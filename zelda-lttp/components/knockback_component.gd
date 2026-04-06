class_name KnockbackComponent extends Node

var _velocity: Vector2 = Vector2.ZERO
var _active: bool = false
var _timer: float = 0.0
var _duration: float = 0.0
var _initial_speed: float = 0.0

@export var default_duration: float = 0.2


func apply(direction: Vector2, force: float, duration: float = -1.0) -> void:
	var dir: Vector2 = direction.normalized() if direction != Vector2.ZERO else Vector2.DOWN
	_duration = duration if duration > 0.0 else default_duration
	_initial_speed = force
	_velocity = dir * force
	_timer = 0.0
	_active = true


func _physics_process(delta: float) -> void:
	if not _active:
		return

	_timer += delta
	var t: float = _timer / _duration
	if t >= 1.0:
		_active = false
		_velocity = Vector2.ZERO
		return

	# Decelerate linearly
	_velocity = _velocity.normalized() * _initial_speed * (1.0 - t)

	var body: CharacterBody2D = get_parent() as CharacterBody2D
	if body:
		body.velocity = _velocity
		body.move_and_slide()


func is_active() -> bool:
	return _active


func get_velocity() -> Vector2:
	return _velocity
