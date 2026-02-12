from __future__ import annotations

import logging
import os
from pathlib import Path
from typing import Any

import yaml
from dotenv import load_dotenv
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field

from .provider_router import ProviderRouter
from .safety_filter import SafetyFilter

load_dotenv()
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("ai-gateway")

APP_DIR = Path(__file__).resolve().parent
ROOT_DIR = APP_DIR.parent
CONFIG_DIR = ROOT_DIR / "config"

PROFILE_CONFIG_PATH = str(CONFIG_DIR / "npc_profiles.yaml")
FALLBACK_CONFIG_PATH = CONFIG_DIR / "fallback_lines.yaml"


def _load_fallbacks(path: Path) -> dict[str, Any]:
    if not path.exists():
        return {"global_default": "夜雾吞掉了回答。", "npc": {}}
    return yaml.safe_load(path.read_text(encoding="utf-8")) or {"global_default": "夜雾吞掉了回答。", "npc": {}}


provider_router = ProviderRouter(config_path=PROFILE_CONFIG_PATH)
safety_filter = SafetyFilter()
fallbacks = _load_fallbacks(FALLBACK_CONFIG_PATH)

app = FastAPI(
    title="GLA AI Gateway",
    description="OpenAI-like gateway with NPC profile routing and safe fallback.",
    version="0.1.0",
)
allowed_origins = [origin.strip() for origin in os.getenv("CORS_ALLOW_ORIGINS", "*").split(",") if origin.strip()]
app.add_middleware(
    CORSMiddleware,
    allow_origins=allowed_origins or ["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)


class NpcReplyRequest(BaseModel):
    npc_id: str
    profile_id: str | None = None
    chapter: str = "chapter1"
    scene_prompt: str
    player_choice: str = ""
    trend_scores: dict[str, int] = Field(default_factory=dict)
    memory: list[str] = Field(default_factory=list)
    fallback_line: str = ""


class NpcReplyResponse(BaseModel):
    reply: str
    source: str
    blocked: bool = False
    reason: str = ""


def _pick_fallback(npc_id: str, request_fallback: str = "") -> str:
    if request_fallback.strip():
        return request_fallback.strip()
    npc_map = fallbacks.get("npc", {})
    if npc_id in npc_map:
        return str(npc_map[npc_id]).strip()
    return str(fallbacks.get("global_default", "夜雾吞掉了回答。")).strip()


def _build_system_prompt(req: NpcReplyRequest) -> str:
    trend = (
        f"angel={req.trend_scores.get('angelKindness', 0)}, "
        f"demon={req.trend_scores.get('demonMalice', 0)}, "
        f"eldritch={req.trend_scores.get('eldritchCorruption', 0)}"
    )
    return (
        "You are an NPC in a suspense-horror branching game. "
        "Keep responses concise (1-3 sentences), atmospheric, and in-character. "
        "No explicit sexual content, no sexual violence, no content involving minors. "
        f"Current chapter: {req.chapter}. Trend scores: {trend}."
    )


def _build_user_prompt(req: NpcReplyRequest) -> str:
    suffix = f"\nPlayer just chose: {req.player_choice}" if req.player_choice else ""
    return req.scene_prompt + suffix


@app.get("/health")
async def health() -> dict[str, Any]:
    return {
        "ok": True,
        "profiles_loaded": len(provider_router.profiles),
        "npc_routes": len(provider_router.npc_to_profile),
    }


@app.post("/v1/npc/reply", response_model=NpcReplyResponse)
async def npc_reply(req: NpcReplyRequest) -> NpcReplyResponse:
    fallback_line = _pick_fallback(req.npc_id, req.fallback_line)

    precheck = safety_filter.check_many([req.scene_prompt, req.player_choice])
    if precheck.blocked:
        return NpcReplyResponse(reply=fallback_line, source="fallback", blocked=True, reason=precheck.reason)

    try:
        reply = await provider_router.generate_npc_reply(
            npc_id=req.npc_id,
            explicit_profile_id=req.profile_id,
            system_prompt=_build_system_prompt(req),
            user_prompt=_build_user_prompt(req),
            memory=req.memory,
        )
    except Exception as exc:  # noqa: BLE001
        logger.warning("provider_failed npc=%s err=%s", req.npc_id, exc)
        return NpcReplyResponse(reply=fallback_line, source="fallback", blocked=False, reason="provider_error")

    postcheck = safety_filter.check_text(reply)
    if postcheck.blocked:
        return NpcReplyResponse(reply=fallback_line, source="fallback", blocked=True, reason=postcheck.reason)

    return NpcReplyResponse(reply=safety_filter.sanitize_reply(reply), source="model", blocked=False)
