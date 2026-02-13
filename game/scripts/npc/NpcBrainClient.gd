extends Node
class_name NpcBrainClient

@export var backend_url := "http://127.0.0.1:8000"
@export var request_timeout_seconds := 8.0
@export var ai_enabled := true

var profile_by_npc: Dictionary = {}


func configure_profiles(npc_map: Dictionary) -> void:
	for npc_id in npc_map.keys():
		var npc_data: Dictionary = npc_map[npc_id]
		var ai_profile: Dictionary = npc_data.get("aiProfile", {})
		profile_by_npc[npc_id] = String(ai_profile.get("profile_id", "default_profile"))


var role_card_by_npc: Dictionary = {}


func configure_role_cards(npc_map: Dictionary) -> void:
	for npc_id in npc_map.keys():
		var npc_data: Dictionary = npc_map[npc_id]
		role_card_by_npc[npc_id] = {
			"name": String(npc_data.get("name", "")),
			"publicPersona": String(npc_data.get("publicPersona", "")),
			"hiddenSecret": String(npc_data.get("hiddenSecret", "")),
			"desire": String(npc_data.get("desire", "")),
			"fear": String(npc_data.get("fear", "")),
			"taboo": String(npc_data.get("taboo", "")),
			"alignmentBias": String(npc_data.get("alignmentBias", ""))
		}


func generate_reply(
	npc_id: String,
	npc_name: String,
	scene_prompt: String,
	game_state: GameState,
	recent_memory: Array,
	fallback_line: String
) -> String:
	if not ai_enabled:
		return fallback_line

	var request_payload := {
		"npc_id": npc_id,
		"profile_id": profile_by_npc.get(npc_id, "default_profile"),
		"chapter": game_state.chapter,
		"scene_prompt": scene_prompt,
		"trend_scores": game_state.axes,
		"memory": recent_memory,
		"fallback_line": fallback_line,
		"role_card": role_card_by_npc.get(npc_id, {})
	}

	var http := HTTPRequest.new()
	http.timeout = request_timeout_seconds
	add_child(http)

	var err := http.request(
		"%s/v1/npc/reply" % backend_url,
		PackedStringArray(["Content-Type: application/json"]),
		HTTPClient.METHOD_POST,
		JSON.stringify(request_payload)
	)
	if err != OK:
		http.queue_free()
		return fallback_line

	var result = await http.request_completed
	var response_code := int(result[1])
	var body_raw := PackedByteArray(result[3]).get_string_from_utf8()
	http.queue_free()

	if response_code < 200 or response_code >= 300:
		return fallback_line

	var parsed = JSON.parse_string(body_raw)
	if typeof(parsed) != TYPE_DICTIONARY:
		return fallback_line

	var reply_text := String(parsed.get("reply", "")).strip_edges()
	if reply_text == "":
		return fallback_line
	return "%s：%s" % [npc_name, reply_text]
