extends Node2D

const SpriteHelper := preload("res://scripts/visuals/sprite_region_helper.gd")
const SHEET := preload("res://sprites/powerups_sheet.png")

var is_one_up: bool = false
var _sprite: Sprite2D


func _ready() -> void:
	_sprite = SpriteHelper.ensure_sprite(self, &"Sprite", SHEET)
	_update_sprite()


func set_one_up(value: bool) -> void:
	is_one_up = value
	_update_sprite()


func _update_sprite() -> void:
	if _sprite == null:
		return
	SpriteHelper.set_cell(_sprite, 1 if is_one_up else 0, 5, Vector2(-16, -30))
