extends "res://scripts/enemies/enemy_base.gd"

const KoopaShellScene := preload("res://scenes/enemies/koopa_shell.tscn")


func _ready() -> void:
	super()
	speed = 35.0
	_enemy_type = &"koopa"


func _physics_process(delta: float) -> void:
	super(delta)
	if not _is_dead and not _flip_dying:
		_visuals.scale.x = -1.0 if direction > 0.0 else 1.0


func stomp_kill() -> bool:
	if _is_dead:
		return false
	_is_dead = true
	EventBus.enemy_stomped.emit(global_position)
	CameraEffects.shake(2.0, 0.1)
	# Spawn shell at this position
	var shell := KoopaShellScene.instantiate()
	shell.position = position
	get_parent().add_child(shell)
	shell.activate()
	call_deferred("queue_free")
	return true
