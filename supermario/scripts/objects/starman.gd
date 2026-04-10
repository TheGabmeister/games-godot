extends CharacterBody2D

const P := preload("res://scripts/color_palette.gd")
const EmergeHelper := preload("res://scripts/objects/emerge_helper.gd")

@export var item_config: Resource  # ItemConfig

var _direction: float = 1.0
var _emerge := EmergeHelper.new()
var _collected: bool = false
var _bounce_velocity: float = -250.0

@onready var hurtbox: Area2D = $Hurtbox

var _anim_time: float = 0.0


func _ready() -> void:
	set_collision_layer_value(1, false)
	set_collision_mask_value(1, false)
	hurtbox.body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	if _collected:
		return

	_anim_time += delta

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

	queue_redraw()


func _on_body_entered(body: Node) -> void:
	if _collected:
		return
	if body.has_method("power_up"):
		_collected = true
		body.power_up(&"starman", global_position)
		queue_free()


func _draw() -> void:
	# Star shape: 5-pointed star
	var cycle := int(_anim_time * 6.0) % 3
	var color: Color
	match cycle:
		0: color = P.STAR_YELLOW
		1: color = P.FIRE_ORANGE
		_: color = Color(0.6, 0.9, 0.3)

	# Draw a simple 5-pointed star shape
	var center := Vector2(0, -8)
	var points: PackedVector2Array = []
	for i in 10:
		var angle: float = (float(i) / 10.0) * TAU - PI * 0.5
		var r: float = 7.0 if i % 2 == 0 else 3.0
		points.append(center + Vector2(cos(angle) * r, sin(angle) * r))
	draw_colored_polygon(points, color)
	# Eye spots
	draw_circle(center + Vector2(-2, 0), 1.0, Color.BLACK)
	draw_circle(center + Vector2(2, 0), 1.0, Color.BLACK)
