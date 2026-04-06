class_name WorldPortal extends Area2D
## Teleports the player between Light and Dark worlds at mirrored coordinates.

@export var target_world_type: StringName = &"dark"


func _ready() -> void:
	collision_layer = 128  # Triggers
	collision_mask = 2  # Player
	monitoring = true
	monitorable = false

	if not _has_collision_shape():
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2(16, 16)
		shape.shape = rect
		add_child(shape)

	body_entered.connect(_on_body_entered)


func _has_collision_shape() -> bool:
	for child in get_children():
		if child is CollisionShape2D:
			return true
	return false


func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D and body.collision_layer & 2:
		EventBus.world_switch_requested.emit(target_world_type)


func _draw() -> void:
	# Swirling portal visual
	var color: Color
	if target_world_type == &"dark":
		color = Color(0.5, 0.2, 0.6, 0.8)
	else:
		color = Color(0.3, 0.6, 0.9, 0.8)

	draw_circle(Vector2.ZERO, 8.0, color)
	draw_arc(Vector2.ZERO, 6.0, 0, TAU, 12, color.lightened(0.3), 1.5)
	draw_arc(Vector2.ZERO, 3.0, 0, TAU, 8, Color.WHITE * Color(1, 1, 1, 0.5), 1.0)
