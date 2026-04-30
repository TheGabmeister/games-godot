extends "res://scripts/enemies/enemy_base.gd"

const SpriteHelper := preload("res://scripts/visuals/sprite_region_helper.gd")
const SHEET_COLUMNS := 3
const SPRITE_OFFSET := Vector2(-16, -30)
const SQUISH_DURATION := 0.5

@export var stomp_sound: AudioStream

var _squish_dying: bool = false
var _squish_timer: float = 0.0
var _walk_cycle: float = 0.0

@onready var _sprite: Sprite2D = $Visuals/Sprite


func _ready() -> void:
	super()
	_enemy_type = &"goomba"


func _process(delta: float) -> void:
	if absf(velocity.x) > 5.0:
		_walk_cycle += absf(velocity.x) * delta * 0.06
	else:
		_walk_cycle = 0.0
	_update_sprite()


func _physics_process(delta: float) -> void:
	if _squish_dying:
		_squish_timer -= delta
		if _squish_timer <= 0.0:
			call_deferred("queue_free")
		return
	super(delta)


func stomp_kill() -> bool:
	if _is_dead:
		return false
	_is_dead = true
	_play_sound(stomp_sound)
	EventBus.enemy_stomped.emit(global_position)
	CameraEffects.shake(2.0, 0.1)
	_start_squish_death()
	return true


func _start_squish_death() -> void:
	_squish_dying = true
	_disable_all_collision()
	velocity = Vector2.ZERO
	_squish_timer = SQUISH_DURATION
	_update_sprite()


func _update_sprite() -> void:
	var frame := 2 if _squish_dying else int(_walk_cycle * 8.0) % 2
	SpriteHelper.set_cell(_sprite, frame, SHEET_COLUMNS, SPRITE_OFFSET)


func _play_sound(sound: AudioStream) -> void:
	if sound != null:
		EventBus.sfx_requested.emit(sound)
