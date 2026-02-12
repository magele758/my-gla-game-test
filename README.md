# My GLA Game With AI

Godot 4 suspense-horror narrative prototype with AI-driven NPC brains.

## Scope (1 week MVP)
- 5 AI NPCs with independent role cards and memory limits
- 3 trend routes: Angel&Kindness, Demon&Malice, Dark&Cthulhu
- 3 chapters, 60 meaningful choices, 9 endings
- Web playable build target + Steam Coming Soon page assets

## Repository Layout
- `game/`: Godot project scenes, scripts, and narrative data
- `backend/`: FastAPI AI gateway for OpenAI-like providers
- `docs/`: MVP design and QA checklist
- `steam/`: Store page copy and asset checklist
- `web/`: Web release/deployment notes

## Quick Start
1. Run backend gateway (see `backend/README.md`).
2. Open this folder in Godot 4.
3. Run `game/scenes/Main.tscn`.

## Notes
- Client never stores raw provider keys.
- Backend injects keys by profile and handles fallback lines.
- If model call fails or is unsafe, the game continues with scripted fallback.
