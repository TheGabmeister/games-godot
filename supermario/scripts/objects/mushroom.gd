extends CharacterBody2D

const P := preload("res://scripts/color_palette.gd")

const SPEED := 60.0
const GRAVITY := 600.0
const EMERGE_HEIGHT := 16.0
const EMERGE_DURATION := 0.4

var _direction: float = 1.0
var _emerging: bool = true
var _emerge_initialized: bool = false
var _emerge_start_y: float = 0.0
var _emerge_timer: float = 0.0
var _collected: bool = false

@onready var hurtbox: Area2D = $Hurtbox
@onready var drawer: Node2D = $Drawer


func _ready() -> void:
	# _emerge_start_y is captured lazily on the first physics tick, not
	# here. _ready() fires synchronously inside the spawner's add_child(),
	# BEFORE the spawner sets global_position. See fire_flower.gd for the
	# full write-up.
	# Disable physics collision during emergence
	set_collision_layer_value(1, false)
	set_collision_mask_value(1, false)
	hurtbox.body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	if _collected:
		return

	if _emerging:
		if not _emerge_initialized:
			_emerge_start_y = global_position.y
			_emerge_initialized = true
		_emerge_timer += delta
		var t: float = minf(_emerge_timer / EMERGE_DURATION, 1.0)
		global_position.y = _emerge_start_y - EMERGE_HEIGHT * t
		if t >= 1.0:
			_emerging = false
			# Re-enable physics collision with terrain
			collision_mask = 1
		return

	velocity.y += GRAVITY * delta
	velocity.x = _direction * SPEED
	move_and_slide()

	# Reverse on wall
	if is_on_wall():
		_direction = -_direction


func _on_body_entered(body: Node) -> void:
	if _collected:
		return
	if body.has_method("power_up"):
		_collected = true
		body.power_up(&"mushroom", global_position)
		queue_free()
