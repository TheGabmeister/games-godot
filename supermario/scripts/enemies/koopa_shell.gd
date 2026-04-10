extends CharacterBody2D

const GRAVITY := 900.0
const SHELL_SPEED := 300.0
const KICK_IMMUNITY := 0.15
const SHELL_COMBO_POINTS := [500, 800, 1000, 2000, 5000, 8000]

enum State { IDLE, MOVING }

var shell_state: State = State.IDLE
var direction: float = 0.0
var _is_active: bool = false
var _is_dead: bool = false
var _flip_dying: bool = false
var _combo_count: int = 0
var _kick_immune_timer: float = 0.0

@onready var _hitbox: Area2D = $Hitbox
@onready var _damage_area: Area2D = $DamageArea
@onready var _visuals: Node2D = $Visuals


func _ready() -> void:
	set_physics_process(false)
	visible = false
	add_to_group("enemies")
	_damage_area.area_entered.connect(_on_damage_area_entered)
	_damage_area.monitoring = false


func activate() -> void:
	if _is_active:
		return
	_is_active = true
	set_physics_process(true)
	visible = true


func is_active() -> bool:
	return _is_active


func is_dead() -> bool:
	return _is_dead


func is_dangerous() -> bool:
	return shell_state == State.MOVING and _kick_immune_timer <= 0.0


func try_kick(kick_direction: float) -> bool:
	if _is_dead or shell_state == State.MOVING:
		return false
	direction = kick_direction
	shell_state = State.MOVING
	_kick_immune_timer = KICK_IMMUNITY
	_combo_count = 0
	_hitbox.monitorable = false
	_damage_area.monitoring = true
	AudioManager.play_sfx(&"kick")
	return true


func stomp_kill() -> bool:
	if _is_dead:
		return false
	if shell_state == State.MOVING:
		# Freeze moving shell to idle
		shell_state = State.IDLE
		velocity.x = 0.0
		direction = 0.0
		_combo_count = 0
		_damage_area.monitoring = false
		AudioManager.play_sfx(&"stomp")
		return false  # No points for stopping a shell
	else:
		# Stomp idle shell → kick it away from player
		var players := get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			var kick_dir := signf(global_position.x - players[0].global_position.x)
			if kick_dir == 0.0:
				kick_dir = 1.0
			try_kick(kick_dir)
		return false  # No points for kicking


func shell_kill() -> void:
	# Killed by another moving shell
	if _is_dead:
		return
	_is_dead = true
	_flip_dying = true
	collision_layer = 0
	collision_mask = 0
	_hitbox.set_deferred("monitorable", false)
	_damage_area.monitoring = false
	_visuals.scale.y = -1
	velocity = Vector2(0.0, -200.0)


func non_stomp_kill() -> void:
	shell_kill()


func die() -> void:
	if _is_dead:
		return
	_is_dead = true
	call_deferred("queue_free")


func _physics_process(delta: float) -> void:
	if _flip_dying:
		velocity.y += GRAVITY * delta
		global_position += velocity * delta
		if global_position.y > 500.0:
			call_deferred("queue_free")
		return
	if _is_dead:
		return

	# Kick immunity countdown
	if _kick_immune_timer > 0.0:
		_kick_immune_timer -= delta
		if _kick_immune_timer <= 0.0:
			_hitbox.monitorable = true

	velocity.y += GRAVITY * delta

	match shell_state:
		State.IDLE:
			velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)
		State.MOVING:
			velocity.x = direction * SHELL_SPEED

	move_and_slide()

	if is_on_wall() and shell_state == State.MOVING:
		direction = -direction


func _on_damage_area_entered(area: Area2D) -> void:
	if shell_state != State.MOVING:
		return
	if area == _hitbox:
		return  # Self-detection
	var enemy = area.get_parent()
	if not is_instance_valid(enemy) or enemy == self:
		return
	if enemy.has_method("is_dead") and enemy.is_dead():
		return
	# Skip other moving shells
	if enemy.has_method("try_kick") and enemy.has_method("is_dangerous"):
		if enemy.is_dangerous():
			return
	# Kill the enemy
	if enemy.has_method("shell_kill"):
		enemy.shell_kill()
	elif enemy.has_method("non_stomp_kill"):
		enemy.non_stomp_kill()
	else:
		return
	_combo_count += 1
	_award_combo_points(enemy.global_position)
	EventBus.combo_stomp.emit(_combo_count, enemy.global_position)
	CameraEffects.shake(minf(1.5 + _combo_count * 0.5, 5.0), 0.1)


func _award_combo_points(pos: Vector2) -> void:
	if _combo_count <= SHELL_COMBO_POINTS.size():
		var points: int = SHELL_COMBO_POINTS[_combo_count - 1]
		GameManager.add_score(points, pos)
	else:
		# 1-UP
		GameManager.earn_one_up()
