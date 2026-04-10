class_name SwitchDoor extends StaticBody2D
## A barrier that opens/closes based on a linked Switch or PressurePlate.

var is_open: bool = false


func _ready() -> void:
	collision_layer = 1  # World
	if not _has_collision_shape():
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2(16, 16)
		shape.shape = rect
		add_child(shape)
	queue_redraw()


func _has_collision_shape() -> bool:
	for child in get_children():
		if child is CollisionShape2D:
			return true
	return false


func set_switch_state(active: bool) -> void:
	is_open = active
	if is_open:
		collision_layer = 0
		for child in get_children():
			if child is CollisionShape2D:
				child.set_deferred("disabled", true)
	else:
		collision_layer = 1
		for child in get_children():
			if child is CollisionShape2D:
				child.set_deferred("disabled", false)
	queue_redraw()


func _draw() -> void:
	if is_open:
		# Open: subtle floor marks
		draw_rect(Rect2(-8, -8, 16, 16), Color(0.3, 0.25, 0.2, 0.3))
	else:
		# Closed: iron bars
		var bar_color := Color(0.5, 0.5, 0.55)
		draw_rect(Rect2(-8, -8, 16, 16), Color(0.3, 0.28, 0.25))
		for i in range(-6, 8, 4):
			draw_line(Vector2(i, -8), Vector2(i, 8), bar_color, 1.5)
		draw_line(Vector2(-8, 0), Vector2(8, 0), bar_color, 1.0)
