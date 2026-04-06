extends Node2D


func _draw() -> void:
	var enemy: BaseEnemy = get_parent() as BaseEnemy
	var color: Color = enemy.enemy_data.color if enemy and enemy.enemy_data else Color(0.9, 0.9, 0.85)

	# Body: white triangle
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, -7),
		Vector2(6, 6),
		Vector2(-6, 6),
	]), color)

	# Eye dots
	var eye_color := Color(0.15, 0.1, 0.1)
	draw_circle(Vector2(-2, -1), 1.5, eye_color)
	draw_circle(Vector2(2, -1), 1.5, eye_color)
