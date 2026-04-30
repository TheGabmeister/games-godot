extends Node2D

const SpriteFramesBuilder := preload("res://scripts/visuals/sprite_frames_builder.gd")
const SHEET := preload("res://sprites/effects_sheet.png")
const ANIMATIONS := {
	&"default": {"frames": [0], "fps": 1.0, "loop": false},
}

var _velocity: Vector2 = Vector2.ZERO
var _timer: float = 0.0
var _rotation_speed: float = 0.0
var _sprite: AnimatedSprite2D
const GRAVITY := 600.0
const LIFETIME := 1.0


func _ready() -> void:
	_sprite = SpriteFramesBuilder.ensure_sprite(self, &"Sprite", SHEET, 6, ANIMATIONS)
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
