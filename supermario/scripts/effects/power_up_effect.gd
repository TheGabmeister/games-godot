extends Node2D

var _timer: float = 0.0
const DURATION := 0.5
const MAX_RADIUS := 24.0


func _process(delta: float) -> void:
	_timer += delta
	if _timer >= DURATION:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var t: float = _timer / DURATION
	var radius: float = MAX_RADIUS * t
	var alpha: float = 1.0 - t
	var color := Color(1.0, 0.95, 0.6, alpha * 0.5)
	# Expanding ring
	draw_arc(Vector2.ZERO, radius, 0, TAU, 24, color, 2.0)
	# Inner glow
	if t < 0.5:
		var inner_alpha: float = (0.5 - t) * 2.0 * 0.4
		draw_circle(Vector2.ZERO, radius * 0.5, Color(1.0, 1.0, 0.8, inner_alpha))
