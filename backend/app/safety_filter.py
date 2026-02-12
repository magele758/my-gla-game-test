from __future__ import annotations

import re
from dataclasses import dataclass
from typing import Iterable


@dataclass(frozen=True)
class SafetyDecision:
    blocked: bool
    reason: str = ""


class SafetyFilter:
    """
    Lightweight content gate for 18+ soft mature horror.
    Blocks high-risk categories and lets normal suspense pass.
    """

    def __init__(self) -> None:
        self._blocked_patterns = [
            re.compile(r"\bminor\b", re.IGNORECASE),
            re.compile(r"未成年"),
            re.compile(r"child\s*sexual", re.IGNORECASE),
            re.compile(r"rape|sexual assault", re.IGNORECASE),
            re.compile(r"强奸|性侵"),
            re.compile(r"incest", re.IGNORECASE),
            re.compile(r"乱伦"),
            re.compile(r"bestiality", re.IGNORECASE),
        ]

    def check_text(self, text: str) -> SafetyDecision:
        normalized = self._normalize(text)
        for pattern in self._blocked_patterns:
            if pattern.search(normalized):
                return SafetyDecision(blocked=True, reason=f"blocked_by:{pattern.pattern}")
        return SafetyDecision(blocked=False)

    def check_many(self, texts: Iterable[str]) -> SafetyDecision:
        for text in texts:
            decision = self.check_text(text)
            if decision.blocked:
                return decision
        return SafetyDecision(blocked=False)

    def sanitize_reply(self, text: str, max_chars: int = 420) -> str:
        clean = self._normalize(text).strip()
        if len(clean) > max_chars:
            clean = clean[: max_chars - 3] + "..."
        return clean

    @staticmethod
    def _normalize(text: str) -> str:
        return text.replace("\u0000", "").strip()
