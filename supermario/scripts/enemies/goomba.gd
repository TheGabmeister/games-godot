extends "res://scripts/enemies/enemy_base.gd"

const SQUISH_DURATION := 0.5

@export var stomp_sound: AudioStream

var _squish_dying: bool = false
var _squish_timer: float = 0.0

@onready var _sprite: AnimatedSprite2D = $Visuals/Sprite


func _ready() -> void:
	super()
	_enemy_type = &"goomba"
	_sprite.play(&"walk")


func _process(_delta: float) -> void:
	if not _squish_dying:
		_sprite.speed_scale = absf(velocity.x) * 0.06 if absf(velocity.x) > 5.0 else 0.0


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
	_start_squish_death()
	return true


func _start_squish_death() -> void:
	_squish_dying = true
	_disable_all_collision()
	velocity = Vector2.ZERO
	_squish_timer = SQUISH_DURATION
	_sprite.play(&"squished")


func _play_sound(sound: AudioStream) -> void:
	if sound != null:
		EventBus.sfx_requested.emit(sound)
