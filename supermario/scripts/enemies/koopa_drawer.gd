extends Node2D

const P := preload("res://scripts/color_palette.gd")

var _walk_cycle: float = 0.0
var _is_moving: bool = false


func _process(delta: float) -> void:
	var body := owner as CharacterBody2D
	if body:
		_is_moving = absf(body.velocity.x) > 5.0
		if _is_moving:
			_walk_cycle += absf(body.velocity.x) * delta * 0.06
		else:
			_walk_cycle = 0.0
	queue_redraw()


func _draw() -> void:
	# Origin at bottom center, 16x24
	var foot_offset := sin(_walk_cycle * TAU) * 2.0 if _is_moving else 0.0

	# Feet
	draw_rect(Rect2(-5, -3, 4, 3), P.KOOPA_GREEN.darkened(0.3))
	draw_rect(Rect2(1 + foot_offset, -3, 4, 3), P.KOOPA_GREEN.darkened(0.3))

	# Underbelly
	draw_rect(Rect2(-5, -12, 10, 9), Color(0.95, 0.85, 0.55))

	# Shell (dome)
	var pts := PackedVector2Array()
	for i in 13:
		var angle: float = PI - PI * float(i) / 12.0
		pts.append(Vector2(cos(angle) * 7.0, -12.0 + sin(angle) * -8.0))
	draw_colored_polygon(pts, P.KOOPA_GREEN)

	# Shell stripe
	draw_rect(Rect2(-5, -16, 10, 2), P.KOOPA_SHELL)

	# Head
	draw_circle(Vector2(4, -18), 3.5, P.KOOPA_GREEN.lightened(0.2))

	# Eye
	draw_circle(Vector2(5, -19), 1.5, Color.WHITE)
	draw_circle(Vector2(5.5, -19), 0.7, Color.BLACK)
