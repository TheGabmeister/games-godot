class_name PressurePlate extends Area2D
## Activates when player or push block is on it. Deactivates when weight removed.

@export var sticky: bool = false  # If true, stays active once pressed
@export var linked_nodes: Array[NodePath] = []

var is_active: bool = false

signal activated()
signal deactivated()


func _ready() -> void:
	collision_layer = 128  # Triggers
	collision_mask = 3  # Player + World (for blocks)
	monitoring = true
	monitorable = false

	if not _has_collision_shape():
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2(14, 14)
		shape.shape = rect
		add_child(shape)

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	queue_redraw()


func _has_collision_shape() -> bool:
	for child in get_children():
		if child is CollisionShape2D:
			return true
	return false


func activate() -> void:
	if is_active:
		return
	is_active = true
	AudioManager.play_sfx(&"switch")
	activated.emit()
	_apply_state()
	queue_redraw()


func deactivate() -> void:
	if not is_active or sticky:
		return
	is_active = false
	deactivated.emit()
	_apply_state()
	queue_redraw()


func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D or body is PushBlock:
		activate()


func _on_body_exited(body: Node2D) -> void:
	if body is CharacterBody2D or body is PushBlock:
		# Check if anything is still on the plate
		if get_overlapping_bodies().is_empty():
			deactivate()


func _apply_state() -> void:
	for path in linked_nodes:
		var node := get_node_or_null(path)
		if node and node.has_method("set_switch_state"):
			node.set_switch_state(is_active)


func _draw() -> void:
	var color := Color(0.7, 0.6, 0.2) if is_active else Color(0.4, 0.35, 0.3)
	# Plate base
	draw_rect(Rect2(-7, -7, 14, 14), color)
	draw_rect(Rect2(-7, -7, 14, 14), color.lightened(0.2), false, 1.0)
	# Depressed center when active
	if is_active:
		draw_rect(Rect2(-5, -5, 10, 10), color.darkened(0.2))
