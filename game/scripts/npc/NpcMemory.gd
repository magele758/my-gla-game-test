extends RefCounted
class_name NpcMemory

var memory_map: Dictionary = {}
var policy_map: Dictionary = {}
var chapter_summary_map: Dictionary = {}


func configure_policy(npc_id: String, policy: Dictionary) -> void:
	policy_map[npc_id] = policy


func append_memory(npc_id: String, memory_text: String) -> void:
	if memory_text.strip_edges() == "":
		return
	if not memory_map.has(npc_id):
		memory_map[npc_id] = []
	var entries: Array = memory_map[npc_id]
	entries.append(memory_text)
	var limit := int(policy_map.get(npc_id, {}).get("shortTermLimit", 6))
	while entries.size() > limit:
		entries.pop_front()
	memory_map[npc_id] = entries


func get_recent(npc_id: String) -> Array:
	return memory_map.get(npc_id, [])


func summarize_chapter(npc_id: String, chapter: String) -> void:
	var recent: Array = get_recent(npc_id)
	var summary := ""
	if recent.size() >= 2:
		summary = "%s / %s" % [recent[recent.size() - 2], recent[recent.size() - 1]]
	elif recent.size() == 1:
		summary = String(recent[0])
	chapter_summary_map["%s::%s" % [npc_id, chapter]] = summary


func get_chapter_summary(npc_id: String, chapter: String) -> String:
	return String(chapter_summary_map.get("%s::%s" % [npc_id, chapter], ""))


func to_dict() -> Dictionary:
	return {
		"memory_map": memory_map.duplicate(true),
		"chapter_summary_map": chapter_summary_map.duplicate(true)
	}


func from_dict(data: Dictionary) -> void:
	memory_map = data.get("memory_map", {})
	chapter_summary_map = data.get("chapter_summary_map", {})
