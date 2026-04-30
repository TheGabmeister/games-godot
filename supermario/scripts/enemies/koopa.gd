extends "res://scripts/enemies/enemy_base.gd"

const SpriteHelper := preload("res://scripts/visuals/sprite_region_helper.gd")
const SHEET_COLUMNS := 3
const SPRITE_OFFSET := Vector2(-16, -30)
const KoopaShellScene := preload("res://scenes/enemies/koopa_shell.tscn")

@export var stomp_sound: AudioStream

var _walk_cycle: float = 0.0

@onready var _sprite: Sprite2D = $Visuals/Sprite


func _ready() -> void:
	super()
	_enemy_type = &"koopa"


func _process(delta: float) -> void:
	var is_moving := absf(velocity.x) > 5.0
	if is_moving:
		_walk_cycle += absf(velocity.x) * delta * 0.06
	else:
		_walk_cycle = 0.0
	var frame := int(_walk_cycle * 8.0) % 2 if is_moving else 0
	SpriteHelper.set_cell(_sprite, frame, SHEET_COLUMNS, SPRITE_OFFSET)


func _physics_process(delta: float) -> void:
	super(delta)
	if not _is_dead and not _flip_dying:
		_visuals.scale.x = -1.0 if direction > 0.0 else 1.0


func stomp_kill() -> bool:
	if _is_dead:
		return false
	_is_dead = true
	_play_sound(stomp_sound)
	EventBus.enemy_stomped.emit(global_position)
	CameraEffects.shake(2.0, 0.1)
	# Spawn shell at this position
	var shell := KoopaShellScene.instantiate()
	shell.position = position
	get_parent().add_child(shell)
	shell.activate()
	call_deferred("queue_free")
	return true


func _play_sound(sound: AudioStream) -> void:
	if sound != null:
		EventBus.sfx_requested.emit(sound)
