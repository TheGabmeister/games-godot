@tool
extends RefCounted

const SELF_ADDON_PATH := "res://addons/gdscript_dependency_graph/"
const DEFAULT_SCAN_ROOT := "res://scripts"

var _class_name_pattern := RegEx.new()
var _path_dependency_pattern := RegEx.new()
var _word_pattern := RegEx.new()


func _init() -> void:
	_class_name_pattern.compile("(?m)^\\s*class_name\\s+([A-Za-z_][A-Za-z0-9_]*)")
	_path_dependency_pattern.compile("\\b(?:extends|preload|load)\\s*(?:\\(\\s*)?[\"'](res://[^\"']+\\.gd)[\"']")
	_word_pattern.compile("\\b[A-Za-z_][A-Za-z0-9_]*\\b")


func scan(root_path: String = DEFAULT_SCAN_ROOT) -> Dictionary:
	var scripts := _find_gd_scripts(root_path)
	var script_lookup := {}
	var comment_stripped := {}
	var fully_stripped := {}
	for path in scripts:
		script_lookup[path] = true
		var text := _read_text(path)
		comment_stripped[path] = _strip_line_comments(text)
		fully_stripped[path] = _strip_comments_and_strings(text)

	var class_to_path := _collect_class_names(scripts, fully_stripped)
	var edges := []
	var edge_keys := {}

	for source_path in scripts:
		_add_path_dependency_edges(source_path, comment_stripped[source_path], script_lookup, edges, edge_keys)
		_add_symbol_dependency_edges(source_path, fully_stripped[source_path], class_to_path, edges, edge_keys)

	return {
		"nodes": scripts,
		"edges": edges,
	}


func _find_gd_scripts(root_path: String) -> Array[String]:
	var found: Array[String] = []
	var pending: Array[String] = [root_path]

	while not pending.is_empty():
		var current: String = pending.pop_back()
		var dir := DirAccess.open(current)
		if dir == null:
			continue

		dir.list_dir_begin()
		var entry_name: String = dir.get_next()
		while entry_name != "":
			if entry_name.begins_with("."):
				entry_name = dir.get_next()
				continue

			var entry_path: String = current.path_join(entry_name)
			if dir.current_is_dir():
				if not entry_path.begins_with(SELF_ADDON_PATH):
					pending.append(entry_path)
			elif entry_path.ends_with(".gd") and not entry_path.begins_with(SELF_ADDON_PATH):
				found.append(entry_path)

			entry_name = dir.get_next()

		dir.list_dir_end()

	found.sort()
	return found


func _collect_class_names(scripts: Array[String], stripped_texts: Dictionary) -> Dictionary:
	var class_to_path := {}

	for path in scripts:
		var result := _class_name_pattern.search(stripped_texts[path])
		if result == null:
			continue

		var class_id := result.get_string(1)
		if class_id != "":
			class_to_path[class_id] = path

	return class_to_path


func _add_path_dependency_edges(
	source_path: String,
	comment_stripped_text: String,
	script_lookup: Dictionary,
	edges: Array,
	edge_keys: Dictionary
) -> void:
	for result in _path_dependency_pattern.search_all(comment_stripped_text):
		var target_path: String = result.get_string(1)
		if target_path == source_path or not script_lookup.has(target_path):
			continue

		_add_edge(source_path, target_path, "path", edges, edge_keys)


func _add_symbol_dependency_edges(
	source_path: String,
	fully_stripped_text: String,
	class_to_path: Dictionary,
	edges: Array,
	edge_keys: Dictionary
) -> void:
	for result in _word_pattern.search_all(fully_stripped_text):
		var word := result.get_string()
		if not class_to_path.has(word):
			continue

		var target_path: String = class_to_path[word]
		if target_path == source_path:
			continue

		_add_edge(source_path, target_path, "symbol", edges, edge_keys)


func _add_edge(
	source_path: String,
	target_path: String,
	kind: String,
	edges: Array,
	edge_keys: Dictionary
) -> void:
	var key: String = "%s -> %s" % [source_path, target_path]
	if edge_keys.has(key):
		return

	edge_keys[key] = true
	edges.append({
		"from": source_path,
		"to": target_path,
		"kind": kind,
	})


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""

	return file.get_as_text()


func _strip_line_comments(text: String) -> String:
	return _strip_source_text(text, true)


func _strip_comments_and_strings(text: String) -> String:
	return _strip_source_text(text, false)


func _strip_source_text(text: String, preserve_strings: bool) -> String:
	var output := PackedStringArray()
	var index := 0
	var in_string := false
	var string_quote := ""
	var in_line_comment := false

	while index < text.length():
		var character: String = text.substr(index, 1)

		if in_line_comment:
			if character == "\n":
				in_line_comment = false
				output.append(character)
			else:
				output.append(" ")
			index += 1
			continue

		if in_string:
			output.append(character if preserve_strings or character == "\n" else " ")
			if character == "\\":
				if index + 1 < text.length():
					var escaped_character := text.substr(index + 1, 1)
					output.append(escaped_character if preserve_strings or escaped_character == "\n" else " ")
					index += 2
				else:
					index += 1
				continue

			if character == string_quote:
				in_string = false
				string_quote = ""

			index += 1
			continue

		if character == "#":
			in_line_comment = true
			output.append(" ")
			index += 1
			continue

		if character == "\"" or character == "'":
			in_string = true
			string_quote = character
			output.append(character if preserve_strings else " ")
			index += 1
			continue

		output.append(character)
		index += 1

	return "".join(output)
