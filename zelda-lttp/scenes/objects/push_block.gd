class_name PushBlock extends StaticBody2D
## Pushes one tile (16px) in the player's facing direction.
## Optionally persists position via GameManager flag.

@export var persist_id: StringName = &""

var _is_moving: bool = false
const TILE_SIZE := 16.0
const PUSH_DURATION := 0.3


func _ready() -> void:
	collision_layer = 1  # World
	collision_mask = 1  # Collide with other world objects

	# Restore persisted position
	if persist_id != &"":
		var room_id := _get_room_id()
		if room_id != &"":
			var saved_pos = GameManager.get_flag("%s/%s" % [room_id, persist_id], null)
			if saved_pos is Array and saved_pos.size() == 2:
				position = Vector2(saved_pos[0], saved_pos[1])

	# Ensure collision shape exists
	if not _has_collision_shape():
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2(TILE_SIZE, TILE_SIZE)
		shape.shape = rect
		add_child(shape)

	queue_redraw()


func _has_collision_shape() -> bool:
	for child in get_children():
		if child is CollisionShape2D:
			return true
	return false


func try_push(direction: Vector2) -> bool:
	if _is_moving:
		return false

	# Snap direction to cardinal
	if absf(direction.x) > absf(direction.y):
		direction = Vector2(signf(direction.x), 0)
	else:
		direction = Vector2(0, signf(direction.y))

	var target_pos := position + direction * TILE_SIZE

	# Check if target position is clear using a raycast
	var space_state := get_world_2d().direct_space_state
	var query := PhysicsRayQueryParameters2D.create(global_position, global_position + direction * TILE_SIZE, 1)
	query.exclude = [get_rid()]
	var result := space_state.intersect_ray(query)
	if result:
		return false  # Blocked

	_is_moving = true
	var tween := create_tween()
	tween.tween_property(self, "position", target_pos, PUSH_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await tween.finished
	_is_moving = false

	AudioManager.play_sfx(&"block_push")

	# Persist new position
	if persist_id != &"":
		var room_id := _get_room_id()
		if room_id != &"":
			GameManager.set_flag("%s/%s" % [room_id, persist_id], [position.x, position.y])

	# Check pressure plates
	_check_pressure_plates()
	return true


func _check_pressure_plates() -> void:
	# Look for pressure plates at current position
	var space_state := get_world_2d().direct_space_state
	var query := PhysicsPointQueryParameters2D.new()
	query.position = global_position
	query.collision_mask = 128  # Triggers layer
	var results := space_state.intersect_point(query)
	for r in results:
		var collider: Object = r["collider"]
		if collider and collider.has_method("activate"):
			collider.call("activate")


func _get_room_id() -> StringName:
	var room := _find_room()
	if room and "room_data" in room and room.room_data:
		return room.room_data.room_id
	return &""


func _find_room() -> Node:
	var node: Node = get_parent()
	while node:
		if "room_data" in node:
			return node
		node = node.get_parent()
	return null


func _draw() -> void:
	var hw := TILE_SIZE * 0.5
	# Stone block
	draw_rect(Rect2(-hw, -hw, TILE_SIZE, TILE_SIZE), Color(0.5, 0.45, 0.4))
	draw_rect(Rect2(-hw, -hw, TILE_SIZE, TILE_SIZE), Color(0.6, 0.55, 0.5), false, 1.0)
	# Cross pattern
	draw_line(Vector2(-hw + 2, 0), Vector2(hw - 2, 0), Color(0.4, 0.35, 0.3), 1.0)
	draw_line(Vector2(0, -hw + 2), Vector2(0, hw - 2), Color(0.4, 0.35, 0.3), 1.0)


func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()
	if persist_id == &"":
		warnings.append("persist_id is empty — block position won't persist.")
	return warnings
