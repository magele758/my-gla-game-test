# Backend AI Gateway

FastAPI gateway that routes NPC requests to OpenAI-like providers by profile.

## 1) Create isolated conda environment
```bash
conda create -n gla_ai_gateway python=3.11 -y
conda activate gla_ai_gateway
```

## 2) Install dependencies
```bash
pip install -r backend/requirements.txt
cp backend/.env.example backend/.env
```

## 3) Configure model endpoints
Fill `backend/.env` with your provider keys and base URLs.
Optional:
- `CORS_ALLOW_ORIGINS=http://localhost:8060,https://your-web-domain`

## 4) Run server
```bash
uvicorn backend.app.main:app --reload --host 0.0.0.0 --port 8000
```

## 5) Verify
```bash
curl http://127.0.0.1:8000/health
python tools/validate_content.py
```

## API
- `POST /v1/npc/reply`
- `GET /health`

The gateway applies:
- profile routing (`npc -> profile`)
- safety filter (high-risk content blocked)
- fallback scripted lines on timeout/provider errors
