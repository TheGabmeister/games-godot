extends Node2D

const SpriteHelper := preload("res://scripts/visuals/sprite_region_helper.gd")
const SHEET := preload("res://sprites/coin_sheet.png")

var _velocity: Vector2 = Vector2(0, -280.0)
var _timer: float = 0.0
var _spawn_y: float = 0.0
var _initialized: bool = false
var _sprite: Sprite2D
const GRAVITY := 900.0
const LIFETIME := 0.5
const SPIN_RATE := 6.0
const FADE_TIME := 0.1


func _ready() -> void:
	_sprite = SpriteHelper.ensure_sprite(self, &"Sprite", SHEET)
	SpriteHelper.set_cell(_sprite, 0, 4, Vector2(-16, -24), Vector2(0.65, 0.65))


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

	var frame := int(_timer * SPIN_RATE) % 4
	SpriteHelper.set_cell(_sprite, frame, 4, Vector2(-16, -24), Vector2(0.65, 0.65))

	var remaining: float = LIFETIME - _timer
	if remaining < FADE_TIME:
		modulate.a = remaining / FADE_TIME
