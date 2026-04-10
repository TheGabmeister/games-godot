class_name DungeonSwitch extends StaticBody2D
## Toggleable switch activated by sword hit. Links to other elements via signal.

@export var persist_id: StringName = &""
@export var linked_nodes: Array[NodePath] = []

var is_active: bool = false

signal toggled(active: bool)


func _ready() -> void:
	collision_layer = 1  # World
	collision_mask = 0

	# Check persist state
	if persist_id != &"":
		var room_id := _get_room_id()
		if room_id != &"":
			is_active = GameManager.get_flag("%s/%s" % [room_id, persist_id], false)

	# Create hurtbox-like area for sword detection
	var area := Area2D.new()
	area.collision_layer = 0
	area.collision_mask = 8  # PlayerAttacks
	area.monitoring = true
	area.monitorable = false
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(14, 14)
	shape.shape = rect
	area.add_child(shape)
	add_child(area)
	area.area_entered.connect(_on_hit)

	# Apply initial state to linked nodes
	call_deferred("_apply_state")
	queue_redraw()


func _on_hit(_area: Area2D) -> void:
	toggle()


func toggle() -> void:
	is_active = not is_active
	AudioManager.play_sfx(&"switch")

	if persist_id != &"":
		var room_id := _get_room_id()
		if room_id != &"":
			GameManager.set_flag("%s/%s" % [room_id, persist_id], is_active)

	toggled.emit(is_active)
	_apply_state()
	queue_redraw()


func _apply_state() -> void:
	for path in linked_nodes:
		var node := get_node_or_null(path)
		if node and node.has_method("set_switch_state"):
			node.set_switch_state(is_active)


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
	# Crystal switch orb
	var base_color := Color(0.4, 0.35, 0.3)
	draw_rect(Rect2(-7, -3, 14, 6), base_color)

	if is_active:
		# Active: orange/red orb
		draw_circle(Vector2(0, -1), 5.0, Color(0.9, 0.5, 0.2))
		draw_circle(Vector2(-1, -2), 2.0, Color(1.0, 0.8, 0.5))
	else:
		# Inactive: blue orb
		draw_circle(Vector2(0, -1), 5.0, Color(0.2, 0.4, 0.8))
		draw_circle(Vector2(-1, -2), 2.0, Color(0.5, 0.7, 1.0))
