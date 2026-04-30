extends CharacterBody2D

const SPEED: float = 500.0
const GRAVITY: float = 1200.0
const BOUNCE_VELOCITY: float = -360.0
const MAX_FALL: float = 800.0

var _direction: float = 1.0
var _alive: bool = true

@onready var _hitbox: Area2D = $Hitbox


func _ready() -> void:
	_hitbox.area_entered.connect(_on_hitbox_area_entered)
	velocity = Vector2(_direction * SPEED, 0.0)


func _physics_process(delta: float) -> void:
	if not _alive:
		return

	velocity.y = minf(velocity.y + GRAVITY * delta, MAX_FALL)
	velocity.x = _direction * SPEED
	move_and_slide()

	if is_on_wall():
		_die()
		return

	if is_on_floor():
		velocity.y = BOUNCE_VELOCITY

	# Off-screen cleanup
	if global_position.y > 600.0 or global_position.x < -64.0:
		queue_free()


func setup(dir: float) -> void:
	_direction = dir


func _on_hitbox_area_entered(area: Area2D) -> void:
	if not _alive:
		return
	var enemy := area.get_parent()
	if not is_instance_valid(enemy):
		return
	if enemy.has_method("is_dead") and enemy.is_dead():
		return
	if enemy.has_method("non_stomp_kill"):
		enemy.non_stomp_kill()
	elif enemy.has_method("shell_kill"):
		enemy.shell_kill()
	_die()


func _die() -> void:
	_alive = false
	queue_free()


func _draw() -> void:
	# Small fireball: 8x8 circle with orange/red
	draw_circle(Vector2(0, -4), 4.0, Palette.FIRE_ORANGE)
	draw_circle(Vector2(0, -4), 2.0, Palette.FIRE_RED)
