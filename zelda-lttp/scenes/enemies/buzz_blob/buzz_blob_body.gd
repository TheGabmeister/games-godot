extends Node2D

var _pulse_time: float = 0.0


func _process(delta: float) -> void:
	_pulse_time += delta
	queue_redraw()


func _draw() -> void:
	var enemy: BaseEnemy = get_parent() as BaseEnemy
	var color: Color = enemy.enemy_data.color if enemy and enemy.enemy_data else Color(0.9, 0.85, 0.2)

	# Pulsing yellow circle
	var pulse: float = 1.0 + sin(_pulse_time * 4.0) * 0.15
	var radius: float = 6.0 * pulse
	draw_circle(Vector2(0, 1), radius, color)

	# Electric highlights
	var highlight := color.lightened(0.4)
	var spark_offset: float = sin(_pulse_time * 7.0) * 3.0
	draw_circle(Vector2(spark_offset, -2), 1.5, highlight)
	draw_circle(Vector2(-spark_offset, 3), 1.0, highlight)
