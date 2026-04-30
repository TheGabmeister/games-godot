extends CharacterBody2D

const EmergeHelper := preload("res://scripts/objects/emerge_helper.gd")

@export var item_config: Resource  # ItemConfig

var _direction: float = 1.0
var _emerge := EmergeHelper.new()
var _collected: bool = false
var _bounce_velocity: float = -250.0

@onready var hurtbox: Area2D = $Hurtbox
@onready var _sprite: AnimatedSprite2D = $Sprite


func _ready() -> void:
	set_collision_layer_value(1, false)
	set_collision_mask_value(1, false)
	hurtbox.body_entered.connect(_on_body_entered)
	_sprite.play(&"cycle")


func _physics_process(delta: float) -> void:
	if _collected:
		return

	if not _emerge.done:
		global_position.y = _emerge.update(delta, global_position.y, item_config.emerge_duration, item_config.emerge_height)
		if _emerge.done:
			collision_mask = 1
			velocity.y = _bounce_velocity
		return

	velocity.y += item_config.mushroom_gravity * delta
	velocity.x = _direction * item_config.mushroom_speed
	move_and_slide()

	if is_on_floor():
		velocity.y = _bounce_velocity

	if is_on_wall():
		_direction = -_direction


func _on_body_entered(body: Node) -> void:
	if _collected:
		return
	if body.has_method("power_up"):
		_collected = true
		body.power_up(&"starman", global_position)
		queue_free()
