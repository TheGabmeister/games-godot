extends Room
## Desert cave with push block puzzle guarding a heart piece.


func _draw() -> void:
	draw_rect(Rect2(0, 0, 256, 224), Color(0.25, 0.22, 0.18))

	var wall_color := Color(0.4, 0.35, 0.25)
	draw_rect(Rect2(0, 0, 256, 32), wall_color)
	draw_rect(Rect2(0, 192, 112, 32), wall_color)
	draw_rect(Rect2(144, 192, 112, 32), wall_color)
	draw_rect(Rect2(0, 0, 32, 224), wall_color)
	draw_rect(Rect2(224, 0, 32, 224), wall_color)

	# Sandy floor detail
	var detail := Color(0.3, 0.28, 0.2)
	draw_circle(Vector2(90, 90), 2.5, detail)
	draw_circle(Vector2(170, 110), 3.0, detail)
	draw_circle(Vector2(100, 150), 2.0, detail)
