extends Node

const SAVE_PATH := "user://save_01.json"
const SAVE_VERSION := 1

signal save_completed(reason: StringName)
signal load_completed

var last_save_reason: StringName = &""
var override_save_path := ""


func build_payload() -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"progression": Progression.to_dict(),
	}


func has_save() -> bool:
	return FileAccess.file_exists(_get_save_path())


func delete_save() -> bool:
	if not has_save():
		return true

	return DirAccess.remove_absolute(ProjectSettings.globalize_path(_get_save_path())) == OK


func save_game(reason: StringName = &"manual") -> bool:
	var effective_save_path := _get_save_path()
	var file := FileAccess.open(effective_save_path, FileAccess.WRITE)
	if file == null:
		push_error("SaveManager failed to open '%s' for writing." % effective_save_path)
		return false

	file.store_string(JSON.stringify(build_payload(), "\t"))
	last_save_reason = reason
	save_completed.emit(reason)
	return true


func load_game() -> bool:
	if not has_save():
		return false

	var effective_save_path := _get_save_path()
	var file := FileAccess.open(effective_save_path, FileAccess.READ)
	if file == null:
		push_error("SaveManager failed to open '%s' for reading." % effective_save_path)
		return false

	var parsed_payload: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed_payload) != TYPE_DICTIONARY:
		push_error("SaveManager found invalid save data in '%s'." % effective_save_path)
		return false

	var payload: Dictionary = parsed_payload

	if int(payload.get("version", -1)) != SAVE_VERSION:
		push_error("SaveManager does not support save version %s." % payload.get("version", "unknown"))
		return false

	Progression.from_dict(payload.get("progression", {}))
	load_completed.emit()
	return true


func _get_save_path() -> String:
	return override_save_path if not override_save_path.is_empty() else SAVE_PATH
