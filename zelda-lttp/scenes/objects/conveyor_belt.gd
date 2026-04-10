class_name ConveyorBelt extends Area2D
## Continuous directional push applied to entities standing on it.

@export var direction: Vector2 = Vector2.RIGHT
@export var push_speed: float = 40.0

var _bodies_on_belt: Array[CharacterBody2D] = []


func _ready() -> void:
	collision_layer = 128  # Triggers
	collision_mask = 6  # Player + Enemies
	monitoring = true
	monitorable = false

	if not _has_collision_shape():
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2(48, 16)
		shape.shape = rect
		add_child(shape)

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _has_collision_shape() -> bool:
	for child in get_children():
		if child is CollisionShape2D:
			return true
	return false


func _physics_process(delta: float) -> void:
	var push := direction.normalized() * push_speed * delta
	for body in _bodies_on_belt:
		if is_instance_valid(body):
			body.velocity += push / delta * 0.3  # Blend into existing velocity


func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D:
		_bodies_on_belt.append(body)


func _on_body_exited(body: Node2D) -> void:
	if body is CharacterBody2D:
		_bodies_on_belt.erase(body)


func _draw() -> void:
	# Draw belt surface
	var belt_color := Color(0.35, 0.35, 0.35)
	# Get shape size from child CollisionShape2D
	var hw := 24.0
	var hh := 8.0
	for child in get_children():
		if child is CollisionShape2D and child.shape is RectangleShape2D:
			hw = child.shape.size.x * 0.5
			hh = child.shape.size.y * 0.5
			break

	draw_rect(Rect2(-hw, -hh, hw * 2, hh * 2), belt_color)
	draw_rect(Rect2(-hw, -hh, hw * 2, hh * 2), belt_color.lightened(0.15), false, 1.0)

	# Direction arrows
	var arrow_color := Color(0.6, 0.55, 0.2)
	var dir := direction.normalized()
	var arrow_spacing := 16.0
	var perp := Vector2(-dir.y, dir.x)
	for i in range(-1, 2):
		var center := dir * i * arrow_spacing
		var tip := center + dir * 4.0
		var left := center - dir * 2.0 + perp * 3.0
		var right := center - dir * 2.0 - perp * 3.0
		draw_colored_polygon(PackedVector2Array([tip, left, right]), arrow_color)
