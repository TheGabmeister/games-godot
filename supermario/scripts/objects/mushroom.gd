extends CharacterBody2D

const SpriteHelper := preload("res://scripts/visuals/sprite_region_helper.gd")
const EmergeHelper := preload("res://scripts/objects/emerge_helper.gd")
const SHEET_COLUMNS := 5
const SPRITE_OFFSET := Vector2(-16, -30)

@export var item_config: Resource  # ItemConfig

var _direction: float = 1.0
var _emerge := EmergeHelper.new()
var _collected: bool = false
var _is_one_up: bool = false

@onready var hurtbox: Area2D = $Hurtbox
@onready var _sprite: Sprite2D = $Sprite


func _ready() -> void:
	# Emerge start position is captured lazily by EmergeHelper on the first
	# physics tick. _ready() fires synchronously inside the spawner's
	# add_child(), BEFORE the spawner sets global_position.
	set_collision_layer_value(1, false)
	set_collision_mask_value(1, false)
	hurtbox.body_entered.connect(_on_body_entered)


func set_one_up(value: bool) -> void:
	_is_one_up = value
	SpriteHelper.set_cell(_sprite, 1 if _is_one_up else 0, SHEET_COLUMNS, SPRITE_OFFSET)


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
	if body.has_method("power_up"):
		_collected = true
		body.power_up(&"mushroom", global_position)
		queue_free()
