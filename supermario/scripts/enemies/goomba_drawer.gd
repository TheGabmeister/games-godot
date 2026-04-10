extends Node2D

var is_squished: bool = false
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
	if is_squished:
		_draw_squished()
	else:
		_draw_normal()


func _draw_normal() -> void:
	# Origin at bottom center, 16x16
	var foot_offset := sin(_walk_cycle * TAU) * 2.0 if _is_moving else 0.0

	# Feet (dark brown, alternating)
	draw_rect(Rect2(-6, -3, 5, 3), Palette.GOOMBA_DARK)
	draw_rect(Rect2(1 + foot_offset, -3, 5, 3), Palette.GOOMBA_DARK)

	# Body (trapezoid)
	var body_pts := PackedVector2Array([
		Vector2(-7, -3), Vector2(7, -3),
		Vector2(5, -13), Vector2(-5, -13),
	])
	draw_colored_polygon(body_pts, Palette.GOOMBA_BROWN)

	# Eyes
	draw_circle(Vector2(-2.5, -10), 2.0, Color.WHITE)
	draw_circle(Vector2(2.5, -10), 2.0, Color.WHITE)
	draw_circle(Vector2(-2, -10), 1.0, Color.BLACK)
	draw_circle(Vector2(3, -10), 1.0, Color.BLACK)

	# Eyebrows
	draw_rect(Rect2(-4.5, -12.5, 3, 1), Palette.GOOMBA_DARK)
	draw_rect(Rect2(1.5, -12.5, 3, 1), Palette.GOOMBA_DARK)


func _draw_squished() -> void:
	# Flattened, ~16x4
	draw_rect(Rect2(-7, -4, 14, 4), Palette.GOOMBA_BROWN)
	draw_rect(Rect2(-3, -3, 2, 1), Palette.GOOMBA_DARK)
	draw_rect(Rect2(1, -3, 2, 1), Palette.GOOMBA_DARK)
