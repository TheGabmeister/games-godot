extends Node
class_name DialogueController

const DIALOGUE_BOX_SCENE_PATH := "res://scenes/ui/DialogueBox.tscn"

signal sequence_started(sequence_id: StringName)
signal line_changed(sequence_id: StringName, line_index: int, line_count: int)
signal sequence_finished(sequence_id: StringName, was_skipped: bool)

var _active_sequence: Resource = null
var _active_box: Control = null
var _line_index := -1
var _runtime_shell: Node = null


func play_sequence(sequence: Resource, overlay_host: Node, runtime_shell: Node = null) -> Dictionary:
	if sequence == null or overlay_host == null:
		return {"completed": false, "skipped": false}

	var box_scene := load(DIALOGUE_BOX_SCENE_PATH) as PackedScene
	if box_scene == null:
		push_error("DialogueController failed to load DialogueBox.")
		return {"completed": false, "skipped": false}

	_runtime_shell = runtime_shell
	_active_sequence = sequence
	_active_box = box_scene.instantiate() as Control
	_line_index = 0

	if _runtime_shell != null and _runtime_shell.has_method("mount_overlay"):
		_runtime_shell.mount_overlay(_active_box)
	else:
		for child in overlay_host.get_children():
			child.queue_free()
		overlay_host.add_child(_active_box)

	sequence_started.emit(_get_sequence_id())
	_apply_current_line()

	while _active_sequence != null:
		await get_tree().process_frame
		if Input.is_action_just_pressed("menu_confirm"):
			if _line_index >= _get_line_count() - 1:
				return _finish_sequence(false)

			_line_index += 1
			_apply_current_line()
		elif Input.is_action_just_pressed("menu_cancel") and _is_skip_allowed():
			return _finish_sequence(true)

	return {"completed": true, "skipped": false}


func _apply_current_line() -> void:
	if _active_sequence == null or _active_box == null:
		return

	if _line_index < 0:
		return

	var lines_variant: Variant = _active_sequence.get("lines")
	var lines: Array = lines_variant if lines_variant is Array else []
	if _line_index >= lines.size():
		return

	var line: Resource = lines[_line_index] as Resource
	var speaker_id: Variant = line.get("speaker_id")
	var body_variant: Variant = line.get("body_text")
	var speaker_name := str(speaker_id if speaker_id != null else &"narrator").replace("_", " ").to_upper()
	var body_text := String(body_variant if body_variant != null else "")
	_active_box.call("configure_line", speaker_name, body_text, _line_index, lines.size(), _is_skip_allowed())
	line_changed.emit(_get_sequence_id(), _line_index, lines.size())


func _finish_sequence(was_skipped: bool) -> Dictionary:
	var sequence_id: StringName = _get_sequence_id()
	if _runtime_shell != null and _runtime_shell.has_method("clear_overlay"):
		_runtime_shell.clear_overlay()
	elif _active_box != null:
		_active_box.queue_free()

	_active_sequence = null
	_active_box = null
	_line_index = -1
	_runtime_shell = null
	sequence_finished.emit(sequence_id, was_skipped)
	return {"completed": true, "skipped": was_skipped}


func _get_sequence_id() -> StringName:
	if _active_sequence == null:
		return &""
	var sequence_id: Variant = _active_sequence.get("sequence_id")
	if sequence_id == null:
		return &""
	return sequence_id as StringName


func _get_line_count() -> int:
	if _active_sequence == null:
		return 0
	var lines_variant: Variant = _active_sequence.get("lines")
	return (lines_variant as Array).size() if lines_variant is Array else 0


func _is_skip_allowed() -> bool:
	if _active_sequence == null:
		return false
	var allow_skip: Variant = _active_sequence.get("allow_skip")
	return bool(allow_skip) if allow_skip != null else false
