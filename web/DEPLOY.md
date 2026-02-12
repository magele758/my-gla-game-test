# Web 发布说明（Godot4 HTML5）

## 目标
- 公开可玩网页版本（itch.io 或 Cloudflare Pages）

## 步骤
1. 打开 Godot4，载入项目根目录。
2. `Project -> Export` 新建 `Web` 预设。
3. 勾选压缩与线程配置（按Godot默认推荐）。
4. 导出到 `build/web/`（生成 `index.html` 与 wasm/js 文件）。

## 网关联通
- 游戏默认访问 `http://127.0.0.1:8000`。
- 公网部署时，请把 `NpcBrainClient.gd` 的 `backend_url` 改为网关公网地址。
- 若跨域，请在网关层配置 CORS。

## 上线
- itch.io：创建项目 -> 上传 `build/web/` zip -> 勾选 This file will be played in the browser。
- Cloudflare Pages：上传 `build/web/` 作为静态站点目录。

## 验收
- 首页能进入主循环
- 至少通关一次结局
- AI异常时不阻塞流程
