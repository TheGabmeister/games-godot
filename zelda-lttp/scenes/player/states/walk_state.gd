extends BasePlayerState

var _safe_position_timer: float = 0.0
var _push_timer: float = 0.0
const SAFE_POSITION_INTERVAL := 0.5
const PUSH_DELAY := 0.25


func enter(msg: Dictionary = {}) -> void:
	super.enter(msg)
	_safe_position_timer = 0.0


func physics_update(delta: float) -> void:
	if is_gameplay_paused():
		return
	var input := get_movement_input()
	if input == Vector2.ZERO:
		state_machine.transition_to(&"Idle")
		return

	# Shield stance: lock facing, slow movement
	var holding_shield: bool = Input.is_action_pressed("action_shield")
	if not holding_shield:
		player.update_facing(input)
	player.move_input = input
	var move_speed: float = player.speed * (0.5 if holding_shield else 1.0)
	player.velocity = input * move_speed
	player.move_and_slide()

	# Push block detection: if we're pressing against something and not moving
	if player.get_slide_collision_count() > 0 and input != Vector2.ZERO:
		_push_timer += delta
		if _push_timer >= PUSH_DELAY:
			_try_push_block()
			_push_timer = 0.0
	else:
		_push_timer = 0.0

	# Check screen-edge transitions for overworld rooms
	_check_screen_edge()

	# Track safe position periodically
	_safe_position_timer += delta
	if _safe_position_timer >= SAFE_POSITION_INTERVAL:
		_safe_position_timer = 0.0
		if player.is_on_floor() or true:  # 2D: always grounded
			player.last_safe_position = player.global_position


func handle_input(event: InputEvent) -> void:
	if is_gameplay_paused():
		return
	if event.is_action_pressed("action_sword"):
		state_machine.transition_to(&"Attack")
	elif event.is_action_pressed("action_item"):
		state_machine.transition_to(&"ItemUse")
	elif event.is_action_pressed("interact"):
		(player as Player).try_interact()
	elif event.is_action_pressed("action_dash"):
		if PlayerState.has_upgrade(&"boots"):
			state_machine.transition_to(&"Dash")


func _try_push_block() -> void:
	for i in player.get_slide_collision_count():
		var collision := player.get_slide_collision(i)
		var collider := collision.get_collider()
		if collider is PushBlock:
			collider.try_push(player.facing_direction)
			return


func _check_screen_edge() -> void:
	if SceneManager._is_transitioning:
		return
	if not SceneManager.current_room_data:
		return
	# Only scroll for overworld rooms
	if SceneManager.current_room_data.room_type != &"overworld":
		return

	var pos := player.global_position
	var direction := &""
	var scroll_dir := Vector2.ZERO

	if pos.x < 0:
		direction = &"left"
		scroll_dir = Vector2.LEFT
	elif pos.x > SceneManager.SCREEN_WIDTH:
		direction = &"right"
		scroll_dir = Vector2.RIGHT
	elif pos.y < 0:
		direction = &"up"
		scroll_dir = Vector2.UP
	elif pos.y > SceneManager.SCREEN_HEIGHT:
		direction = &"down"
		scroll_dir = Vector2.DOWN

	if direction == &"":
		return

	var room := SceneManager.current_room
	if room and room.has_method("get_neighbor"):
		var neighbor_id: StringName = room.get_neighbor(direction)
		if neighbor_id != &"":
			SceneManager.scroll_to_room(neighbor_id, scroll_dir)
