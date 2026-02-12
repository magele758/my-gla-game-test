extends RefCounted
class_name BranchRouter


func is_choice_available(choice_data: Dictionary, game_state: GameState) -> bool:
	var conditions: Dictionary = choice_data.get("conditions", {})
	if conditions.is_empty():
		return true

	for flag_name in conditions.get("require_flags", []):
		if not game_state.has_flag(String(flag_name)):
			return false

	for flag_name in conditions.get("forbid_flags", []):
		if game_state.has_flag(String(flag_name)):
			return false

	var min_axes: Dictionary = conditions.get("min_axes", {})
	for axis_name in min_axes.keys():
		if int(game_state.axes.get(axis_name, 0)) < int(min_axes[axis_name]):
			return false

	var max_axes: Dictionary = conditions.get("max_axes", {})
	for axis_name in max_axes.keys():
		if int(game_state.axes.get(axis_name, 0)) > int(max_axes[axis_name]):
			return false

	return true


func route_next(choice_data: Dictionary, game_state: GameState) -> String:
	for rule in choice_data.get("conditional_next", []):
		var if_flag := String(rule.get("if_flag", ""))
		var if_not_flag := String(rule.get("if_not_flag", ""))
		var hit := true
		if if_flag != "":
			hit = hit and game_state.has_flag(if_flag)
		if if_not_flag != "":
			hit = hit and (not game_state.has_flag(if_not_flag))
		if hit:
			return String(rule.get("next", game_state.current_node_id))
	return String(choice_data.get("next", game_state.current_node_id))
