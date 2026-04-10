extends CharacterBody2D

@export var config: Resource  # EnemyConfig

var speed: float = 40.0
var direction: float = -1.0
var _is_active: bool = false
var _is_dead: bool = false
var _enemy_type: StringName = &"enemy"
var _flip_dying: bool = false

@onready var _hitbox: Area2D = $Hitbox
@onready var _visuals: Node2D = $Visuals


func _ready() -> void:
	set_physics_process(false)
	visible = false
	add_to_group("enemies")


func activate() -> void:
	if _is_active:
		return
	_is_active = true
	if config:
		speed = config.patrol_speed
	set_physics_process(true)
	visible = true


func is_active() -> bool:
	return _is_active


func is_dead() -> bool:
	return _is_dead


func is_dangerous() -> bool:
	return _is_active and not _is_dead


func _physics_process(delta: float) -> void:
	if _flip_dying:
		_process_flip_death(delta)
		return
	if _is_dead:
		return

	velocity.y += config.gravity * delta
	velocity.x = direction * speed
	move_and_slide()

	if is_on_wall():
		direction = -direction


func stomp_kill() -> bool:
	# Override in subclass. Return true if the enemy was killed (award points).
	return false


func shell_kill() -> void:
	_kill_flip(false)


func non_stomp_kill() -> void:
	_kill_flip(true)


func _kill_flip(award_points: bool) -> void:
	if _is_dead:
		return
	_is_dead = true
	if award_points:
		GameManager.add_score(200, global_position)
	EventBus.enemy_killed.emit(global_position, _enemy_type)
	_start_flip_death()


func _start_flip_death() -> void:
	_flip_dying = true
	_disable_all_collision()
	_visuals.scale.y = -1
	velocity = Vector2(velocity.x * 0.5, -200.0)


func _disable_all_collision() -> void:
	collision_layer = 0
	collision_mask = 0
	_hitbox.set_deferred("monitoring", false)
	_hitbox.set_deferred("monitorable", false)


func _process_flip_death(delta: float) -> void:
	velocity.y += config.gravity * delta
	global_position += velocity * delta
	if global_position.y > 500.0:
		call_deferred("queue_free")


func die() -> void:
	# Called by KillZone
	if _is_dead:
		return
	_is_dead = true
	call_deferred("queue_free")
