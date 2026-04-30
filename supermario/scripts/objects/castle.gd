extends Node2D

const SpriteFramesBuilder := preload("res://scripts/visuals/sprite_frames_builder.gd")
const SHEET := preload("res://sprites/castle_sheet.png")
const ANIMATIONS := {
	&"default": {"frames": [0], "fps": 1.0, "loop": false},
}

var _sprite: AnimatedSprite2D


func _ready() -> void:
	_sprite = SpriteFramesBuilder.ensure_sprite(self, &"Sprite", SHEET, 1, ANIMATIONS)
	_sprite.position = Vector2(-40, -70)
	_sprite.scale = Vector2(2.5, 2.5)
