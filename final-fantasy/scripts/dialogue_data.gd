extends Node

var _cache: Dictionary = {}

func load_file(path: String) -> Dictionary:
	if path in _cache:
		return _cache[path]
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		push_error("Failed to load dialogue file: %s" % path)
		return {}
	var json := JSON.new()
	json.parse(file.get_as_text())
	var data: Dictionary = json.data
	_cache[path] = data
	return data

func get_dialogue(path: String, dialogue_id: String) -> Dictionary:
	var data := load_file(path)
	if dialogue_id in data:
		return data[dialogue_id]
	push_error("Dialogue ID '%s' not found in %s" % [dialogue_id, path])
	return {"name": "???", "lines": ["..."]}
