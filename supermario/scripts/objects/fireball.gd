extends CharacterBody2D

const FramesBuilder := preload("res://scripts/visuals/sprite_frames_builder.gd")
const SHEET := preload("res://sprites/fireball_sheet.png")
const SPEED: float = 500.0
const GRAVITY: float = 1200.0
const BOUNCE_VELOCITY: float = -360.0
const MAX_FALL: float = 800.0

var _direction: float = 1.0
var _alive: bool = true

@onready var _hitbox: Area2D = $Hitbox
@onready var _sprite: AnimatedSprite2D = $Sprite


func _ready() -> void:
	_hitbox.area_entered.connect(_on_hitbox_area_entered)
	velocity = Vector2(_direction * SPEED, 0.0)
	_sprite.sprite_frames = FramesBuilder.build(SHEET, 4, {
		&"spin": {"frames": [0, 1, 2, 3], "fps": 12.0},
	})
	_sprite.play(&"spin")


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
