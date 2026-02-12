from __future__ import annotations

import os
import re
from dataclasses import dataclass
from pathlib import Path
from typing import Any

import httpx
import yaml


@dataclass
class ModelProfile:
    profile_id: str
    provider_id: str
    base_url: str
    api_key: str
    model_name: str
    temperature: float
    max_tokens: int
    timeout_seconds: float
    chat_path: str = "/chat/completions"


class ProviderRouter:
    def __init__(self, config_path: str) -> None:
        self.config_path = Path(config_path)
        self.npc_to_profile: dict[str, str] = {}
        self.profiles: dict[str, ModelProfile] = {}
        self._load_config()

    def _load_config(self) -> None:
        raw = yaml.safe_load(self.config_path.read_text(encoding="utf-8")) or {}
        self.npc_to_profile = raw.get("npc_to_profile", {})

        self.profiles = {}
        for profile_id, profile_cfg in raw.get("profiles", {}).items():
            self.profiles[profile_id] = self._parse_profile(profile_id, profile_cfg)

    def _parse_profile(self, profile_id: str, cfg: dict[str, Any]) -> ModelProfile:
        api_key = self._resolve_secret(cfg.get("api_key_env", ""), cfg.get("api_key", ""))
        return ModelProfile(
            profile_id=profile_id,
            provider_id=str(cfg.get("provider_id", "openai_like")),
            base_url=self._expand_env(str(cfg.get("base_url", "https://api.openai.com/v1"))),
            api_key=api_key,
            model_name=str(cfg.get("model_name", "gpt-4o-mini")),
            temperature=float(cfg.get("temperature", 0.8)),
            max_tokens=int(cfg.get("max_tokens", 240)),
            timeout_seconds=float(cfg.get("timeout_seconds", 10.0)),
            chat_path=str(cfg.get("chat_path", "/chat/completions")),
        )

    @staticmethod
    def _resolve_secret(env_name: str, direct_value: str) -> str:
        if env_name:
            return os.getenv(env_name, "")
        return direct_value

    @staticmethod
    def _expand_env(value: str) -> str:
        pattern = re.compile(r"\$\{([A-Z0-9_]+)(?::([^}]+))?\}")

        def repl(match: re.Match[str]) -> str:
            var_name = match.group(1)
            default = match.group(2) or ""
            return os.getenv(var_name, default)

        return pattern.sub(repl, value)

    def resolve_profile(self, npc_id: str, explicit_profile_id: str | None = None) -> ModelProfile:
        profile_id = explicit_profile_id or self.npc_to_profile.get(npc_id, "default_profile")
        if profile_id not in self.profiles:
            raise KeyError(f"profile_not_found:{profile_id}")
        return self.profiles[profile_id]

    async def generate_npc_reply(
        self,
        *,
        npc_id: str,
        explicit_profile_id: str | None,
        system_prompt: str,
        user_prompt: str,
        memory: list[str],
    ) -> str:
        profile = self.resolve_profile(npc_id=npc_id, explicit_profile_id=explicit_profile_id)
        messages = [
            {"role": "system", "content": system_prompt},
            {
                "role": "user",
                "content": f"Scene:\n{user_prompt}\n\nRecent memory:\n- "
                + "\n- ".join(memory[-6:] if memory else ["None"]),
            },
        ]
        return await self._call_openai_like(profile, messages)

    async def _call_openai_like(self, profile: ModelProfile, messages: list[dict[str, str]]) -> str:
        endpoint = profile.base_url.rstrip("/") + profile.chat_path
        headers = {"Content-Type": "application/json"}
        if profile.api_key:
            headers["Authorization"] = f"Bearer {profile.api_key}"

        payload = {
            "model": profile.model_name,
            "messages": messages,
            "temperature": profile.temperature,
            "max_tokens": profile.max_tokens,
        }

        timeout = httpx.Timeout(timeout=profile.timeout_seconds, connect=profile.timeout_seconds)
        async with httpx.AsyncClient(timeout=timeout) as client:
            resp = await client.post(endpoint, headers=headers, json=payload)
            resp.raise_for_status()
            data = resp.json()
        return self._extract_text(data)

    @staticmethod
    def _extract_text(data: dict[str, Any]) -> str:
        choices = data.get("choices", [])
        if not choices:
            raise ValueError("empty_choices")

        first = choices[0]
        if isinstance(first, dict):
            message = first.get("message", {})
            if isinstance(message, dict) and message.get("content"):
                return str(message["content"]).strip()
            if first.get("text"):
                return str(first["text"]).strip()
        raise ValueError("invalid_completion_payload")
