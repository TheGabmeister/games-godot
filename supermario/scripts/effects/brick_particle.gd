extends Node2D

const P := preload("res://scripts/color_palette.gd")

var _velocity: Vector2 = Vector2.ZERO
var _timer: float = 0.0
var _rotation_speed: float = 0.0
const GRAVITY := 600.0
const LIFETIME := 1.0


func setup(vel: Vector2) -> void:
	_velocity = vel
	_rotation_speed = randf_range(-10.0, 10.0)


func _process(delta: float) -> void:
	_timer += delta
	if _timer >= LIFETIME:
		queue_free()
		return
	_velocity.y += GRAVITY * delta
	position += _velocity * delta
	rotation += _rotation_speed * delta
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(-3, -3, 6, 6), P.BRICK_RED)
	draw_rect(Rect2(-3, -3, 6, 6), P.BRICK_DARK, false, 1.0)
