extends Node2D

const SpriteHelper := preload("res://scripts/visuals/sprite_region_helper.gd")
const SHEET := preload("res://sprites/flagpole_sheet.png")
const POLE_HEIGHT: float = 320.0

@export var flagpole_sound: AudioStream

var _flag_offset_y: float = 0.0
var _triggered: bool = false
var _pole_sprite: Sprite2D
var _ball_sprite: Sprite2D
var _flag_sprite: Sprite2D
var _base_sprite: Sprite2D

@onready var _detect_area: Area2D = $DetectArea


func _ready() -> void:
	_detect_area.body_entered.connect(_on_body_entered)
	_pole_sprite = SpriteHelper.ensure_sprite(self, &"PoleSprite", SHEET)
	_ball_sprite = SpriteHelper.ensure_sprite(self, &"BallSprite", SHEET)
	_flag_sprite = SpriteHelper.ensure_sprite(self, &"FlagSprite", SHEET)
	_base_sprite = SpriteHelper.ensure_sprite(self, &"BaseSprite", SHEET)
	_update_sprites()


func get_pole_top_y() -> float:
	return global_position.y - POLE_HEIGHT


func get_pole_bottom_y() -> float:
	return global_position.y


func get_pole_x() -> float:
	return global_position.x


func slide_flag_to_bottom() -> void:
	var tween := create_tween()
	tween.tween_property(self, "_flag_offset_y", POLE_HEIGHT - 32.0, 0.8)


func get_height_ratio(grab_y: float) -> float:
	var pole_top: float = global_position.y - POLE_HEIGHT
	var pole_bottom: float = global_position.y
	var ratio: float = 1.0 - (grab_y - pole_top) / (pole_bottom - pole_top)
	return clampf(ratio, 0.0, 1.0)


func get_height_bonus(height_ratio: float) -> int:
	if height_ratio >= 0.95:
		return 5000
	elif height_ratio >= 0.8:
		return 2000
	elif height_ratio >= 0.6:
		return 800
	elif height_ratio >= 0.4:
		return 400
	elif height_ratio >= 0.2:
		return 200
	return 100


func _on_body_entered(body: Node2D) -> void:
	if _triggered:
		return
	if not body.is_in_group("player"):
		return
	_triggered = true
	var grab_y: float = body.global_position.y - 16.0
	var height_ratio: float = get_height_ratio(grab_y)
	var bonus: int = get_height_bonus(height_ratio)

	EventBus.flagpole_reached.emit(height_ratio)
	GameManager.add_score(bonus, Vector2(global_position.x, grab_y))
	_play_sound(flagpole_sound)

	slide_flag_to_bottom()

	if body.has_method("start_flagpole"):
		body.start_flagpole(self)


func _process(_delta: float) -> void:
	_update_sprites()


func _update_sprites() -> void:
	SpriteHelper.set_cell(_pole_sprite, 0, 4, Vector2(-16, -POLE_HEIGHT), Vector2(1.0, 10.0))
	SpriteHelper.set_cell(_ball_sprite, 1, 4, Vector2(-16, -POLE_HEIGHT - 16))
	SpriteHelper.set_cell(_flag_sprite, 2, 4, Vector2(-42, -POLE_HEIGHT + _flag_offset_y))
	SpriteHelper.set_cell(_base_sprite, 3, 4, Vector2(-16, -32))


func _play_sound(sound: AudioStream) -> void:
	if sound != null:
		EventBus.sfx_requested.emit(sound)
