extends Node2D

var _effects: Resource

var _trail_positions: Array[Vector2] = []
var _trail_alphas: Array[float] = []
var _distance_accum: float = 0.0
var _last_pos: Vector2 = Vector2.ZERO
const MAX_TRAIL := 5
const MIN_SPEED := 180.0


func _ready() -> void:
	_effects = (owner as CharacterBody2D).effects if owner else preload("res://resources/config/effects_default.tres")


func _process(delta: float) -> void:
	var body := get_parent() as CharacterBody2D
	if not body or not _effects:
		return

	var speed := absf(body.velocity.x)
	if speed < MIN_SPEED:
		_trail_positions.clear()
		_trail_alphas.clear()
		_distance_accum = 0.0
		_last_pos = body.global_position
		queue_redraw()
		return

	var moved := body.global_position.distance_to(_last_pos)
	_distance_accum += moved
	_last_pos = body.global_position

	if _distance_accum >= _effects.motion_trail_spacing:
		_distance_accum = 0.0
		_trail_positions.push_front(body.global_position)
		_trail_alphas.push_front(0.3)
		if _trail_positions.size() > MAX_TRAIL:
			_trail_positions.pop_back()
			_trail_alphas.pop_back()

	# Fade trail
	for i in _trail_alphas.size():
		_trail_alphas[i] -= delta * 2.0

	# Remove faded entries
	while _trail_alphas.size() > 0 and _trail_alphas.back() <= 0.0:
		_trail_alphas.pop_back()
		_trail_positions.pop_back()

	queue_redraw()


func _draw() -> void:
	var body := get_parent() as CharacterBody2D
	if not body or _trail_positions.is_empty():
		return
	for i in _trail_positions.size():
		var pos: Vector2 = _trail_positions[i] - body.global_position
		var alpha: float = maxf(_trail_alphas[i], 0.0)
		var color := Color(0.9, 0.15, 0.15, alpha)
		draw_rect(Rect2(pos.x - 4, pos.y - 10, 8, 10), color)
