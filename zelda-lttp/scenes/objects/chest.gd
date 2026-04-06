extends StaticBody2D

@export var item: ItemData
@export var persist_id: StringName = &""

var _opened: bool = false


func _ready() -> void:
	# Check if already opened via persist flag
	if persist_id != &"":
		var room_id: StringName = &""
		var room: Node = _find_room()
		if room and room.has_method("get_room_id"):
			room_id = room.get_room_id()
		elif room and "room_data" in room and room.room_data:
			room_id = room.room_data.room_id
		if room_id != &"" and GameManager.get_flag("%s/%s" % [room_id, persist_id]):
			_opened = true

	# Connect interaction
	var probe_areas: Array[Node] = []
	for child in get_children():
		if child is Area2D:
			probe_areas.append(child)
	if probe_areas.is_empty():
		# Create an interaction area
		var area := Area2D.new()
		area.collision_layer = 32  # Interactables
		area.collision_mask = 0
		area.monitorable = true
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2(16, 16)
		shape.shape = rect
		area.add_child(shape)
		add_child(area)

	queue_redraw()


func interact() -> void:
	if _opened or not item:
		return
	_opened = true

	# Set persist flag
	if persist_id != &"":
		var room_id: StringName = &""
		var room: Node = _find_room()
		if room and room.has_method("get_room_id"):
			room_id = room.get_room_id()
		elif room and "room_data" in room and room.room_data:
			room_id = room.room_data.room_id
		if room_id != &"":
			GameManager.set_flag("%s/%s" % [room_id, persist_id], true)

	AudioManager.play_sfx(&"chest_open")
	EventBus.item_get_requested.emit(item)
	queue_redraw()


func _find_room() -> Node:
	var node: Node = get_parent()
	while node:
		if "room_data" in node:
			return node
		node = node.get_parent()
	return null


func _draw() -> void:
	if _opened:
		# Open chest: dark interior with lid back
		draw_rect(Rect2(-8, -4, 16, 12), Color(0.25, 0.15, 0.1))
		draw_rect(Rect2(-8, -4, 16, 12), Color(0.5, 0.35, 0.15), false, 1.0)
		# Lid tilted back
		draw_colored_polygon(PackedVector2Array([
			Vector2(-8, -4), Vector2(8, -4),
			Vector2(7, -8), Vector2(-7, -8),
		]), Color(0.6, 0.4, 0.15))
	else:
		# Closed chest
		draw_rect(Rect2(-8, -4, 16, 12), Color(0.5, 0.35, 0.15))
		draw_rect(Rect2(-8, -4, 16, 12), Color(0.65, 0.45, 0.2), false, 1.0)
		# Lock/clasp
		draw_rect(Rect2(-2, 0, 4, 4), Color(0.8, 0.7, 0.2))
		# Lid line
		draw_line(Vector2(-8, -4), Vector2(8, -4), Color(0.4, 0.3, 0.1), 1.0)


func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()
	if persist_id == &"":
		warnings.append("persist_id is empty — chest state won't persist.")
	return warnings
