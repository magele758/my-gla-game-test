extends RefCounted
class_name GameState

const DEFAULT_NODE_ID := "c1_n01"

var axes: Dictionary = {
	"angelKindness": 0,
	"demonMalice": 0,
	"eldritchCorruption": 0
}
var flags: Dictionary = {}
var chapter: String = "chapter1"
var current_node_id: String = DEFAULT_NODE_ID
var choice_history: Array = []
var npc_memory_snapshot: Dictionary = {}


func reset() -> void:
	axes = {
		"angelKindness": 0,
		"demonMalice": 0,
		"eldritchCorruption": 0
	}
	flags = {}
	chapter = "chapter1"
	current_node_id = DEFAULT_NODE_ID
	choice_history = []
	npc_memory_snapshot = {}


func apply_effects(effects: Dictionary) -> void:
	for key in effects.keys():
		if axes.has(key):
			axes[key] += int(effects[key])


func set_flags(flag_list: Array) -> void:
	for flag in flag_list:
		flags[String(flag)] = true


func clear_flags(flag_list: Array) -> void:
	for flag in flag_list:
		flags.erase(String(flag))


func has_flag(flag_name: String) -> bool:
	return flags.get(flag_name, false)


func dominant_trend() -> String:
	var winner := "angelKindness"
	var max_score := int(axes[winner])
	for key in axes.keys():
		var score := int(axes[key])
		if score > max_score:
			max_score = score
			winner = key
	return winner


func append_choice(choice_record: Dictionary) -> void:
	choice_history.append(choice_record)


func to_dict() -> Dictionary:
	return {
		"axes": axes.duplicate(true),
		"flags": flags.duplicate(true),
		"chapter": chapter,
		"current_node_id": current_node_id,
		"choice_history": choice_history.duplicate(true),
		"npc_memory_snapshot": npc_memory_snapshot.duplicate(true)
	}


func from_dict(data: Dictionary) -> void:
	axes = data.get("axes", axes)
	flags = data.get("flags", {})
	chapter = data.get("chapter", "chapter1")
	current_node_id = data.get("current_node_id", DEFAULT_NODE_ID)
	choice_history = data.get("choice_history", [])
	npc_memory_snapshot = data.get("npc_memory_snapshot", {})
