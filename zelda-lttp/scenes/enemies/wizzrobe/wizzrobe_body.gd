extends Node2D


func _draw() -> void:
	var enemy: BaseEnemy = get_parent() as BaseEnemy
	var color: Color = enemy.enemy_data.color if enemy and enemy.enemy_data else Color(0.5, 0.2, 0.8)
	var facing: Vector2 = enemy.facing_direction if enemy else Vector2.DOWN

	# Hooded robe: triangle shape wider at the bottom
	var robe_color := color
	var robe_points := PackedVector2Array([
		Vector2(0, -8),    # Hood tip (top)
		Vector2(-7, 8),    # Bottom-left of robe
		Vector2(7, 8),     # Bottom-right of robe
	])
	draw_colored_polygon(robe_points, robe_color)

	# Hood shadow / darker inner area
	var hood_color := color.darkened(0.3)
	var hood_points := PackedVector2Array([
		Vector2(0, -6),
		Vector2(-5, 2),
		Vector2(5, 2),
	])
	draw_colored_polygon(hood_points, hood_color)

	# Face area: small dark oval inside the hood
	var face_color := Color(0.15, 0.08, 0.2)
	draw_circle(Vector2(0, -1), 3.0, face_color)

	# Eyes: two glowing dots, shift based on facing direction
	var eye_offset: Vector2 = facing.normalized() * 1.0
	var eye_color := Color(1.0, 0.3, 0.3)
	draw_circle(Vector2(-1.5, -1.5) + eye_offset, 0.8, eye_color)
	draw_circle(Vector2(1.5, -1.5) + eye_offset, 0.8, eye_color)

	# Robe bottom trim
	var trim_color := color.lightened(0.2)
	draw_line(Vector2(-7, 8), Vector2(7, 8), trim_color, 1.0)
