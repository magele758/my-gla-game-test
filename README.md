# Whispers of the Hollow Ward — GLA AI 叙事恐怖游戏

Godot 4 悬疑惊悚分支叙事原型，5名NPC各自接入AI大脑，玩家选择驱动三大趋势结局。

## 功能概览
| 模块 | 说明 |
|------|------|
| 剧情引擎 | 30个剧情节点、60个选择、9种结局（天使/恶魔/黑化各3） |
| AI NPC | 5名NPC独立角色卡、记忆策略、可配置OpenAI-like模型 |
| AI网关 | FastAPI后端，按NPC profile路由请求，内置安全过滤与降级回复 |
| 存档系统 | JSON存档/读档，支持中途保存与新周目 |
| 成人内容开关 | 游戏内可切换完整18+氛围/降级文本 |

## 前置依赖

| 工具 | 版本要求 | 用途 |
|------|----------|------|
| [Godot 4](https://godotengine.org/download/) | 4.2+ | 运行游戏客户端 |
| [Conda](https://docs.conda.io/en/latest/miniconda.html) 或 Python | 3.11+ | 运行AI网关后端 |
| OpenAI-like API Key | 任意兼容provider | NPC的AI大脑（可选，无key也可用降级台词玩） |

## Quick Start（完整步骤）

### 1. 克隆仓库
```bash
git clone https://github.com/magele758/my-gla-game-test.git
cd my-gla-game-test
```

### 2. 启动AI网关后端
```bash
# 创建隔离环境
conda create -n gla_ai_gateway python=3.11 -y
conda activate gla_ai_gateway

# 安装依赖
pip install -r backend/requirements.txt

# 配置API密钥（必做，否则NPC只能用降级台词）
cp backend/.env.example backend/.env
# 编辑 backend/.env，至少填写 OPENAI_API_KEY=你的key
# 支持任意OpenAI-like provider，修改 OPENAI_BASE_URL 即可

# 启动网关（默认端口8000）
uvicorn backend.app.main:app --reload --host 0.0.0.0 --port 8000
```

验证网关：
```bash
curl http://127.0.0.1:8000/health
# 应返回 {"ok":true,"profiles_loaded":6,"npc_routes":5}
```

### 3. 运行游戏
1. 打开 **Godot 4 编辑器**
2. 点击 **Import** -> 选择本仓库根目录的 `project.godot`
3. 点击左上角 **运行 (F5)** 即可开始游戏

### 4. 开始游玩
- 游戏自动从「第一章·夜班签到」开始
- 每个场景会显示NPC的AI回复（或降级台词）
- 选择会影响三轴数值（天使/恶魔/黑化），顶部实时显示
- 通关30个节点后进入结局判定
- 可随时点「保存/读档/重开」

## 无API Key也能玩

如果你没有配置任何API key，游戏**完全可以运行**：
- 每个NPC都有预设的降级台词（fallback lines）
- 网关超时/报错/被安全过滤拦截时，自动返回降级台词
- 剧情推进、选择、存档、结局判定均不依赖AI

## 自定义AI模型配置

每个NPC可以独立配置不同的模型provider：

| 环境变量 | 说明 |
|----------|------|
| `OPENAI_BASE_URL` | 默认provider地址（支持任意OpenAI-like） |
| `OPENAI_API_KEY` | 默认API密钥 |
| `OPENAI_MODEL` | 默认模型名（如 `gpt-4o-mini`） |
| `MATRON_BASE_URL` / `MATRON_API_KEY` / `MATRON_MODEL` | 林修女专属配置 |
| `DETECTIVE_*` | 顾探员专属配置 |
| `MEDIUM_*` | 沈婆专属配置 |
| `DRIFTER_*` | 黎渡专属配置 |
| `SCHOLAR_*` | 裴学者专属配置 |

NPC专属配置为空时，自动回退到默认profile。

## 项目结构
```
├── project.godot              # Godot项目入口
├── game/
│   ├── scenes/                # Main.tscn 主场景
│   ├── scripts/
│   │   ├── core/              # GameState / BranchRouter / SaveSystem / EndingResolver
│   │   ├── main/              # Main.gd 主循环控制器
│   │   └── npc/               # NpcBrainClient / NpcMemory
│   └── data/
│       ├── npcs/npcs.json     # 5名NPC角色卡与AI配置
│       └── story/             # story_nodes.json + endings.json
├── backend/
│   ├── app/                   # FastAPI网关（main / provider_router / safety_filter）
│   ├── config/                # npc_profiles.yaml + fallback_lines.yaml
│   ├── .env.example           # 环境变量模板
│   └── requirements.txt
├── tools/validate_content.py  # 内容校验脚本（30节点/60选择/9结局）
├── docs/                      # GDD / QA清单 / 上线Runbook
├── steam/                     # Steam商店页文案与素材清单
└── web/                       # Web导出与部署说明
```

## 内容校验
```bash
conda activate gla_ai_gateway
python tools/validate_content.py
# 应输出: Content validation passed. Nodes: 30; Choices: 60; Endings: 9
```

## Web导出与发布
详见 [web/DEPLOY.md](web/DEPLOY.md)

## Steam商店页
详见 [steam/store_page_zh.md](steam/store_page_zh.md) | [steam/store_page_en.md](steam/store_page_en.md)

## 设计文档
- [MVP GDD](docs/gdd_mvp.md)
- [QA Checklist](docs/qa_checklist.md)
- [Release Runbook](docs/release_runbook.md)

## 技术要点
- 客户端不保存任何真实API密钥，只保留 profile_id
- 后端网关按NPC配置注入密钥并统一转发OpenAI-like请求
- AI调用失败/超时/内容违规时，自动降级为脚本台词，剧情不中断
- 内置安全过滤器拦截高风险内容（未成年/性暴力等）
- 开场有内容警告，游戏内可切换成人氛围文本开关
