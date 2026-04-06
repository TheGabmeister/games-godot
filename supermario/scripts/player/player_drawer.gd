extends Node2D

const P := preload("res://scripts/color_palette.gd")

var power_state: int = 0  # GameManager.PowerState
var is_crouching: bool = false
var star_power_active: bool = false

# Animation state
var _walk_cycle: float = 0.0
var _is_moving: bool = false
var _star_cycle: float = 0.0


func _process(delta: float) -> void:
	var parent_body := owner as CharacterBody2D
	if parent_body:
		_is_moving = absf(parent_body.velocity.x) > 10.0
		if _is_moving:
			_walk_cycle += absf(parent_body.velocity.x) * delta * 0.05
		else:
			_walk_cycle = 0.0
	if star_power_active:
		_star_cycle += delta * 8.0
	queue_redraw()


func _draw() -> void:
	if power_state == 0:  # SMALL
		_draw_small_mario()
	else:
		if is_crouching:
			_draw_crouching_mario()
		else:
			_draw_big_mario()


func _draw_small_mario() -> void:
	# 16x16, origin at bottom center
	var foot_offset := _get_foot_offset()

	# Feet (two small rectangles)
	draw_rect(Rect2(-5, -3, 4, 3), P.MARIO_RED)
	draw_rect(Rect2(1 + foot_offset, -3, 4, 3), P.MARIO_RED)

	# Body / overalls
	draw_rect(Rect2(-6, -11, 12, 8), P.MARIO_BLUE)

	# Shirt / arms
	draw_rect(Rect2(-5, -13, 10, 3), P.MARIO_RED)

	# Head / skin
	draw_rect(Rect2(-4, -16, 8, 4), P.MARIO_SKIN)

	# Hat
	draw_rect(Rect2(-6, -18, 11, 3), _hat_color())

	# Eyes
	draw_rect(Rect2(0, -15, 2, 2), Color.WHITE)
	draw_rect(Rect2(1, -15, 1, 1), Color.BLACK)


func _draw_big_mario() -> void:
	# 16x32, origin at bottom center
	var foot_offset := _get_foot_offset()

	# Feet
	draw_rect(Rect2(-5, -4, 4, 4), P.MARIO_RED)
	draw_rect(Rect2(1 + foot_offset, -4, 4, 4), P.MARIO_RED)

	# Legs / overalls lower
	draw_rect(Rect2(-6, -14, 12, 10), P.MARIO_BLUE)

	# Belt line
	draw_rect(Rect2(-6, -15, 12, 1), P.MARIO_RED.darkened(0.3))

	# Shirt / torso
	draw_rect(Rect2(-6, -22, 12, 7), _hat_color())

	# Arms
	draw_rect(Rect2(-7, -20, 2, 5), P.MARIO_SKIN)
	draw_rect(Rect2(5, -20, 2, 5), P.MARIO_SKIN)

	# Head / skin
	draw_rect(Rect2(-5, -27, 10, 6), P.MARIO_SKIN)

	# Hat
	draw_rect(Rect2(-6, -30, 12, 4), _hat_color())

	# Eyes
	draw_rect(Rect2(0, -26, 2, 2), Color.WHITE)
	draw_rect(Rect2(1, -26, 1, 1), Color.BLACK)

	# Nose
	draw_rect(Rect2(2, -24, 2, 2), P.MARIO_SKIN.darkened(0.15))


func _draw_crouching_mario() -> void:
	# Big Mario crouching — compressed to ~16x16, origin at bottom center
	var foot_offset := _get_foot_offset()

	# Feet
	draw_rect(Rect2(-5, -3, 4, 3), P.MARIO_RED)
	draw_rect(Rect2(1 + foot_offset, -3, 4, 3), P.MARIO_RED)

	# Body compressed
	draw_rect(Rect2(-6, -11, 12, 8), P.MARIO_BLUE)

	# Shirt
	draw_rect(Rect2(-6, -14, 12, 3), _hat_color())

	# Head tucked
	draw_rect(Rect2(-4, -17, 8, 4), P.MARIO_SKIN)

	# Hat
	draw_rect(Rect2(-6, -19, 11, 3), _hat_color())

	# Eyes
	draw_rect(Rect2(0, -16, 2, 2), Color.WHITE)
	draw_rect(Rect2(1, -16, 1, 1), Color.BLACK)


func _hat_color() -> Color:
	if star_power_active:
		var idx := int(_star_cycle) % 4
		match idx:
			0: return P.STAR_YELLOW
			1: return P.MARIO_RED
			2: return Color(0.2, 0.8, 0.3)
			3: return P.MARIO_FIRE_WHITE
		return P.STAR_YELLOW
	if power_state == 2:  # FIRE
		return P.MARIO_FIRE_WHITE
	return P.MARIO_RED


func _get_foot_offset() -> float:
	if _is_moving:
		return sin(_walk_cycle * TAU) * 2.0
	return 0.0
