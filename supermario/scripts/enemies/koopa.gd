extends "res://scripts/enemies/enemy_base.gd"

const KoopaShellScene := preload("res://scenes/enemies/koopa_shell.tscn")

@export var stomp_sound: AudioStream

@onready var _sprite: AnimatedSprite2D = $Visuals/Sprite


func _ready() -> void:
	super()
	_enemy_type = &"koopa"
	_sprite.play(&"walk")


func _process(_delta: float) -> void:
	_sprite.speed_scale = absf(velocity.x) * 0.06 if absf(velocity.x) > 5.0 else 0.0


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
	var shell := KoopaShellScene.instantiate()
	shell.position = position
	get_parent().add_child(shell)
	shell.activate()
	call_deferred("queue_free")
	return true


func _play_sound(sound: AudioStream) -> void:
	if sound != null:
		EventBus.sfx_requested.emit(sound)
