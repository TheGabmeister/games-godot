extends Node2D


func _draw() -> void:
	var enemy: BaseEnemy = get_parent() as BaseEnemy
	var color: Color = enemy.enemy_data.color if enemy and enemy.enemy_data else Color(0.6, 0.2, 0.7)

	# Diamond body
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, -5),
		Vector2(5, 0),
		Vector2(0, 5),
		Vector2(-5, 0),
	]), color)

	# Wings
	var wing_color := color.lightened(0.2)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-3, -2),
		Vector2(-8, -4),
		Vector2(-6, 1),
	]), wing_color)
	draw_colored_polygon(PackedVector2Array([
		Vector2(3, -2),
		Vector2(8, -4),
		Vector2(6, 1),
	]), wing_color)
