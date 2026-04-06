extends Node2D


func _draw() -> void:
	var enemy: BaseEnemy = get_parent() as BaseEnemy
	var color: Color = enemy.enemy_data.color if enemy and enemy.enemy_data else Color(0.8, 0.2, 0.15)
	var facing: Vector2 = enemy.facing_direction if enemy else Vector2.DOWN

	# Body: red rectangle
	draw_rect(Rect2(-6, -4, 12, 12), color)

	# Helmet triangle pointing in facing direction
	var helmet_color := color.darkened(0.3)
	var center := Vector2(0, -4)
	var tip: Vector2 = center + facing.normalized() * 6.0
	var perp := Vector2(-facing.y, facing.x).normalized()
	draw_colored_polygon(PackedVector2Array([
		tip,
		center + perp * 5.0,
		center - perp * 5.0,
	]), helmet_color)
