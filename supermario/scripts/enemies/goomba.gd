extends "res://scripts/enemies/enemy_base.gd"

var _squish_dying: bool = false
var _squish_timer: float = 0.0
const SQUISH_DURATION := 0.5

@export var stomp_sound: AudioStream

@onready var _drawer: Node2D = $Visuals/Drawer


func _ready() -> void:
	super()
	_enemy_type = &"goomba"


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
	_drawer.is_squished = true


func _play_sound(sound: AudioStream) -> void:
	if sound != null:
		EventBus.sfx_requested.emit(sound)
