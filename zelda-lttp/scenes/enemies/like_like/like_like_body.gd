extends Node2D


func _draw() -> void:
	var enemy: BaseEnemy = get_parent() as BaseEnemy
	var color: Color = enemy.enemy_data.color if enemy and enemy.enemy_data else Color(0.7, 0.5, 0.3)
	var is_engulfing: bool = enemy._is_engulfing if enemy and "_is_engulfing" in enemy else false

	# Tube body — tall oval shape
	var body_color := color
	if is_engulfing:
		body_color = color.lightened(0.2)  # Pulsing when engulfing

	# Main body (elongated oval)
	draw_circle(Vector2(0, 0), 8.0, body_color)
	draw_rect(Rect2(-8, -4, 16, 12), body_color)
	draw_circle(Vector2(0, 8), 7.0, body_color)

	# Mouth opening at top
	var mouth_color := body_color.darkened(0.4)
	draw_circle(Vector2(0, -3), 5.0, mouth_color)
	# Inner mouth (darker)
	draw_circle(Vector2(0, -3), 3.0, mouth_color.darkened(0.3))

	# Texture ridges
	var ridge_color := body_color.darkened(0.15)
	draw_line(Vector2(-7, 2), Vector2(7, 2), ridge_color, 0.5)
	draw_line(Vector2(-6, 6), Vector2(6, 6), ridge_color, 0.5)
	draw_line(Vector2(-5, 10), Vector2(5, 10), ridge_color, 0.5)
