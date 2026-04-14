extends Node
class_name CutsceneDirector

const DIALOGUE_CONTROLLER_SCRIPT = preload("res://scripts/systems/dialogue_controller.gd")

signal cutscene_started(cutscene_id: StringName)
signal action_started(cutscene_id: StringName, action_type: StringName)
signal cutscene_finished(cutscene_id: StringName, was_skipped: bool)

@export var fallback_overlay_host_path: NodePath

var _dialogue_controller: Node
var _active_cutscene_id: StringName = &""


func _ready() -> void:
	_dialogue_controller = DIALOGUE_CONTROLLER_SCRIPT.new()
	add_child(_dialogue_controller)


func is_active() -> bool:
	return not _active_cutscene_id.is_empty()


func get_active_cutscene_id() -> StringName:
	return _active_cutscene_id


func play_cutscene(cutscene_id: StringName, actions: Array, context: Dictionary = {}) -> Dictionary:
	if cutscene_id.is_empty() or is_active():
		return {"completed": false, "skipped": false}

	_active_cutscene_id = cutscene_id
	cutscene_started.emit(_active_cutscene_id)

	var was_skipped := false
	for action_variant in actions:
		if typeof(action_variant) != TYPE_DICTIONARY:
			push_warning("CutsceneDirector ignored a non-dictionary action in cutscene '%s'." % cutscene_id)
			continue

		var action := action_variant as Dictionary
		var action_type := action.get("type", &"") as StringName
		action_started.emit(_active_cutscene_id, action_type)
		var action_result := await _execute_action(action, context)
		was_skipped = was_skipped or bool(action_result.get("skipped", false))

	_active_cutscene_id = &""
	cutscene_finished.emit(cutscene_id, was_skipped)
	return {"completed": true, "skipped": was_skipped}


func _execute_action(action: Dictionary, context: Dictionary) -> Dictionary:
	match action.get("type", &"") as StringName:
		&"wait":
			await _await_frames(int(action.get("frames", 1)))
		&"camera_pan_to_marker":
			var marker := _resolve_node2d(action.get("marker", null))
			var camera := _resolve_camera(context)
			if camera != null and marker != null and camera.has_method("set_target"):
				camera.set_target(marker)
			await _await_frames(int(action.get("wait_frames", 1)))
		&"camera_follow_player":
			var camera := _resolve_camera(context)
			var player := context.get("player", null) as Node
			if camera != null and player != null and player.has_method("get_camera_anchor"):
				camera.set_target(player.get_camera_anchor())
			await _await_frames(int(action.get("wait_frames", 1)))
		&"emit_audio_event":
			var audio_manager := get_node_or_null("/root/AudioManager")
			if audio_manager != null and audio_manager.has_method("play_sfx"):
				audio_manager.play_sfx(action.get("event_id", &"") as StringName)
		&"show_text":
			var overlay_host := _resolve_overlay_host()
			if overlay_host == null:
				push_error("CutsceneDirector could not resolve an overlay host for dialogue.")
				return {"completed": false, "skipped": false}
			return await _dialogue_controller.play_sequence(
				action.get("sequence", null) as Resource,
				overlay_host,
				_resolve_runtime_shell()
			)
		&"unlock_dash":
			var pickup_id := action.get("pickup_id", &"") as StringName
			var changed := Progression.grant_dash_unlock(pickup_id)
			var player := context.get("player", null) as Node
			if player != null and player.has_method("set_dash_unlocked"):
				player.set_dash_unlocked(true)
			var capsule := action.get("capsule", null) as Node
			if capsule != null and capsule.has_method("mark_collected"):
				capsule.mark_collected()
			var save_manager := get_node_or_null("/root/SaveManager")
			if changed and save_manager != null and save_manager.has_method("save_game"):
				save_manager.save_game(&"persistent_pickup")
		_:
			push_warning("CutsceneDirector ignored unknown action type '%s'." % action.get("type", ""))

	return {"completed": true, "skipped": false}


func _resolve_runtime_shell() -> Node:
	return get_tree().root.get_node_or_null("Main")


func _resolve_overlay_host() -> Node:
	var runtime_shell := _resolve_runtime_shell()
	if runtime_shell != null and runtime_shell.has_method("get_overlay_root"):
		return runtime_shell.get_overlay_root()

	if fallback_overlay_host_path.is_empty():
		return null

	return get_node_or_null(fallback_overlay_host_path)


func _resolve_camera(context: Dictionary) -> Camera2D:
	return context.get("camera", null) as Camera2D


func _resolve_node2d(value: Variant) -> Node2D:
	if value is Node2D:
		return value
	if value is NodePath:
		return get_node_or_null(value) as Node2D
	return null


func _await_frames(frame_count: int) -> void:
	for _frame in range(maxi(1, frame_count)):
		await get_tree().process_frame
