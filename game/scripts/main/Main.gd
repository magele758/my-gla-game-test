extends Control

const STORY_PATH := "res://game/data/story/story_nodes.json"
const ENDINGS_PATH := "res://game/data/story/endings.json"
const NPCS_PATH := "res://game/data/npcs/npcs.json"

const GameStateCls = preload("res://game/scripts/core/GameState.gd")
const BranchRouterCls = preload("res://game/scripts/core/BranchRouter.gd")
const SaveSystemCls = preload("res://game/scripts/core/SaveSystem.gd")
const EndingResolverCls = preload("res://game/scripts/core/EndingResolver.gd")
const NpcMemoryCls = preload("res://game/scripts/npc/NpcMemory.gd")
const NpcBrainClientCls = preload("res://game/scripts/npc/NpcBrainClient.gd")

@onready var trend_label: Label = $RootMargin/MainVBox/TrendLabel
@onready var mature_toggle: CheckButton = $RootMargin/MainVBox/MatureToneToggle
@onready var story_text: RichTextLabel = $RootMargin/MainVBox/StoryText
@onready var npc_reply_text: RichTextLabel = $RootMargin/MainVBox/NpcReply
@onready var choices_vbox: VBoxContainer = $RootMargin/MainVBox/ChoicesPanel/ChoicesVBox
@onready var save_button: Button = $RootMargin/MainVBox/BottomRow/SaveButton
@onready var load_button: Button = $RootMargin/MainVBox/BottomRow/LoadButton
@onready var restart_button: Button = $RootMargin/MainVBox/BottomRow/RestartButton
@onready var status_label: Label = $RootMargin/MainVBox/BottomRow/StatusLabel

var game_state: GameState
var branch_router: BranchRouter
var save_system: SaveSystem
var ending_resolver: EndingResolver
var npc_memory: NpcMemory
var npc_brain_client: NpcBrainClient

var nodes_by_id: Dictionary = {}
var endings: Array = []
var npc_by_id: Dictionary = {}
var is_busy := false
var mature_tone_enabled := true


func _ready() -> void:
	game_state = GameStateCls.new()
	branch_router = BranchRouterCls.new()
	save_system = SaveSystemCls.new()
	ending_resolver = EndingResolverCls.new()
	npc_memory = NpcMemoryCls.new()
	npc_brain_client = NpcBrainClientCls.new()
	add_child(npc_brain_client)

	save_button.pressed.connect(_on_save_pressed)
	load_button.pressed.connect(_on_load_pressed)
	restart_button.pressed.connect(_on_restart_pressed)
	mature_toggle.toggled.connect(_on_mature_toggle_changed)
	mature_tone_enabled = mature_toggle.button_pressed

	if not _load_content_data():
		status_label.text = "状态: 数据加载失败，请检查JSON文件"
		return

	_configure_npc_modules()
	_start_new_game()


func _load_content_data() -> bool:
	var story_root := _load_json_file(STORY_PATH)
	var ending_root := _load_json_file(ENDINGS_PATH)
	var npc_root := _load_json_file(NPCS_PATH)

	if story_root.is_empty() or ending_root.is_empty() or npc_root.is_empty():
		return false

	nodes_by_id.clear()
	for node in story_root.get("nodes", []):
		nodes_by_id[String(node.get("id", ""))] = node

	endings = ending_root.get("endings", [])

	npc_by_id.clear()
	for npc in npc_root.get("npc_profiles", []):
		npc_by_id[String(npc.get("id", ""))] = npc
	return true


func _load_json_file(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return parsed


func _configure_npc_modules() -> void:
	for npc_id in npc_by_id.keys():
		var npc_data: Dictionary = npc_by_id[npc_id]
		npc_memory.configure_policy(npc_id, npc_data.get("memoryPolicy", {}))
	npc_brain_client.configure_profiles(npc_by_id)


func _start_new_game() -> void:
	game_state.reset()
	npc_memory = NpcMemoryCls.new()
	_configure_npc_modules()
	_update_trend_label()
	call_deferred("_deferred_render_current_node")


func _deferred_render_current_node() -> void:
	await _render_current_node()


func _update_trend_label() -> void:
	trend_label.text = "趋势: 天使 %d | 恶魔 %d | 黑化 %d" % [
		int(game_state.axes.get("angelKindness", 0)),
		int(game_state.axes.get("demonMalice", 0)),
		int(game_state.axes.get("eldritchCorruption", 0))
	]


func _render_current_node() -> void:
	if game_state.current_node_id == "ENDING":
		_render_ending()
		return

	var node_data: Dictionary = nodes_by_id.get(game_state.current_node_id, {})
	if node_data.is_empty():
		status_label.text = "状态: 节点不存在 %s" % game_state.current_node_id
		return

	story_text.text = _display_text("[%s]\n\n%s" % [String(node_data.get("title", "")), String(node_data.get("text", ""))])
	npc_reply_text.text = ""

	var npc_id := String(node_data.get("npc_id", ""))
	if npc_id != "":
		var npc_data: Dictionary = npc_by_id.get(npc_id, {})
		var npc_name := String(npc_data.get("name", "无名者"))
		var fallback_line := String(node_data.get("fallback_line", npc_data.get("fallback_line", "她沉默了几秒，只留下模糊的暗示。")))
		status_label.text = "状态: %s 正在回应..." % npc_name
		var ai_reply := await npc_brain_client.generate_reply(
			npc_id,
			npc_name,
			String(node_data.get("text", "")),
			game_state,
			npc_memory.get_recent(npc_id),
			fallback_line
		)
		npc_reply_text.text = _display_text(ai_reply)
		npc_memory.append_memory(npc_id, ai_reply)

	_refresh_choices(node_data)
	status_label.text = "状态: %s" % game_state.current_node_id


func _refresh_choices(node_data: Dictionary) -> void:
	for child in choices_vbox.get_children():
		child.queue_free()

	var visible_choice_count := 0
	for choice_data in node_data.get("choices", []):
		if not branch_router.is_choice_available(choice_data, game_state):
			continue
		var choice_button := Button.new()
		choice_button.text = _display_text(String(choice_data.get("text", "未命名选项")))
		choice_button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		choice_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		choice_button.pressed.connect(func() -> void:
			_on_choice_pressed(choice_data)
		)
		choices_vbox.add_child(choice_button)
		visible_choice_count += 1

	if visible_choice_count == 0:
		var continue_button := Button.new()
		continue_button.text = "继续"
		continue_button.pressed.connect(func() -> void:
			game_state.current_node_id = "ENDING"
			call_deferred("_deferred_render_current_node")
		)
		choices_vbox.add_child(continue_button)


func _on_choice_pressed(choice_data: Dictionary) -> void:
	if is_busy:
		return
	is_busy = true
	_set_choice_buttons_disabled(true)

	var current_node: Dictionary = nodes_by_id.get(game_state.current_node_id, {})
	var npc_id := String(current_node.get("npc_id", ""))
	var choice_text := String(choice_data.get("text", ""))

	game_state.apply_effects(choice_data.get("effects", {}))
	game_state.set_flags(choice_data.get("set_flags", []))
	game_state.clear_flags(choice_data.get("clear_flags", []))
	game_state.append_choice({
		"node_id": game_state.current_node_id,
		"choice_id": String(choice_data.get("id", "")),
		"choice_text": choice_text
	})

	if npc_id != "":
		npc_memory.append_memory(npc_id, "玩家选择: %s" % choice_text)

	var next_node := branch_router.route_next(choice_data, game_state)
	game_state.current_node_id = next_node
	_update_chapter_by_node(next_node)
	_update_trend_label()

	await _render_current_node()

	_set_choice_buttons_disabled(false)
	is_busy = false


func _set_choice_buttons_disabled(disabled: bool) -> void:
	for child in choices_vbox.get_children():
		if child is Button:
			(child as Button).disabled = disabled


func _update_chapter_by_node(node_id: String) -> void:
	if node_id.begins_with("c1_"):
		game_state.chapter = "chapter1"
	elif node_id.begins_with("c2_"):
		game_state.chapter = "chapter2"
	elif node_id.begins_with("c3_"):
		game_state.chapter = "chapter3"
	elif node_id == "ENDING":
		game_state.chapter = "ending"


func _render_ending() -> void:
	for child in choices_vbox.get_children():
		child.queue_free()

	var ending: Dictionary = ending_resolver.resolve_ending(endings, game_state)
	story_text.text = _display_text("[%s]\n\n%s" % [
		String(ending.get("title", "无名结局")),
		String(ending.get("description", "夜色吞没了最后的证言。"))
	])
	npc_reply_text.text = _display_text(String(ending.get("epilogue", "你听见门后有人低语，却再也分不清那是谁。")))
	status_label.text = "状态: 结局已达成 (%s)" % String(ending.get("id", "unknown"))

	var restart_btn := Button.new()
	restart_btn.text = "开始新周目"
	restart_btn.pressed.connect(_on_restart_pressed)
	choices_vbox.add_child(restart_btn)


func _on_save_pressed() -> void:
	game_state.npc_memory_snapshot = npc_memory.to_dict()
	var payload := game_state.to_dict()
	payload["save_version"] = 1
	if save_system.save_state(payload):
		status_label.text = "状态: 存档成功"
	else:
		status_label.text = "状态: 存档失败"


func _on_load_pressed() -> void:
	var payload := save_system.load_state()
	if payload.is_empty():
		status_label.text = "状态: 未找到可用存档"
		return
	game_state.from_dict(payload)
	npc_memory = NpcMemoryCls.new()
	_configure_npc_modules()
	npc_memory.from_dict(game_state.npc_memory_snapshot)
	_update_trend_label()
	call_deferred("_deferred_render_current_node")
	status_label.text = "状态: 读档成功"


func _on_restart_pressed() -> void:
	status_label.text = "状态: 重开中..."
	_start_new_game()


func _on_mature_toggle_changed(pressed: bool) -> void:
	mature_tone_enabled = pressed
	status_label.text = "状态: 文本模式已切换"
	call_deferred("_deferred_render_current_node")


func _display_text(text: String) -> String:
	if mature_tone_enabled:
		return text
	return _downgrade_text(text)


func _downgrade_text(text: String) -> String:
	var toned := text
	var replacements := {
		"血供": "代价",
		"献祭": "仪式",
		"召引": "呼唤",
		"召唤": "呼唤",
		"勒索": "施压",
		"围猎": "追缉",
		"黑市": "地下渠道",
		"黑化": "异变"
	}
	for key in replacements.keys():
		toned = toned.replace(key, replacements[key])
	return toned
