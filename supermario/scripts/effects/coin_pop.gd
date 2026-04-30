extends Node2D

var _velocity: Vector2 = Vector2(0, -280.0)
var _timer: float = 0.0
var _spawn_y: float = 0.0
var _initialized: bool = false
const GRAVITY := 900.0
const LIFETIME := 0.5
const SPIN_RATE := 6.0
const FADE_TIME := 0.1

@onready var _sprite: AnimatedSprite2D = $Sprite


func _ready() -> void:
	_sprite.animation = &"spin"
	_sprite.position = Vector2(-16, -24)
	_sprite.scale = Vector2(0.65, 0.65)
	_sprite.play()


func _process(delta: float) -> void:
	if not _initialized:
		_spawn_y = global_position.y
		_initialized = true

	_timer += delta
	_velocity.y += GRAVITY * delta
	position.y += _velocity.y * delta

	if _timer >= LIFETIME or (_velocity.y > 0 and global_position.y >= _spawn_y):
		queue_free()
		return

	var remaining: float = LIFETIME - _timer
	if remaining < FADE_TIME:
		modulate.a = remaining / FADE_TIME
