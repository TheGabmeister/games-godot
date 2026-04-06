extends Room


func _draw() -> void:
	# Wooden floor
	draw_rect(Rect2(0, 0, 256, 224), Color(0.55, 0.4, 0.25))

	# Floor plank lines
	var line_color := Color(0.45, 0.32, 0.2)
	for y_line in range(0, 224, 16):
		draw_line(Vector2(0, y_line), Vector2(256, y_line), line_color, 1.0)

	# Walls
	var wall_color := Color(0.65, 0.55, 0.4)
	draw_rect(Rect2(0, 0, 256, 32), wall_color)
	draw_rect(Rect2(0, 0, 32, 224), wall_color)
	draw_rect(Rect2(224, 0, 32, 224), wall_color)
	# Bottom wall with door gap
	draw_rect(Rect2(0, 192, 112, 32), wall_color)
	draw_rect(Rect2(144, 192, 112, 32), wall_color)

	# Table
	draw_rect(Rect2(60, 60, 40, 24), Color(0.5, 0.35, 0.2))
	# Bed
	draw_rect(Rect2(170, 50, 32, 48), Color(0.8, 0.3, 0.3))
	draw_rect(Rect2(170, 50, 32, 16), Color(0.9, 0.85, 0.8))
