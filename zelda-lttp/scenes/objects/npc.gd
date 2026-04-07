class_name NPC extends Node2D
## Static or wandering NPC with dialog, optional flag gating, and optional reward.

@export var npc_name: String = "NPC"
@export var dialog_lines: Array[String] = []
@export var required_flag: StringName = &""
@export var reward_item: ItemData
@export var reward_flag: StringName = &""
@export var wander_enabled: bool = false
@export var wander_radius: float = 32.0
@export var npc_color: Color = Color(0.8, 0.6, 0.4)

enum WanderState { IDLE, WALKING }

var _wander_state: WanderState = WanderState.IDLE
var _wander_timer: float = 0.0
var _wander_target: Vector2 = Vector2.ZERO
var _spawn_position: Vector2 = Vector2.ZERO
var _move_speed: float = 15.0
var _visible_flag_met: bool = true


func _ready() -> void:
	_spawn_position = position

	# Check flag gating
	if required_flag != &"":
		_visible_flag_met = GameManager.get_flag(required_flag)
		visible = _visible_flag_met

	# Create interaction area
	var area := Area2D.new()
	area.name = "InteractArea"
	area.collision_layer = 32  # Interactables
	area.collision_mask = 0
	area.monitorable = true
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(16, 16)
	shape.shape = rect
	area.add_child(shape)
	add_child(area)

	# Create collision body so player can't walk through
	var body := StaticBody2D.new()
	body.collision_layer = 1  # World
	body.collision_mask = 0
	var body_shape := CollisionShape2D.new()
	var body_rect := RectangleShape2D.new()
	body_rect.size = Vector2(12, 12)
	body_shape.shape = body_rect
	body.add_child(body_shape)
	add_child(body)

	if wander_enabled:
		_wander_timer = randf_range(2.0, 4.0)

	queue_redraw()


func _process(delta: float) -> void:
	# Check flag visibility
	if required_flag != &"" and not _visible_flag_met:
		if GameManager.get_flag(required_flag):
			_visible_flag_met = true
			visible = true

	if not visible:
		return

	if wander_enabled:
		_update_wander(delta)


func _update_wander(delta: float) -> void:
	match _wander_state:
		WanderState.IDLE:
			_wander_timer -= delta
			if _wander_timer <= 0.0:
				_wander_target = _spawn_position + Vector2(
					randf_range(-wander_radius, wander_radius),
					randf_range(-wander_radius, wander_radius)
				)
				_wander_state = WanderState.WALKING
		WanderState.WALKING:
			var dir := (_wander_target - position).normalized()
			position += dir * _move_speed * delta
			if position.distance_to(_wander_target) < 2.0:
				position = _wander_target
				_wander_state = WanderState.IDLE
				_wander_timer = randf_range(2.0, 5.0)


func interact() -> void:
	if dialog_lines.is_empty():
		return
	EventBus.dialog_requested.emit(dialog_lines)

	# Give reward after dialog if applicable
	if reward_item and reward_flag != &"" and not GameManager.get_flag(reward_flag):
		_give_reward_after_dialog()


func _give_reward_after_dialog() -> void:
	await EventBus.dialog_closed
	GameManager.set_flag(reward_flag, true)
	EventBus.item_get_requested.emit(reward_item)


func _draw() -> void:
	# Simple humanoid shape: circle head + rectangle body
	# Body
	draw_rect(Rect2(-4, -2, 8, 12), npc_color)
	# Head
	draw_circle(Vector2(0, -5), 4.0, npc_color.lightened(0.15))
	# Eyes
	draw_circle(Vector2(-1.5, -6), 0.8, Color(0.1, 0.1, 0.1))
	draw_circle(Vector2(1.5, -6), 0.8, Color(0.1, 0.1, 0.1))


func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()
	if dialog_lines.is_empty():
		warnings.append("dialog_lines is empty — NPC has nothing to say.")
	return warnings
