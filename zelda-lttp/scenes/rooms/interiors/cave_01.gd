extends Room


func _draw() -> void:
	# Cave floor: dark stone
	draw_rect(Rect2(0, 0, 256, 224), Color(0.2, 0.18, 0.16))

	# Wall borders
	var wall_color := Color(0.35, 0.3, 0.25)
	# Top wall
	draw_rect(Rect2(0, 0, 256, 32), wall_color)
	# Bottom wall (with gap for entrance)
	draw_rect(Rect2(0, 192, 112, 32), wall_color)
	draw_rect(Rect2(144, 192, 112, 32), wall_color)
	# Left wall
	draw_rect(Rect2(0, 0, 32, 224), wall_color)
	# Right wall
	draw_rect(Rect2(224, 0, 32, 224), wall_color)

	# Some rocky texture details
	var detail_color := Color(0.25, 0.22, 0.18)
	draw_circle(Vector2(80, 80), 3.0, detail_color)
	draw_circle(Vector2(160, 100), 2.5, detail_color)
	draw_circle(Vector2(120, 140), 2.0, detail_color)
