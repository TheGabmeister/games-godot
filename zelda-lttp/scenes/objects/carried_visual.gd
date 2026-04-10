extends Node2D
## Simple visual node drawn above the player while carrying an object.

var visual_type: StringName = &"pot"


func _draw() -> void:
	match visual_type:
		&"bush":
			draw_circle(Vector2.ZERO, 6.0, Color(0.35, 0.65, 0.25))
		&"skull":
			draw_circle(Vector2.ZERO, 5.0, Color(0.75, 0.7, 0.65))
			draw_circle(Vector2(-2, -1), 1.5, Color(0.15, 0.12, 0.1))
			draw_circle(Vector2(2, -1), 1.5, Color(0.15, 0.12, 0.1))
		&"sign":
			draw_rect(Rect2(-6, -4, 12, 8), Color(0.55, 0.4, 0.2))
			draw_rect(Rect2(-6, -4, 12, 8), Color(0.65, 0.48, 0.25), false, 1.0)
		_:  # pot
			draw_rect(Rect2(-5, -5, 10, 10), Color(0.55, 0.38, 0.22))
			draw_rect(Rect2(-5, -6, 10, 2), Color(0.65, 0.48, 0.3))
