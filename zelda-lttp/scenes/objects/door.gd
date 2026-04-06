class_name Door extends Area2D
## Transition trigger for interior/cave/dungeon entrances.
## Can be walk-in (step on trigger) or interact (press button while overlapping).

enum TriggerMode { WALK_IN, INTERACT }

@export var target_room_id: StringName = &""
@export var target_entry_point: StringName = &""
@export var transition_style: StringName = &"fade"  # fade, iris, instant
@export var trigger_mode: TriggerMode = TriggerMode.WALK_IN
@export var door_width: float = 16.0
@export var door_height: float = 16.0

var _triggered: bool = false


func _ready() -> void:
	collision_layer = 128  # Triggers layer
	collision_mask = 2  # Player layer
	monitoring = true
	monitorable = false

	# Create collision shape if none exists
	if get_child_count() == 0 or not _has_collision_shape():
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2(door_width, door_height)
		shape.shape = rect
		add_child(shape)

	body_entered.connect(_on_body_entered)


func _has_collision_shape() -> bool:
	for child in get_children():
		if child is CollisionShape2D:
			return true
	return false


func _on_body_entered(body: Node2D) -> void:
	if _triggered:
		return
	if not body is CharacterBody2D:
		return
	# Check this is the player
	if body.collision_layer & 2 == 0:
		return

	if trigger_mode == TriggerMode.WALK_IN:
		_trigger_transition(body)


func interact() -> void:
	if _triggered:
		return
	if trigger_mode == TriggerMode.INTERACT:
		# Find the player
		var bodies := get_overlapping_bodies()
		for body in bodies:
			if body is CharacterBody2D and body.collision_layer & 2:
				_trigger_transition(body)
				return


func _trigger_transition(body: Node2D) -> void:
	_triggered = true
	# Pass transition style to the player as metadata so main.gd can read it
	if body.has_method("set_meta"):
		body.set_meta("transition_style", transition_style)
	EventBus.room_transition_requested.emit(target_room_id, target_entry_point)
	# Reset after a delay to allow re-entry if transition is cancelled
	await get_tree().create_timer(1.0).timeout
	_triggered = false


func _draw() -> void:
	# Draw a dark doorway shape
	var door_color := Color(0.15, 0.1, 0.08)
	var frame_color := Color(0.4, 0.3, 0.2)
	var hw := door_width * 0.5
	var hh := door_height * 0.5

	# Door frame
	draw_rect(Rect2(-hw - 2, -hh - 2, door_width + 4, door_height + 4), frame_color)
	# Door interior (dark)
	draw_rect(Rect2(-hw, -hh, door_width, door_height), door_color)
	# Archway top
	draw_arc(Vector2(0, -hh), hw, 0, PI, 8, frame_color, 2.0)
