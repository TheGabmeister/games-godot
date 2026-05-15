extends Node

var player: Player
var camera: Node2D
var current_room: Node2D
var transitioning: bool = false
var door_states: Dictionary[String, int] = {}

var _player_scene: PackedScene = preload("res://scenes/player.tscn")
var _hud_scene: PackedScene = preload("res://scenes/hud.tscn")
var _camera_scene: PackedScene = preload("res://scenes/camera.tscn")

const SCROLL_DURATION: float = 0.75
const FADE_DURATION: float = 0.3
const WALK_DURATION: float = 0.3
const WALK_DISTANCE: float = 48.0
const EXIT_DISTANCE: float = 48.0
const OVERLAY_Z: int = 50

const FACING_LEFT: int = 0
const FACING_RIGHT: int = 1
const FACING_UP: int = 2
const FACING_DOWN: int = 3

const HUD := preload("res://scripts/hud/hud.gd")


func _ready() -> void:
	_setup.call_deferred()


func _setup() -> void:
	current_room = get_tree().current_scene
	var markers := get_tree().get_nodes_in_group(GameConsts.GROUP_PLAYER_START)
	if markers.is_empty():
		return
	var marker: Marker2D = markers[0] as Marker2D

	player = _player_scene.instantiate()
	player.position = marker.position
	get_tree().root.add_child(player)

	var cam: Node2D = _camera_scene.instantiate() as Node2D
	cam.set(&"target", player)
	get_tree().root.add_child(cam)
	camera = cam

	var bounds: Variant = current_room.get(&"camera_bounds")
	if bounds is Rect2:
		camera.call(&"set_room_limits", bounds)

	var hud: HUD = _hud_scene.instantiate()
	hud.connect_to_player(player)
	get_tree().root.add_child(hud)


func start_transition(target_path: String, target_door_id: StringName, source_facing: int) -> void:
	if transitioning:
		return
	transitioning = true
	await _perform_transition(target_path, target_door_id, source_facing)
	transitioning = false


func _perform_transition(target_path: String, target_door_id: StringName, source_facing: int) -> void:
	var dir := _facing_to_vector(source_facing)
	var vp_size := Vector2(960, 720)
	var offset := dir * vp_size

	_set_player_input(false)

	# Auto-walk player into the doorway
	player.player_sprite.play(PlayerConsts.ANIM_WALK)
	if dir.x != 0.0:
		player.update_facing(dir.x)
	var walk_tween := create_tween()
	var _tw1 := walk_tween.tween_property(player, "global_position", player.global_position + dir * WALK_DISTANCE, WALK_DURATION)
	await walk_tween.finished

	# Fade room to black (overlay covers tiles; door z_index stays above)
	var old_overlay := _create_fade_overlay()
	current_room.add_child(old_overlay)
	var fade_out := create_tween()
	var _tw2 := fade_out.tween_property(old_overlay, "color:a", 1.0, FADE_DURATION)
	await fade_out.finished

	player.visible = false

	# Load new room offset in the scroll direction
	var target_scene := load(target_path) as PackedScene
	var new_room: Node2D = target_scene.instantiate()
	new_room.position = offset
	get_tree().root.add_child(new_room)

	var new_overlay := _create_fade_overlay()
	new_overlay.color.a = 1.0
	new_room.add_child(new_overlay)

	# Scroll camera from old room to new room
	camera.set(&"following", false)
	var cam2d := camera as Camera2D
	var screen_pos: Vector2 = cam2d.get_screen_center_position()
	cam2d.position_smoothing_enabled = false
	camera.call(&"clear_limits")
	camera.global_position = screen_pos
	var scroll_tween := create_tween()
	var _tw3 := scroll_tween.set_trans(Tween.TRANS_SINE)
	var _tw4 := scroll_tween.set_ease(Tween.EASE_IN_OUT)
	var _tw5 := scroll_tween.tween_property(camera, "global_position", screen_pos + offset, SCROLL_DURATION)
	await scroll_tween.finished

	# Swap rooms: free old, reposition new to origin
	current_room.queue_free()
	var room_offset := new_room.position
	new_room.position = Vector2.ZERO
	camera.global_position -= room_offset
	current_room = new_room

	# Place player at target door exit
	var target_door: Node2D = _find_door(target_door_id)
	if target_door:
		player.global_position = target_door.global_position + dir * EXIT_DISTANCE
		if dir.x != 0.0:
			player.update_facing(dir.x)

	# Apply new room camera limits
	var new_bounds: Variant = current_room.get(&"camera_bounds")
	if new_bounds is Rect2:
		camera.call(&"set_room_limits", new_bounds)
	camera.global_position = player.global_position
	(camera as Camera2D).position_smoothing_enabled = true
	(camera as Camera2D).reset_smoothing()
	camera.set(&"following", true)

	# Reveal player and fade new room in
	player.visible = true
	player.player_sprite.play(PlayerConsts.ANIM_WALK)
	var fade_in := create_tween()
	var _tw6 := fade_in.tween_property(new_overlay, "color:a", 0.0, FADE_DURATION)
	await fade_in.finished
	new_overlay.queue_free()

	# Close target door behind the player
	if target_door and target_door.has_method(&"close_door"):
		target_door.call(&"close_door")

	# Walk player a bit further into the room
	var enter_tween := create_tween()
	var _tw7 := enter_tween.tween_property(player, "global_position", player.global_position + dir * 32.0, WALK_DURATION)
	await enter_tween.finished

	# Reset player to idle
	player.velocity = Vector2.ZERO
	player.player_sprite.play(PlayerConsts.ANIM_IDLE)
	player.state_machine.transition_to(PlayerConsts.STATE_IDLE)
	_set_player_input(true)


func _facing_to_vector(f: int) -> Vector2:
	match f:
		FACING_LEFT: return Vector2.LEFT
		FACING_RIGHT: return Vector2.RIGHT
		FACING_UP: return Vector2.UP
		FACING_DOWN: return Vector2.DOWN
	return Vector2.ZERO


func _set_player_input(enabled: bool) -> void:
	player.set_physics_process(enabled)
	player.set_process_unhandled_input(enabled)


func _create_fade_overlay() -> ColorRect:
	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0)
	overlay.size = Vector2(960, 720)
	overlay.z_index = OVERLAY_Z
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return overlay


func _find_door(id: StringName) -> Node2D:
	for child: Node in current_room.get_children():
		if child.get(&"door_id") == id:
			return child as Node2D
	return null
