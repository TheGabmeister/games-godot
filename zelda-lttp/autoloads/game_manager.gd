extends Node

var flags: Dictionary = {}
var is_paused: bool = false
var last_safe_position: Vector2 = Vector2.ZERO
var last_safe_room_id: StringName = &""
var current_save_slot: int = -1

## Read-only: delegates to SceneManager.current_room_data.world_type
var world_type: StringName:
	get:
		if SceneManager.current_room_data:
			return SceneManager.current_room_data.world_type
		return &"light"


func set_flag(key: StringName, value: Variant) -> void:
	flags[key] = value


func get_flag(key: StringName, default_value: Variant = false) -> Variant:
	return flags.get(key, default_value)


func has_flag(key: StringName) -> bool:
	return flags.has(key)


# --- Serialization ---

func serialize() -> Dictionary:
	var flags_dict: Dictionary = {}
	for key: StringName in flags:
		flags_dict[String(key)] = flags[key]
	return {
		"flags": flags_dict,
		"last_safe_room_id": String(last_safe_room_id),
		"last_safe_position": [last_safe_position.x, last_safe_position.y],
	}


func deserialize(data: Dictionary) -> void:
	flags.clear()
	var flags_data: Dictionary = data.get("flags", {})
	for key: String in flags_data:
		flags[StringName(key)] = flags_data[key]

	last_safe_room_id = StringName(data.get("last_safe_room_id", ""))
	var pos_arr: Array = data.get("last_safe_position", [0, 0])
	last_safe_position = Vector2(float(pos_arr[0]), float(pos_arr[1]))


func reset() -> void:
	flags.clear()
	is_paused = false
	last_safe_position = Vector2.ZERO
	last_safe_room_id = &""
	current_save_slot = -1
