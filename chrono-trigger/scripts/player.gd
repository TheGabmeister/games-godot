extends CharacterBody2D

const SPEED := 150.0
const RAY_LENGTH := 20.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var interact_ray: RayCast2D = $InteractRay

var facing := Vector2.DOWN

func _ready() -> void:
	_play_idle_animation()

func _physics_process(_delta: float) -> void:
	if GameState.current != GameState.State.FIELD:
		velocity = Vector2.ZERO
		return

	var input := Vector2.ZERO
	input.x = Input.get_axis("move_left", "move_right")
	input.y = Input.get_axis("move_up", "move_down")
	input = input.normalized()

	velocity = input * SPEED

	if input != Vector2.ZERO:
		facing = input.snapped(Vector2.ONE).normalized()
		interact_ray.target_position = facing * RAY_LENGTH
		_play_walk_animation()
	else:
		_play_idle_animation()

	move_and_slide()

	if Input.is_action_just_pressed("interact"):
		_try_interact()

func _play_walk_animation() -> void:
	var anim := _direction_name()
	animated_sprite.play("walk_" + anim)

func _play_idle_animation() -> void:
	var anim := _direction_name()
	animated_sprite.play("idle_" + anim)

func _direction_name() -> String:
	if abs(facing.x) > abs(facing.y):
		return "right" if facing.x > 0 else "left"
	else:
		return "down" if facing.y > 0 else "up"

func get_facing_direction_name() -> String:
	return _direction_name()

func _try_interact() -> void:
	if not interact_ray.is_colliding():
		return
	var collider := interact_ray.get_collider()
	if collider and collider.is_in_group("interactable"):
		collider.interact()
