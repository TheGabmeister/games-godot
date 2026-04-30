extends Node2D

@onready var _sprite: AnimatedSprite2D = $Sprite


func _ready() -> void:
	_sprite.animation = &"default"
	_sprite.position = Vector2(-40, -70)
	_sprite.scale = Vector2(2.5, 2.5)
