extends Node

signal player_health_changed(current: int, max_health: int)
signal player_magic_changed(current: int, max_magic: int)
signal player_rupees_changed(amount: int)
signal player_damaged(amount: int, source_type: int)
signal player_died()

signal enemy_defeated(enemy_type: StringName, position: Vector2)

signal item_get_requested(item: ItemData)
signal item_acquired(item_id: StringName)

signal room_transition_requested(target_room_id: StringName, entry_point: StringName)
signal world_switch_requested(target_world_type: StringName)

signal dialog_requested(lines: Array)
signal dialog_closed()
signal dialog_force_close()

signal screen_shake_requested(intensity: float, duration: float)
