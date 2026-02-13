# 插件集成说明

本项目集成了 5 个 Godot 4 社区插件，以下是每个插件的用途、来源和使用指引。

## 1. Dialogue Manager (3,310 stars)
- **来源**: [nathanhoad/godot_dialogue_manager](https://github.com/nathanhoad/godot_dialogue_manager)
- **用途**: 非线性对话系统，支持条件分支、变量注入和打字机效果
- **路径**: `addons/dialogue_manager/`
- **使用方式**:
  - 在 `game/dialogues/` 下创建 `.dialogue` 文件
  - 用 Godot 内置的 Dialogue Editor 编辑对话树
  - 可替代或补充现有的 `story_nodes.json` 中的NPC台词
  - 文档: https://dialoguemanager.nathanhoad.net/

## 2. AdaptiSound (85 stars)
- **来源**: [MrWalkmanDev/AdaptiSound](https://github.com/MrWalkmanDev/AdaptiSound)
- **用途**: 背景音乐管理器，支持场景切换淡入淡出、分层音轨
- **路径**: `addons/AdaptiSound/`
- **使用方式**:
  - 在 AdaptiSound 面板中注册音乐和音效资源
  - 代码中调用 `AdaptiSound.play_music("track_name")` 播放
  - 恐怖场景建议用低频环境音 + 突发音效层叠
  - 音频文件放在 `game/audio/` 下

## 3. Quest System (434 stars)
- **来源**: [shomykohai/quest-system](https://github.com/shomykohai/quest-system)
- **用途**: 任务/线索追踪系统，用于管理5条NPC秘密线进度
- **路径**: `addons/quest_system/`
- **使用方式**:
  - 预建的 5 条 NPC 秘密线资源在 `game/data/quests/`
  - 通过 `QuestSystem.start_quest(quest)` 激活线索
  - 通过 `QuestSystem.complete_quest(quest)` 完成线索
  - 秘密线完成状态影响结局判定

## 4. ShaderV (1,133 stars)
- **来源**: [arkology/ShaderV](https://github.com/arkology/ShaderV)
- **用途**: 可视化着色器插件，提供噪点/扭曲/暗角等恐怖视觉效果
- **路径**: `addons/shaderV/`
- **使用方式**:
  - 这是纯 shader 资源，无需启用插件
  - 在 VisualShader 编辑器中可直接使用 ShaderV 节点
  - 建议用于: 暗角（vignette）、色差（chromatic aberration）、噪点（noise grain）
  - 在终章和结局场景加重效果

## 5. Godot Game Settings (514 stars)
- **来源**: [zijcht/godot-game-settings](https://github.com/zijcht/godot-game-settings)
- **用途**: 游戏设置菜单管理（音量/分辨率/全屏/语言等）
- **路径**: `addons/ggs/`
- **使用方式**:
  - 在 GGS 面板中定义设置项
  - 自动生成设置 UI
  - 发布前必须有: 音量控制、全屏切换、语言切换
