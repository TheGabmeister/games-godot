extends Room
## Graveyard cave — NPC gives heart piece reward.


func _draw() -> void:
	draw_rect(Rect2(0, 0, 256, 224), Color(0.18, 0.16, 0.2))

	var wall_color := Color(0.32, 0.28, 0.35)
	draw_rect(Rect2(0, 0, 256, 32), wall_color)
	draw_rect(Rect2(0, 192, 112, 32), wall_color)
	draw_rect(Rect2(144, 192, 112, 32), wall_color)
	draw_rect(Rect2(0, 0, 32, 224), wall_color)
	draw_rect(Rect2(224, 0, 32, 224), wall_color)

	# Mysterious glowing detail
	draw_circle(Vector2(128, 60), 15.0, Color(0.15, 0.1, 0.25, 0.4))
