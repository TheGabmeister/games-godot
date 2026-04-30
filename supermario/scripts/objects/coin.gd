extends Area2D

const SpriteHelper := preload("res://scripts/visuals/sprite_region_helper.gd")
const SHEET := preload("res://sprites/coin_sheet.png")

@export var collect_sound: AudioStream

var _spin_time: float = 0.0
var _collected: bool = false
var _sprite: Sprite2D


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_sprite = SpriteHelper.ensure_sprite(self, &"Sprite", SHEET)
	SpriteHelper.set_cell(_sprite, 0, 4, Vector2(-16, -25), Vector2(0.75, 0.75))


func _process(delta: float) -> void:
	_spin_time += delta
	var frame := int(_spin_time * 6.0) % 4
	SpriteHelper.set_cell(_sprite, frame, 4, Vector2(-16, -25), Vector2(0.75, 0.75))


func _on_body_entered(_body: Node2D) -> void:
	_collect()


func _collect() -> void:
	if _collected:
		return
	_collected = true
	if collect_sound != null:
		EventBus.sfx_requested.emit(collect_sound)
	GameManager.add_coin(global_position)
	queue_free()
