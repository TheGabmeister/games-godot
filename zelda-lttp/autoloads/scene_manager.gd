extends Node

var current_room: Node = null
var current_room_data: RoomData = null
var current_screen_coords: Vector2i = Vector2i.ZERO
var room_registry: Dictionary = {}  # StringName -> String (room_id -> scene_path)

var _world_node: Node2D = null
var _player: CharacterBody2D = null
var _is_transitioning: bool = false


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
		_is_transitioning = false
		return

	var room_instance := scene.instantiate()
	if _world_node:
		_world_node.add_child(room_instance)
	current_room = room_instance

	# Read room data
	if room_instance.has_method("get_room_data"):
		current_room_data = room_instance.get_room_data()
	elif "room_data" in room_instance:
		current_room_data = room_instance.room_data

	if current_room_data:
		current_screen_coords = current_room_data.screen_coords
		# Update safe position if applicable
		if current_room_data.is_safe_respawn_point:
			GameManager.last_safe_room_id = current_room_data.room_id
		# Play music
		if current_room_data.music_track != &"":
			AudioManager.play_bgm(current_room_data.music_track)

	# Place player
	if _player:
		var entities_node := _find_entities_node(room_instance)
		if entities_node:
			entities_node.add_child(_player)
		else:
			room_instance.add_child(_player)

		# Find entry point marker
		var spawn_pos := _find_entry_point(room_instance, entry_point)
		_player.global_position = spawn_pos

		if current_room_data and current_room_data.is_safe_respawn_point:
			GameManager.last_safe_position = spawn_pos

		# Apply camera limits to room bounds
		_apply_camera_limits(room_instance)


func _apply_camera_limits(room: Node) -> void:
	if not _player or not _player.has_node("Camera2D"):
		return
	var cam: Camera2D = _player.get_node("Camera2D")

	# Use room's bounding rect: look for a Floor ColorRect or fall back to viewport size
	var room_size := Vector2(256, 224)
	var room_origin := Vector2.ZERO

	var floor_node := room.get_node_or_null("Floor")
	if floor_node is ColorRect:
		room_origin = floor_node.global_position
		room_size = floor_node.size

	cam.limit_left = int(room_origin.x)
	cam.limit_top = int(room_origin.y)
	cam.limit_right = int(room_origin.x + room_size.x)
	cam.limit_bottom = int(room_origin.y + room_size.y)


func _find_entities_node(room: Node) -> Node:
	var entities := room.get_node_or_null("Entities")
	if entities:
		return entities
	return null


func _find_entry_point(room: Node, entry_point: StringName) -> Vector2:
	var entry_points := room.get_node_or_null("EntryPoints")
	if entry_points and entry_point != &"":
		var marker := entry_points.get_node_or_null(String(entry_point))
		if marker is Marker2D:
			return marker.global_position

	# Fallback: PlayerSpawn marker
	if entry_points:
		var spawn := entry_points.get_node_or_null("PlayerSpawn")
		if spawn is Marker2D:
			return spawn.global_position

	# Last fallback: room center
	return room.global_position + Vector2(128, 112)
