extends Node2D

var _velocity: Vector2 = Vector2.ZERO
var _timer: float = 0.0
var _rotation_speed: float = 0.0
const GRAVITY := 600.0
const LIFETIME := 1.0

@onready var _sprite: AnimatedSprite2D = $Sprite


func _ready() -> void:
	_sprite.animation = &"brick"
	_sprite.position = Vector2(-16, -16)
	_sprite.scale = Vector2(0.45, 0.45)


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
