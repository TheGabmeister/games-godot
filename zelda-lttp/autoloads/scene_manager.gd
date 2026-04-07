extends Node

var current_room: Node = null
var current_room_data: RoomData = null
var current_screen_coords: Vector2i = Vector2i.ZERO
var room_registry: Dictionary = {}  # StringName -> String (room_id -> scene_path)
var _room_data_cache: Dictionary = {}  # StringName -> RoomData (room_id -> RoomData)

var _world_node: Node2D = null
var _player: CharacterBody2D = null
var _transition_overlay = null  # TransitionOverlay (CanvasLayer with script)
var _is_transitioning: bool = false

const SCROLL_DURATION := 0.5
const AUTO_WALK_DISTANCE := 24.0
const AUTO_WALK_SPEED := 60.0
const SCREEN_WIDTH := 256.0
const SCREEN_HEIGHT := 224.0
const COLOR_GRADE_TRANSITION := 0.3

# Color grading presets: preset_name -> {color_shift, saturation, brightness, contrast}
var _grading_presets: Dictionary = {
	&"overworld": {"color_shift": Vector3(0.02, 0.01, -0.01), "saturation": 1.05, "brightness": 1.02, "contrast": 1.0},
	&"forest": {"color_shift": Vector3(-0.02, 0.04, -0.02), "saturation": 1.0, "brightness": 0.98, "contrast": 1.05},
	&"mountain": {"color_shift": Vector3(-0.02, -0.01, 0.03), "saturation": 0.85, "brightness": 1.0, "contrast": 1.0},
	&"dungeon": {"color_shift": Vector3(-0.01, -0.01, 0.02), "saturation": 0.75, "brightness": 0.95, "contrast": 1.05},
	&"dark_world": {"color_shift": Vector3(0.05, -0.03, 0.08), "saturation": 0.8, "brightness": 0.9, "contrast": 1.1},
	&"boss": {"color_shift": Vector3(0.03, -0.02, -0.02), "saturation": 0.9, "brightness": 0.92, "contrast": 1.15},
	&"cave": {"color_shift": Vector3(-0.02, -0.01, 0.03), "saturation": 0.85, "brightness": 0.95, "contrast": 1.02},
	&"desert": {"color_shift": Vector3(0.04, 0.02, -0.03), "saturation": 0.9, "brightness": 1.05, "contrast": 1.05},
	&"village": {"color_shift": Vector3(0.01, 0.02, -0.01), "saturation": 1.1, "brightness": 1.0, "contrast": 1.0},
	&"graveyard": {"color_shift": Vector3(-0.03, -0.02, 0.02), "saturation": 0.7, "brightness": 0.88, "contrast": 1.1},
	&"lake": {"color_shift": Vector3(-0.01, 0.02, 0.04), "saturation": 1.0, "brightness": 1.0, "contrast": 1.0},
	&"field": {"color_shift": Vector3(0.01, 0.02, -0.01), "saturation": 1.05, "brightness": 1.03, "contrast": 1.0},
}

var _post_process_rect: ColorRect = null
var _grade_tween: Tween = null


func _ready() -> void:
	_build_room_registry()


func _build_room_registry() -> void:
	_scan_room_data("res://resources/room_data/")


func _scan_room_data(path: String) -> void:
	var dir := DirAccess.open(path)
	if not dir:
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		var full_path := path + file_name
		if dir.current_is_dir():
			_scan_room_data(full_path + "/")
		elif file_name.ends_with(".tres") or file_name.ends_with(".res"):
			var res := load(full_path)
			if res is RoomData:
				var rd: RoomData = res
				if rd.room_id != &"":
					room_registry[rd.room_id] = rd.scene_path
					_room_data_cache[rd.room_id] = rd
		file_name = dir.get_next()
	dir.list_dir_end()


func set_world_node(node: Node2D) -> void:
	_world_node = node


func set_player(player: CharacterBody2D) -> void:
	_player = player


func set_transition_overlay(overlay) -> void:
	_transition_overlay = overlay


func set_post_process_rect(rect: ColorRect) -> void:
	_post_process_rect = rect


# --- Standard room load (no transition animation) ---

func load_room(room_id: StringName, entry_point: StringName = &"") -> void:
	if _is_transitioning:
		return
	var scene_path: String = room_registry.get(room_id, "")
	if scene_path == "":
		push_error("[SceneManager] Unknown room_id: %s" % room_id)
		return
	_is_transitioning = true
	await _perform_room_load(scene_path, entry_point)
	_is_transitioning = false


func load_room_direct(scene_path: String, entry_point: StringName = &"") -> void:
	if _is_transitioning:
		return
	_is_transitioning = true
	await _perform_room_load(scene_path, entry_point)
	_is_transitioning = false


# --- Transition-aware room load ---

func load_room_with_transition(room_id: StringName, entry_point: StringName = &"", style: StringName = &"fade") -> void:
	if _is_transitioning:
		return
	var scene_path: String = room_registry.get(room_id, "")
	if scene_path == "":
		push_error("[SceneManager] Unknown room_id: %s" % room_id)
		return
	_is_transitioning = true
	_set_player_control(false)

	match style:
		&"iris":
			var player_screen_pos := _get_player_screen_position()
			await _transition_overlay.iris_out(player_screen_pos, 0.4)
			await _perform_room_load(scene_path, entry_point)
			var new_screen_pos := _get_player_screen_position()
			await _transition_overlay.iris_in(new_screen_pos, 0.4)
		&"instant":
			await _perform_room_load(scene_path, entry_point)
		_:  # fade
			await _transition_overlay.fade_out(0.3)
			await _perform_room_load(scene_path, entry_point)
			await _transition_overlay.fade_in(0.3)

	_set_player_control(true)
	_is_transitioning = false


# --- Screen-edge scroll transition (overworld) ---

func scroll_to_room(room_id: StringName, direction: Vector2) -> void:
	if _is_transitioning:
		return
	var scene_path: String = room_registry.get(room_id, "")
	if scene_path == "":
		push_error("[SceneManager] Unknown room_id for scroll: %s" % room_id)
		return
	_is_transitioning = true
	_set_player_control(false)

	# Load new room scene
	var scene: PackedScene = load(scene_path)
	if not scene:
		push_error("[SceneManager] Failed to load scene: %s" % scene_path)
		_set_player_control(true)
		_is_transitioning = false
		return

	var new_room := scene.instantiate()
	# Position new room adjacent to the current one
	var offset := direction * Vector2(SCREEN_WIDTH, SCREEN_HEIGHT)
	new_room.position = offset
	_world_node.add_child(new_room)

	# Detach player from old room's Entities and reparent to world temporarily
	if _player and _player.get_parent():
		var old_parent := _player.get_parent()
		var player_global_pos := _player.global_position
		old_parent.remove_child(_player)
		_world_node.add_child(_player)
		_player.global_position = player_global_pos

	# Detach camera from player so it holds still while rooms scroll past.
	# Make it top_level so it ignores parent transforms, then tween nothing —
	# it just sits at screen center (128, 112) as the world slides.
	var cam: Camera2D = _player.get_node_or_null("Camera2D") if _player else null
	var old_smoothing := false
	if cam:
		old_smoothing = cam.position_smoothing_enabled
		cam.position_smoothing_enabled = false
		cam.top_level = true
		cam.global_position = Vector2(SCREEN_WIDTH * 0.5, SCREEN_HEIGHT * 0.5)
		cam.limit_left = -100000
		cam.limit_top = -100000
		cam.limit_right = 100000
		cam.limit_bottom = 100000

	# Compute where the player should end up in the NEW room's local coordinates.
	var player_pos := _player.global_position
	var final_pos_in_new_room := Vector2.ZERO
	if direction == Vector2.RIGHT:
		final_pos_in_new_room = Vector2(AUTO_WALK_DISTANCE, player_pos.y)
	elif direction == Vector2.LEFT:
		final_pos_in_new_room = Vector2(SCREEN_WIDTH - AUTO_WALK_DISTANCE, player_pos.y)
	elif direction == Vector2.DOWN:
		final_pos_in_new_room = Vector2(player_pos.x, AUTO_WALK_DISTANCE)
	elif direction == Vector2.UP:
		final_pos_in_new_room = Vector2(player_pos.x, SCREEN_HEIGHT - AUTO_WALK_DISTANCE)

	# Tween: slide the world so the new room ends at the origin, walk the player into it.
	var player_target_local := final_pos_in_new_room + offset
	var scroll_offset := -offset
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(_world_node, "position", scroll_offset, SCROLL_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(_player, "position", player_target_local, SCROLL_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tween.finished

	# Remove old room
	var old_room := current_room
	if old_room:
		old_room.queue_free()

	# Reset world and new room to origin
	_world_node.position = Vector2.ZERO
	new_room.position = Vector2.ZERO

	# Reparent player into new room's Entities
	if _player.get_parent():
		_player.get_parent().remove_child(_player)
	var entities := new_room.get_node_or_null("Entities")
	if entities:
		entities.add_child(_player)
	else:
		new_room.add_child(_player)
	# Player is now a child of the new room (at origin), set final position directly
	_player.position = final_pos_in_new_room

	# Update current room state
	current_room = new_room
	_read_room_data(new_room)

	# Restore camera: re-attach to player, apply room limits
	if cam:
		cam.top_level = false
		cam.position = Vector2.ZERO
		cam.position_smoothing_enabled = old_smoothing
		_apply_camera_limits(new_room)

	_set_player_control(true)
	_is_transitioning = false


# --- World switching (Light/Dark) ---

func switch_world(target_world_type: StringName) -> void:
	if _is_transitioning or not current_room_data:
		return

	# Find the mirrored room: same screen_coords but different world_type
	var target_room_id := _find_mirror_room(current_room_data.screen_coords, target_world_type)
	if target_room_id == &"":
		push_warning("[SceneManager] No mirror room found for coords %s in world %s" % [current_room_data.screen_coords, target_world_type])
		return

	_is_transitioning = true
	_set_player_control(false)

	# Swirl/fade transition for world switch
	if _transition_overlay:
		await _transition_overlay.fade_out(0.5)

	var scene_path: String = room_registry.get(target_room_id, "")
	if scene_path != "":
		# Preserve player's relative position in the room
		var player_pos := _player.global_position if _player else Vector2(128, 112)
		await _perform_room_load(scene_path, &"")
		if _player:
			_player.global_position = player_pos

	if _transition_overlay:
		await _transition_overlay.fade_in(0.5)

	_set_player_control(true)
	_is_transitioning = false


func _find_mirror_room(coords: Vector2i, world_type: StringName) -> StringName:
	# Data-driven: scan cached RoomData for a room with matching coords, world_type, and room_type=overworld
	for room_id: StringName in _room_data_cache:
		var rd: RoomData = _room_data_cache[room_id]
		if rd.screen_coords == coords and rd.world_type == world_type and rd.room_type == &"overworld":
			return room_id
	return &""


# --- Internal ---

func _perform_room_load(scene_path: String, entry_point: StringName) -> void:
	# Remove old room
	if current_room:
		if _player and _player.get_parent():
			_player.get_parent().remove_child(_player)
		current_room.queue_free()
		current_room = null

	# Load new room
	var scene: PackedScene
	if ResourceLoader.exists(scene_path):
		scene = load(scene_path)
	else:
		push_error("[SceneManager] Scene not found: %s" % scene_path)
		return

	var room_instance := scene.instantiate()
	if _world_node:
		_world_node.add_child(room_instance)
	current_room = room_instance

	_read_room_data(room_instance)

	# Place player
	if _player:
		var entities_node := room_instance.get_node_or_null("Entities")
		if entities_node:
			entities_node.add_child(_player)
		else:
			room_instance.add_child(_player)

		var spawn_pos := _find_entry_point(room_instance, entry_point)
		_player.global_position = spawn_pos

		if current_room_data and current_room_data.is_safe_respawn_point:
			GameManager.last_safe_position = spawn_pos

		_apply_camera_limits(room_instance)


func _read_room_data(room_instance: Node) -> void:
	if room_instance.has_method("get_room_data"):
		current_room_data = room_instance.get_room_data()
	elif "room_data" in room_instance:
		current_room_data = room_instance.room_data

	if current_room_data:
		current_screen_coords = current_room_data.screen_coords
		if current_room_data.is_safe_respawn_point:
			GameManager.last_safe_room_id = current_room_data.room_id
		if current_room_data.music_track != &"":
			AudioManager.play_bgm(current_room_data.music_track)
		_apply_color_grading(current_room_data.color_grading_preset)
		_update_bunny_state()


func _apply_camera_limits(room: Node) -> void:
	if not _player or not _player.has_node("Camera2D"):
		return
	var cam: Camera2D = _player.get_node("Camera2D")

	var room_size := Vector2(SCREEN_WIDTH, SCREEN_HEIGHT)
	var room_origin := Vector2.ZERO

	var floor_node := room.get_node_or_null("Floor")
	if floor_node is ColorRect:
		room_origin = floor_node.global_position
		room_size = floor_node.size

	cam.limit_left = int(room_origin.x)
	cam.limit_top = int(room_origin.y)
	cam.limit_right = int(room_origin.x + room_size.x)
	cam.limit_bottom = int(room_origin.y + room_size.y)


func _find_entry_point(room: Node, entry_point: StringName) -> Vector2:
	var entry_points := room.get_node_or_null("EntryPoints")
	if entry_points and entry_point != &"":
		var marker := entry_points.get_node_or_null(String(entry_point))
		if marker is Marker2D:
			return marker.global_position

	if entry_points:
		var spawn := entry_points.get_node_or_null("PlayerSpawn")
		if spawn is Marker2D:
			return spawn.global_position

	return room.global_position + Vector2(128, 112)


func _get_player_screen_position() -> Vector2:
	if not _player:
		return Vector2(128, 112)
	# Convert player global position to screen position
	var viewport := get_viewport()
	if viewport and _player.has_node("Camera2D"):
		var cam: Camera2D = _player.get_node("Camera2D")
		var cam_pos := cam.get_screen_center_position()
		var viewport_size := viewport.get_visible_rect().size
		return _player.global_position - cam_pos + viewport_size * 0.5
	return Vector2(128, 112)


func _apply_color_grading(preset: StringName) -> void:
	if not _post_process_rect or not _post_process_rect.material:
		return
	var mat: ShaderMaterial = _post_process_rect.material as ShaderMaterial
	if not mat:
		return
	var data: Dictionary = _grading_presets.get(preset, _grading_presets.get(&"overworld", {}))
	if data.is_empty():
		return

	if _grade_tween and _grade_tween.is_valid():
		_grade_tween.kill()
	_grade_tween = create_tween()
	_grade_tween.set_parallel(true)
	_grade_tween.tween_method(
		func(v: Vector3) -> void: mat.set_shader_parameter("color_shift", v),
		mat.get_shader_parameter("color_shift") as Vector3,
		data["color_shift"] as Vector3,
		COLOR_GRADE_TRANSITION
	)
	_grade_tween.tween_method(
		func(v: float) -> void: mat.set_shader_parameter("saturation", v),
		mat.get_shader_parameter("saturation") as float,
		data["saturation"] as float,
		COLOR_GRADE_TRANSITION
	)
	_grade_tween.tween_method(
		func(v: float) -> void: mat.set_shader_parameter("brightness", v),
		mat.get_shader_parameter("brightness") as float,
		data["brightness"] as float,
		COLOR_GRADE_TRANSITION
	)
	_grade_tween.tween_method(
		func(v: float) -> void: mat.set_shader_parameter("contrast", v),
		mat.get_shader_parameter("contrast") as float,
		data["contrast"] as float,
		COLOR_GRADE_TRANSITION
	)


func _update_bunny_state() -> void:
	if not _player or not current_room_data:
		return
	if current_room_data.world_type == &"dark" and not PlayerState.has_upgrade(&"moon_pearl"):
		_player.is_bunny = true
	else:
		_player.is_bunny = false
	if _player.has_node("PlayerBody"):
		_player.get_node("PlayerBody").queue_redraw()


func _set_player_control(enabled: bool) -> void:
	if not _player:
		return
	if enabled:
		_player.set_process_unhandled_input(true)
		# Re-enable state machine processing
		var sm: Node = _player.get_node_or_null("StateMachine")
		if sm:
			sm.set_process(true)
			sm.set_physics_process(true)
			sm.set_process_unhandled_input(true)
	else:
		_player.set_process_unhandled_input(false)
		_player.velocity = Vector2.ZERO
		# Disable state machine so walk/idle states stop reading input and moving
		var sm: Node = _player.get_node_or_null("StateMachine")
		if sm:
			sm.set_process(false)
			sm.set_physics_process(false)
			sm.set_process_unhandled_input(false)
