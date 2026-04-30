extends Node2D

const SpriteFramesBuilder := preload("res://scripts/visuals/sprite_frames_builder.gd")
const SHEET := preload("res://sprites/effects_sheet.png")
const ANIMATIONS := {
	&"default": {"frames": [3], "fps": 1.0, "loop": false},
}

var _timer: float = 0.0
const DURATION := 0.5
const MAX_SCALE := 1.5

@onready var _sprite: AnimatedSprite2D = $Sprite


func _ready() -> void:
	_sprite.sprite_frames = SpriteFramesBuilder.build(SHEET, 6, ANIMATIONS)
	_sprite.position = Vector2(-16, -16)


func _process(delta: float) -> void:
	_timer += delta
	if _timer >= DURATION:
		queue_free()
		return
	var t: float = _timer / DURATION
	var s := maxf(0.1, MAX_SCALE * t)
	_sprite.scale = Vector2(s, s)
	_sprite.modulate.a = 1.0 - t
