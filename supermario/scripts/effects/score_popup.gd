extends Node2D

var _effects: Resource
var _timer: float = 0.0
var _points: int = 0


func setup(points: int, effects_config: Resource) -> void:
	_points = points
	_effects = effects_config


func _process(delta: float) -> void:
	_timer += delta
	var t: float = _timer / _effects.score_popup_duration
	if t >= 1.0:
		queue_free()
		return
	position.y -= _effects.score_popup_rise_speed * delta
	modulate.a = 1.0 - t * t
	queue_redraw()


func _draw() -> void:
	var text := str(_points)
	# Draw each digit as a small rectangle-based number
	var x_offset: float = -float(text.length()) * 3.0
	for i in text.length():
		var ch := text[i]
		_draw_digit(Vector2(x_offset + i * 7.0, -8), ch)


func _draw_digit(pos: Vector2, ch: String) -> void:
	# Simple 5x7 pixel digit rendering
	var segs := _get_segments(ch)
	for seg in segs:
		draw_rect(Rect2(pos.x + seg.x, pos.y + seg.y, seg.z, seg.w), Color.WHITE)


func _get_segments(ch: String) -> Array[Vector4]:
	match ch:
		"0": return [Vector4(0,0,5,1), Vector4(0,6,5,1), Vector4(0,0,1,7), Vector4(4,0,1,7)]
		"1": return [Vector4(2,0,1,7)]
		"2": return [Vector4(0,0,5,1), Vector4(4,0,1,4), Vector4(0,3,5,1), Vector4(0,3,1,4), Vector4(0,6,5,1)]
		"3": return [Vector4(0,0,5,1), Vector4(0,3,5,1), Vector4(0,6,5,1), Vector4(4,0,1,7)]
		"4": return [Vector4(0,0,1,4), Vector4(0,3,5,1), Vector4(4,0,1,7)]
		"5": return [Vector4(0,0,5,1), Vector4(0,0,1,4), Vector4(0,3,5,1), Vector4(4,3,1,4), Vector4(0,6,5,1)]
		"6": return [Vector4(0,0,5,1), Vector4(0,0,1,7), Vector4(0,3,5,1), Vector4(4,3,1,4), Vector4(0,6,5,1)]
		"7": return [Vector4(0,0,5,1), Vector4(4,0,1,7)]
		"8": return [Vector4(0,0,5,1), Vector4(0,3,5,1), Vector4(0,6,5,1), Vector4(0,0,1,7), Vector4(4,0,1,7)]
		"9": return [Vector4(0,0,5,1), Vector4(0,0,1,4), Vector4(0,3,5,1), Vector4(4,0,1,7), Vector4(0,6,5,1)]
	return []
