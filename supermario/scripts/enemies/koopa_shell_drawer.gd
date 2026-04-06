extends Node2D

const P := preload("res://scripts/color_palette.gd")

var _spin_cycle: float = 0.0


func _process(delta: float) -> void:
	var body := owner as CharacterBody2D
	if body and absf(body.velocity.x) > 5.0:
		_spin_cycle += absf(body.velocity.x) * delta * 0.04
	queue_redraw()


func _draw() -> void:
	# Origin at bottom center, 16x14 shell
	# Shell body (rounded shape via polygon)
	var pts := PackedVector2Array()
	# Bottom flat, top dome
	pts.append(Vector2(-7, -2))
	pts.append(Vector2(7, -2))
	pts.append(Vector2(7, -6))
	# Top dome
	for i in 9:
		var angle: float = -PI * float(i) / 8.0
		pts.append(Vector2(cos(angle) * 7.0, -6.0 + sin(angle) * -6.0))
	pts.append(Vector2(-7, -6))
	draw_colored_polygon(pts, P.KOOPA_GREEN)

	# Shell underside
	draw_rect(Rect2(-6, -2, 12, 2), Color(0.95, 0.85, 0.55))

	# Shell pattern (animated stripe when spinning)
	var stripe_offset := sin(_spin_cycle * TAU) * 3.0
	draw_rect(Rect2(-4 + stripe_offset, -9, 8, 2), P.KOOPA_SHELL)

	# Highlight
	draw_rect(Rect2(-3, -11, 6, 1), P.KOOPA_GREEN.lightened(0.3))
