extends RefCounted
class_name EndingResolver


func resolve_ending(endings: Array, game_state: GameState) -> Dictionary:
	var trend := game_state.dominant_trend()
	var candidates: Array = []
	for ending in endings:
		if String(ending.get("trend", "")) == trend:
			candidates.append(ending)
	if candidates.is_empty():
		candidates = endings

	var best_score := -9999
	var best_ending: Dictionary = {}
	for ending in candidates:
		if _violates_forbidden_flags(ending, game_state):
			continue
		var score := _score_ending(ending, game_state)
		if score > best_score:
			best_score = score
			best_ending = ending

	if best_ending.is_empty() and not candidates.is_empty():
		best_ending = candidates[0]
	return best_ending


func _score_ending(ending: Dictionary, game_state: GameState) -> int:
	var score := 0
	for flag_name in ending.get("required_flags", []):
		if game_state.has_flag(String(flag_name)):
			score += 2
		else:
			score -= 3
	score += int(game_state.axes.get(String(ending.get("trend", "")), 0))
	return score


func _violates_forbidden_flags(ending: Dictionary, game_state: GameState) -> bool:
	for flag_name in ending.get("forbidden_flags", []):
		if game_state.has_flag(String(flag_name)):
			return true
	return false
