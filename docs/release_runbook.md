# Go-Live Runbook

## 1. 内容与分支校验
```bash
python tools/validate_content.py
```

## 2. 启动 AI 网关
```bash
conda activate gla_ai_gateway
uvicorn backend.app.main:app --host 0.0.0.0 --port 8000
```

## 3. 本地试玩回归
- 从开头推进到任一结局
- 断开网关后确认 fallback 台词生效
- 存档 -> 读档 -> 继续到结局

## 4. Web 发布
- Godot 导出 HTML5 到 `build/web/`
- 上传到 itch.io 或 Cloudflare Pages
- 校验公开链接可访问

## 5. Steam 商店页
- 导入 `steam/store_page_zh.md` 和 `steam/store_page_en.md`
- 上传 Capsule、截图、预告片
- 完成内容调查并公开 Coming Soon 页面
