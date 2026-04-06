extends Node2D


func _draw() -> void:
	var enemy: BaseEnemy = get_parent() as BaseEnemy
	var color: Color = enemy.enemy_data.color if enemy and enemy.enemy_data else Color(0.8, 0.15, 0.1)

	# Body: red circle
	draw_circle(Vector2(0, 1), 6.0, color)

	# Snout nub in facing direction
	var facing: Vector2 = enemy.facing_direction if enemy else Vector2.DOWN
	var snout_pos: Vector2 = facing.normalized() * 5.0
	draw_circle(snout_pos, 2.5, color.darkened(0.2))
