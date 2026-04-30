extends Node2D

const SpriteHelper := preload("res://scripts/visuals/sprite_region_helper.gd")
const SHEET := preload("res://sprites/koopa_shell_sheet.png")
const COLUMNS := 4

var _spin_cycle: float = 0.0
var _sprite: Sprite2D


func _ready() -> void:
	_sprite = SpriteHelper.ensure_sprite(self, &"Sprite", SHEET)
	SpriteHelper.set_cell(_sprite, 0, COLUMNS, Vector2(-16, -30))


func _process(delta: float) -> void:
	var body := owner as CharacterBody2D
	if body and absf(body.velocity.x) > 5.0:
		_spin_cycle += absf(body.velocity.x) * delta * 0.04
	var frame := int(_spin_cycle * 8.0) % COLUMNS
	SpriteHelper.set_cell(_sprite, frame, COLUMNS, Vector2(-16, -30))
