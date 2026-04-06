extends Node2D

var _timer: float = 0.0
const DURATION := 0.2


func _process(delta: float) -> void:
	_timer += delta
	if _timer >= DURATION:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var t: float = _timer / DURATION
	var radius: float = 4.0 + t * 8.0
	var alpha: float = 1.0 - t
	var color := Color(1.0, 1.0, 1.0, alpha * 0.6)
	for i in 6:
		var angle: float = float(i) / 6.0 * TAU
		var offset := Vector2(cos(angle), sin(angle)) * radius
		draw_circle(offset, 2.0 - t * 1.5, color)
