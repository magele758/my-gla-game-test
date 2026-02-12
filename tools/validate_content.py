#!/usr/bin/env python3
from __future__ import annotations

import json
from collections import Counter, defaultdict
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
STORY_PATH = ROOT / "game" / "data" / "story" / "story_nodes.json"
ENDINGS_PATH = ROOT / "game" / "data" / "story" / "endings.json"


def load_json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def main() -> None:
    story = load_json(STORY_PATH)
    endings = load_json(ENDINGS_PATH)

    nodes = story["nodes"]
    node_ids = {node["id"] for node in nodes}
    chapter_counts = Counter(node["chapter"] for node in nodes)

    choice_count = 0
    bad_next = []
    for node in nodes:
        choices = node.get("choices", [])
        if not choices:
            raise SystemExit(f"Node has no choices: {node['id']}")
        for choice in choices:
            choice_count += 1
            next_id = choice.get("next")
            if next_id != "ENDING" and next_id not in node_ids:
                bad_next.append((node["id"], choice.get("id"), next_id))

    if bad_next:
        raise SystemExit(f"Invalid next node links: {bad_next}")

    endings_list = endings["endings"]
    trend_counts = Counter(item["trend"] for item in endings_list)

    assert len(nodes) == 30, f"expected 30 nodes, got {len(nodes)}"
    assert choice_count == 60, f"expected 60 choices, got {choice_count}"
    assert chapter_counts == {"chapter1": 10, "chapter2": 10, "chapter3": 10}, chapter_counts
    assert len(endings_list) == 9, f"expected 9 endings, got {len(endings_list)}"
    assert trend_counts == {
        "angelKindness": 3,
        "demonMalice": 3,
        "eldritchCorruption": 3,
    }, trend_counts

    print("Content validation passed.")
    print(f"Nodes: {len(nodes)}; Choices: {choice_count}; Endings: {len(endings_list)}")
    print(f"Chapters: {dict(chapter_counts)}")
    print(f"Ending trends: {dict(trend_counts)}")


if __name__ == "__main__":
    main()
