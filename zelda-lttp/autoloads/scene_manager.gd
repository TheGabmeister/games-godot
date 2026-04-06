extends Node

var current_room: Node = null
var current_room_data: RoomData = null
var current_screen_coords: Vector2i = Vector2i.ZERO
var room_registry: Dictionary = {}  # StringName -> String (room_id -> scene_path)

var _world_node: Node2D = null
var _player: CharacterBody2D = null
var _transition_overlay = null  # TransitionOverlay (CanvasLayer with script)
var _is_transitioning: bool = false

const SCROLL_DURATION := 0.5
const AUTO_WALK_DISTANCE := 24.0
const AUTO_WALK_SPEED := 60.0
const SCREEN_WIDTH := 256.0
const SCREEN_HEIGHT := 224.0


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
		file_name = dir.get_next()
	dir.list_dir_end()


func set_world_node(node: Node2D) -> void:
	_world_node = node


func set_player(player: CharacterBody2D) -> void:
	_player = player


func set_transition_overlay(overlay) -> void:
	_transition_overlay = overlay


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

	# Disable camera smoothing during scroll and detach limits
	var cam: Camera2D = _player.get_node_or_null("Camera2D") if _player else null
	var old_smoothing := false
	if cam:
		old_smoothing = cam.position_smoothing_enabled
		cam.position_smoothing_enabled = false
		# Remove limits so camera can scroll freely
		cam.limit_left = -100000
		cam.limit_top = -100000
		cam.limit_right = 100000
		cam.limit_bottom = 100000

	# Scroll: tween the world node position so both rooms slide
	var scroll_offset := -offset
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(_world_node, "position", scroll_offset, SCROLL_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	# Auto-walk player a short distance into the new screen
	var player_target := _player.global_position + direction * AUTO_WALK_DISTANCE
	tween.tween_property(_player, "global_position", player_target, SCROLL_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tween.finished

	# Remove old room
	var old_room := current_room
	if old_room:
		old_room.queue_free()

	# Reset world position — shift new room to origin
	_world_node.position = Vector2.ZERO
	new_room.position = Vector2.ZERO
	# Adjust player position to compensate
	_player.global_position = _player.global_position + offset  # undo the world scroll effect

	# Actually: player's position relative to the new room is correct after scroll.
	# We need to recalculate: during scroll, world moved by scroll_offset, new_room was at +offset.
	# After reset: player needs to be at (player_target - offset + Vector2.ZERO) relative to new room origin
	# Simpler: the player ended at player_target in world-space where world.position = scroll_offset and new_room.position = offset.
	# Player's position relative to new_room = player_target - scroll_offset - offset = player_target
	# After reset (world at 0, new_room at 0): player should be at player_target - scroll_offset - offset + 0
	# Wait, let me think more carefully.
	# During scroll end state:
	#   world.position = scroll_offset = -offset
	#   new_room.position (local to world) = offset
	#   new_room global position = world.position + new_room.position = -offset + offset = 0
	#   player.global_position = player_target (player is child of world)
	#   player position relative to new_room's global = player_target - 0 = player_target
	# After reset:
	#   world.position = 0
	#   new_room.position = 0 (global = 0)
	#   player should be at player_target (since new_room is now at 0 same as before)
	# So player position stays the same! But player is a child of world, so:
	#   Before reset: player.global_position = world.position + player.position = -offset + player.position = player_target
	#     => player.position = player_target + offset
	#   After reset: world.position = 0, so player.global_position = player.position = player_target + offset
	#   But we want player.global_position = player_target
	# So we need to adjust:
	_player.global_position = player_target

	# Reparent player into new room's Entities
	if _player.get_parent():
		_player.get_parent().remove_child(_player)
	var entities := new_room.get_node_or_null("Entities")
	if entities:
		entities.add_child(_player)
	else:
		new_room.add_child(_player)
	_player.global_position = player_target

	# Update current room state
	current_room = new_room
	_read_room_data(new_room)

	# Restore camera
	if cam:
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
	# Scan all room data to find one with matching coords and world_type
	for room_id: StringName in room_registry:
		var path: String = room_registry[room_id]
		# We need to check the RoomData - load it from the resource folder
		# Use a cached lookup approach
		pass

	# Fallback: convention-based lookup
	# Light world: overworld_X_Y, Dark world: dark_overworld_X_Y
	var prefix := "dark_overworld" if world_type == &"dark" else "overworld"
	var target_id := StringName("%s_%d_%d" % [prefix, coords.x, coords.y])
	if room_registry.has(target_id):
		return target_id
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
		_player.set_physics_process(true)
	else:
		_player.set_process_unhandled_input(false)
		# Keep physics for visual updates but zero velocity
		_player.velocity = Vector2.ZERO
