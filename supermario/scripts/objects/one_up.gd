extends CharacterBody2D

const EmergeHelper := preload("res://scripts/objects/emerge_helper.gd")
const OneUpSound := preload("res://audio/sfx/1up.wav")

@export var item_config: Resource  # ItemConfig

var _direction: float = 1.0
var _emerge := EmergeHelper.new()
var _collected: bool = false

@onready var hurtbox: Area2D = $Hurtbox
@onready var _sprite: AnimatedSprite2D = $Sprite


func _ready() -> void:
	set_collision_layer_value(1, false)
	set_collision_mask_value(1, false)
	hurtbox.body_entered.connect(_on_body_entered)
	_sprite.play(&"1up")


func _physics_process(delta: float) -> void:
	if _collected:
		return

	if not _emerge.done:
		global_position.y = _emerge.update(delta, global_position.y, item_config.emerge_duration, item_config.emerge_height)
		if _emerge.done:
			collision_mask = 1
		return

	velocity.y += item_config.mushroom_gravity * delta
	velocity.x = _direction * item_config.mushroom_speed
	move_and_slide()

	if is_on_wall():
		_direction = -_direction


func _on_body_entered(body: Node) -> void:
	if _collected:
		return
	if body.is_in_group("player"):
		_collected = true
		GameManager.earn_one_up()
		_play_sound(OneUpSound)
		queue_free()


func _play_sound(sound: AudioStream) -> void:
	if sound != null:
		EventBus.sfx_requested.emit(sound)
