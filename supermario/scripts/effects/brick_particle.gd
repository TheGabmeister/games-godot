extends Node2D

const SpriteHelper := preload("res://scripts/visuals/sprite_region_helper.gd")
const SHEET := preload("res://sprites/effects_sheet.png")

var _velocity: Vector2 = Vector2.ZERO
var _timer: float = 0.0
var _rotation_speed: float = 0.0
var _sprite: Sprite2D
const GRAVITY := 600.0
const LIFETIME := 1.0


func _ready() -> void:
	_sprite = SpriteHelper.ensure_sprite(self, &"Sprite", SHEET)
	SpriteHelper.set_cell(_sprite, 0, 6, Vector2(-16, -16), Vector2(0.45, 0.45))


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
