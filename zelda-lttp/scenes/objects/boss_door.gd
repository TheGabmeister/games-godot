class_name BossDoor extends StaticBody2D
## Requires the big key scoped to its containing room's dungeon_id.
## Does NOT consume the big key — just gates on it.

@export var persist_id: StringName = &""

var _opened: bool = false
var _dungeon_id: StringName = &""


func _ready() -> void:
	collision_layer = 1  # World
	_dungeon_id = _get_dungeon_id()

	# Check persist state
	if persist_id != &"":
		var room_id := _get_room_id()
		if room_id != &"" and GameManager.get_flag("%s/%s" % [room_id, persist_id]):
			_opened = true
			_make_passable()

	# Create interaction area
	var area := Area2D.new()
	area.collision_layer = 32  # Interactables
	area.collision_mask = 0
	area.monitorable = true
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(20, 20)
	shape.shape = rect
	area.add_child(shape)
	add_child(area)

	queue_redraw()


func interact() -> void:
	if _opened:
		return

	var has_big_key: bool = GameManager.get_flag("%s/has_big_key" % _dungeon_id, false)
	if has_big_key:
		_opened = true
		AudioManager.play_sfx(&"door_unlock")

		if persist_id != &"":
			var room_id := _get_room_id()
			if room_id != &"":
				GameManager.set_flag("%s/%s" % [room_id, persist_id], true)

		_make_passable()
		queue_redraw()
	else:
		AudioManager.play_sfx(&"error")


func _make_passable() -> void:
	collision_layer = 0
	collision_mask = 0
	for child in get_children():
		if child is CollisionShape2D:
			child.set_deferred("disabled", true)


func _get_dungeon_id() -> StringName:
	var room := _find_room()
	if room and "dungeon_id" in room:
		return room.dungeon_id
	return &""


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
	if _opened:
		draw_rect(Rect2(-10, -10, 20, 20), Color(0.1, 0.08, 0.06))
	else:
		# Big ornate door
		draw_rect(Rect2(-10, -10, 20, 20), Color(0.35, 0.2, 0.1))
		draw_rect(Rect2(-10, -10, 20, 20), Color(0.6, 0.5, 0.2), false, 1.5)
		# Ornate keyhole
		draw_circle(Vector2(0, -2), 3.0, Color(0.7, 0.6, 0.2))
		draw_circle(Vector2(0, -2), 2.0, Color(0.15, 0.1, 0.08))
		draw_rect(Rect2(-1.5, 0, 3, 5), Color(0.15, 0.1, 0.08))
		# Corner decorations
		for corner in [Vector2(-8, -8), Vector2(8, -8), Vector2(-8, 8), Vector2(8, 8)]:
			draw_circle(corner, 2.0, Color(0.7, 0.6, 0.2))


func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()
	if persist_id == &"":
		warnings.append("persist_id is empty — door state won't persist.")
	return warnings
