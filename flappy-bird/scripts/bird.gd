extends CharacterBody2D

const GRAVITY: float = 980.0
const FLAP_VELOCITY: float = -330.0
const MAX_FALL_SPEED: float = 600.0
const ROTATION_SPEED: float = 4.0

var _started: bool = false


func _ready() -> void:
	GameManager.game_started.connect(_on_game_started)
	GameManager.game_over.connect(_on_game_over)


func _physics_process(delta: float) -> void:
	if GameManager.is_game_over:
		velocity.y += GRAVITY * delta
		velocity.y = minf(velocity.y, MAX_FALL_SPEED)
		move_and_slide()
		_update_rotation(delta)
		queue_redraw()
		return

	if not _started:
		position.y = 360.0 + sin(Time.get_ticks_msec() / 300.0) * 10.0
		queue_redraw()
		return

	if not GameManager.is_playing:
		return

	velocity.y += GRAVITY * delta
	velocity.y = minf(velocity.y, MAX_FALL_SPEED)

	if Input.is_action_just_pressed("flap"):
		velocity.y = FLAP_VELOCITY

	move_and_slide()
	_update_rotation(delta)
	queue_redraw()

	if get_slide_collision_count() > 0:
		GameManager.end_game()

	if position.y < -50 or position.y > 770:
		GameManager.end_game()


func _update_rotation(delta: float) -> void:
	var target_rotation: float
	if velocity.y < 0:
		target_rotation = deg_to_rad(-25.0)
	else:
		target_rotation = deg_to_rad(minf(velocity.y / MAX_FALL_SPEED * 90.0, 70.0))
	rotation = lerp(rotation, target_rotation, ROTATION_SPEED * delta)


func _draw() -> void:
	# Body (yellow circle)
	draw_circle(Vector2.ZERO, 15.0, Color(1.0, 0.843, 0.0))
	draw_arc(Vector2.ZERO, 15.0, 0.0, TAU, 32, Color(0.855, 0.647, 0.125), 2.0)

	# Wing
	var wing_offset := sin(Time.get_ticks_msec() / 100.0) * 3.0
	var wing_points := PackedVector2Array([
		Vector2(-5, 2 + wing_offset),
		Vector2(-14, 8 + wing_offset),
		Vector2(-5, 10 + wing_offset),
	])
	draw_colored_polygon(wing_points, Color(0.9, 0.75, 0.0))

	# Eye
	draw_circle(Vector2(6, -5), 5.0, Color.WHITE)
	draw_circle(Vector2(8, -5), 2.5, Color.BLACK)

	# Beak
	var beak_points := PackedVector2Array([
		Vector2(12, 0),
		Vector2(22, 3),
		Vector2(12, 6),
	])
	draw_colored_polygon(beak_points, Color(1.0, 0.549, 0.0))


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("flap") and not _started and not GameManager.is_game_over:
		GameManager.start_game()


func _on_game_started() -> void:
	_started = true
	position = Vector2(120, 360)
	velocity = Vector2.ZERO
	rotation = 0.0


func _on_game_over() -> void:
	pass
