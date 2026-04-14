extends Node

const SAVE_PATH := "user://save_01.json"
const SAVE_VERSION := 1


func build_payload() -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"progression": Progression.to_dict(),
	}


func save_game() -> bool:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("SaveManager failed to open '%s' for writing." % SAVE_PATH)
		return false

	file.store_string(JSON.stringify(build_payload(), "\t"))
	return true


func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_error("SaveManager failed to open '%s' for reading." % SAVE_PATH)
		return false

	var parsed_payload: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed_payload) != TYPE_DICTIONARY:
		push_error("SaveManager found invalid save data in '%s'." % SAVE_PATH)
		return false

	var payload: Dictionary = parsed_payload

	if int(payload.get("version", -1)) != SAVE_VERSION:
		push_error("SaveManager does not support save version %s." % payload.get("version", "unknown"))
		return false

	Progression.from_dict(payload.get("progression", {}))
	return true
