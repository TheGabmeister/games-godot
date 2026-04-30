extends Node2D

const SpriteHelper := preload("res://scripts/visuals/sprite_region_helper.gd")
const SHEET := preload("res://sprites/goomba_sheet.png")
const COLUMNS := 3

var is_squished: bool = false
var _walk_cycle: float = 0.0
var _is_moving: bool = false
var _sprite: Sprite2D


func _ready() -> void:
	_sprite = SpriteHelper.ensure_sprite(self, &"Sprite", SHEET)
	SpriteHelper.set_cell(_sprite, 0, COLUMNS, Vector2(-16, -30))


func _process(delta: float) -> void:
	var body := owner as CharacterBody2D
	if body:
		_is_moving = absf(body.velocity.x) > 5.0
		if _is_moving:
			_walk_cycle += absf(body.velocity.x) * delta * 0.06
		else:
			_walk_cycle = 0.0

	var frame := 2 if is_squished else int(_walk_cycle * 8.0) % 2
	SpriteHelper.set_cell(_sprite, frame, COLUMNS, Vector2(-16, -30))
