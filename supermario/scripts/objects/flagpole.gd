extends Node2D

const POLE_HEIGHT: float = 320.0

@export var flagpole_sound: AudioStream

var _flag_offset_y: float = 0.0
var _triggered: bool = false
@onready var _detect_area: Area2D = $DetectArea
@onready var _pole_sprite: AnimatedSprite2D = $PoleSprite
@onready var _ball_sprite: AnimatedSprite2D = $BallSprite
@onready var _flag_sprite: AnimatedSprite2D = $FlagSprite
@onready var _base_sprite: AnimatedSprite2D = $BaseSprite


func _ready() -> void:
	_detect_area.body_entered.connect(_on_body_entered)
	_pole_sprite.animation = &"pole"
	_ball_sprite.animation = &"ball"
	_flag_sprite.animation = &"flag"
	_base_sprite.animation = &"base"
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
	_pole_sprite.position = Vector2(-16, -POLE_HEIGHT)
	_pole_sprite.scale = Vector2(1.0, 10.0)
	_ball_sprite.position = Vector2(-16, -POLE_HEIGHT - 16)
	_flag_sprite.position = Vector2(-42, -POLE_HEIGHT + _flag_offset_y)
	_base_sprite.position = Vector2(-16, -32)


func _play_sound(sound: AudioStream) -> void:
	if sound != null:
		EventBus.sfx_requested.emit(sound)
