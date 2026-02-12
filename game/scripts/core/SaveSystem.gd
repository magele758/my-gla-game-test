extends RefCounted
class_name SaveSystem

const SAVE_PATH := "user://savegame.json"


func save_state(state_data: Dictionary) -> bool:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(state_data))
	return true


func load_state() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return {}
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return {}
	var raw_text := file.get_as_text()
	var parsed = JSON.parse_string(raw_text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return parsed
