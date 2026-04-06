extends Node2D

const P := preload("res://scripts/color_palette.gd")

var _velocity: Vector2 = Vector2(0, -280.0)
var _timer: float = 0.0
var _spawn_y: float = 0.0
var _initialized: bool = false
const GRAVITY := 900.0
const LIFETIME := 0.5
const SPIN_RATE := 6.0
const FADE_TIME := 0.1


func _process(delta: float) -> void:
	if not _initialized:
		_spawn_y = global_position.y
		_initialized = true

	_timer += delta
	_velocity.y += GRAVITY * delta
	position.y += _velocity.y * delta

	# End when falling back past spawn point or lifetime exceeded
	if _timer >= LIFETIME or (_velocity.y > 0 and global_position.y >= _spawn_y):
		queue_free()
		return

	# Fade in last 0.1s
	var remaining: float = LIFETIME - _timer
	if remaining < FADE_TIME:
		modulate.a = remaining / FADE_TIME

	queue_redraw()


func _draw() -> void:
	# Spinning coin: scale.x oscillates to simulate rotation
	var spin: float = cos(_timer * TAU * SPIN_RATE)
	var half_w: float = 4.0 * absf(spin)
	if half_w < 0.5:
		half_w = 0.5
	# Coin body
	draw_rect(Rect2(-half_w, -6, half_w * 2.0, 10), P.COIN_GOLD)
	# Highlight
	if half_w > 1.5:
		draw_rect(Rect2(-half_w + 1, -4, 2, 6), P.COIN_SHINE)
	# Border
	draw_rect(Rect2(-half_w, -6, half_w * 2.0, 10), P.COIN_GOLD.darkened(0.3), false, 1.0)
