extends Room
## Mountain cave with a heart piece chest.


func _draw() -> void:
	draw_rect(Rect2(0, 0, 256, 224), Color(0.22, 0.2, 0.18))

	var wall_color := Color(0.38, 0.33, 0.28)
	draw_rect(Rect2(0, 0, 256, 32), wall_color)
	draw_rect(Rect2(0, 192, 112, 32), wall_color)
	draw_rect(Rect2(144, 192, 112, 32), wall_color)
	draw_rect(Rect2(0, 0, 32, 224), wall_color)
	draw_rect(Rect2(224, 0, 32, 224), wall_color)

	# Stalactite details
	var detail := Color(0.3, 0.27, 0.22)
	draw_colored_polygon(PackedVector2Array([
		Vector2(60, 32), Vector2(64, 50), Vector2(56, 50),
	]), detail)
	draw_colored_polygon(PackedVector2Array([
		Vector2(140, 32), Vector2(144, 48), Vector2(136, 48),
	]), detail)
	draw_colored_polygon(PackedVector2Array([
		Vector2(190, 32), Vector2(194, 55), Vector2(186, 55),
	]), detail)
