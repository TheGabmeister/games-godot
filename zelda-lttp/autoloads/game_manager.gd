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
