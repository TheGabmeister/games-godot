extends Node

## Full save/load system. 3 slots, JSON format, schema_version for migration.

const SCHEMA_VERSION := 1
const SAVE_DIR := "user://saves/"


func _ready() -> void:
	# Ensure saves directory exists
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)


func save_game(slot: int) -> void:
	var player_node: Node2D = SceneManager._player
	var room_id: StringName = SceneManager.current_room_data.room_id if SceneManager.current_room_data else &""
	var player_pos: Vector2 = player_node.global_position if player_node else Vector2(128, 112)
	var player_facing: Vector2 = player_node.facing_direction if player_node and "facing_direction" in player_node else Vector2(0, 1)
	var world_type: StringName = SceneManager.current_room_data.world_type if SceneManager.current_room_data else &"light"

	# Get play time from Main scene
	var play_time: int = 0
	var main_node: Node = get_tree().current_scene
	if main_node and main_node.has_method("get_play_time"):
		play_time = main_node.get_play_time()

	var timestamp := Time.get_datetime_string_from_system(true)

	var data: Dictionary = {
		"schema_version": SCHEMA_VERSION,
		"slot": slot,
		"timestamp_utc": timestamp,
		"play_time_seconds": play_time,
		"player": {
			"room_id": String(room_id),
			"position": [player_pos.x, player_pos.y],
			"facing": [player_facing.x, player_facing.y],
		},
		"world_type": String(world_type),
		"player_state": PlayerState.serialize(),
		"game_manager": GameManager.serialize(),
	}

	var json_string := JSON.stringify(data, "  ")
	var path := _slot_path(slot)
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(json_string)
		file.close()
		GameManager.current_save_slot = slot
		print("[SaveManager] Saved to slot %d" % slot)
	else:
		push_error("[SaveManager] Failed to save to %s: %s" % [path, FileAccess.get_open_error()])


func load_game(slot: int) -> void:
	var path := _slot_path(slot)
	if not FileAccess.file_exists(path):
		push_error("[SaveManager] No save file at %s" % path)
		return

	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		push_error("[SaveManager] Failed to open %s" % path)
		return

	var json_string := file.get_as_text()
	file.close()

	var json := JSON.new()
	var error := json.parse(json_string)
	if error != OK:
		push_error("[SaveManager] JSON parse error in %s: %s" % [path, json.get_error_message()])
		return

	var data: Dictionary = json.data as Dictionary

	# Schema version check
	var version: int = int(data.get("schema_version", 0))
	if version != SCHEMA_VERSION:
		push_warning("[SaveManager] Save schema_version %d differs from current %d" % [version, SCHEMA_VERSION])

	# Restore state
	GameManager.deserialize(data.get("game_manager", {}))
	GameManager.current_save_slot = slot
	PlayerState.deserialize(data.get("player_state", {}))

	# Load the saved room
	var player_data: Dictionary = data.get("player", {})
	var room_id: StringName = StringName(player_data.get("room_id", ""))
	var pos_arr: Array = player_data.get("position", [128, 112])
	var facing_arr: Array = player_data.get("facing", [0, 1])

	if room_id != &"" and SceneManager.room_registry.has(room_id):
		SceneManager.load_room(room_id)
		if SceneManager._player:
			SceneManager._player.global_position = Vector2(float(pos_arr[0]), float(pos_arr[1]))
			SceneManager._player.facing_direction = Vector2(float(facing_arr[0]), float(facing_arr[1]))
	else:
		push_warning("[SaveManager] Saved room_id '%s' not found in registry, loading default" % room_id)
		var main_node: Node = get_tree().current_scene
		if main_node and main_node.has_method("_load_starting_room"):
			main_node._load_starting_room()

	print("[SaveManager] Loaded slot %d" % slot)


func has_save(slot: int) -> bool:
	return FileAccess.file_exists(_slot_path(slot))


func get_slot_metadata(slot: int) -> Dictionary:
	var path := _slot_path(slot)
	if not FileAccess.file_exists(path):
		return {}

	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		return {}

	var json_string := file.get_as_text()
	file.close()

	var json := JSON.new()
	if json.parse(json_string) != OK:
		return {}

	var data: Dictionary = json.data as Dictionary
	var ps: Dictionary = data.get("player_state", {})

	return {
		"play_time_seconds": int(data.get("play_time_seconds", 0)),
		"timestamp": data.get("timestamp_utc", ""),
		"max_health": int(ps.get("max_health", 6)),
		"current_health": int(ps.get("current_health", 6)),
		"room_id": data.get("player", {}).get("room_id", ""),
	}


func delete_save(slot: int) -> void:
	var path := _slot_path(slot)
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
		print("[SaveManager] Deleted slot %d" % slot)


func _slot_path(slot: int) -> String:
	return SAVE_DIR + "save_%d.json" % slot
