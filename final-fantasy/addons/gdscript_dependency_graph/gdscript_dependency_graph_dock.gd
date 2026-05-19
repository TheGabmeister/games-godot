@tool
extends VBoxContainer

const DependencyGraphScanner := preload("res://addons/gdscript_dependency_graph/gdscript_dependency_graph_scanner.gd")
const DependencyGraphCanvas := preload("res://addons/gdscript_dependency_graph/gdscript_dependency_graph_canvas.gd")

const DEFAULT_SCAN_ROOT := "res://scripts"

var _graph_canvas: Control
var _status_label: Label
var _scan_folder_label: Label
var _folder_dialog: EditorFileDialog
var _scan_root_path := DEFAULT_SCAN_ROOT


func _ready() -> void:
	_build_ui()


func _build_ui() -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	custom_minimum_size = Vector2(0.0, 360.0)

	var toolbar := HBoxContainer.new()
	toolbar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(toolbar)

	var generate_button := Button.new()
	generate_button.text = "Generate Graph"
	generate_button.pressed.connect(_on_generate_graph_pressed)
	toolbar.add_child(generate_button)

	var reset_button := Button.new()
	reset_button.text = "Reset View"
	reset_button.pressed.connect(_on_reset_view_pressed)
	toolbar.add_child(reset_button)

	var choose_folder_button := Button.new()
	choose_folder_button.text = "Choose Folder"
	choose_folder_button.pressed.connect(_on_choose_folder_pressed)
	toolbar.add_child(choose_folder_button)

	_scan_folder_label = Label.new()
	_scan_folder_label.text = _scan_root_path
	_scan_folder_label.tooltip_text = _scan_root_path
	toolbar.add_child(_scan_folder_label)

	_status_label = Label.new()
	_status_label.text = "No graph generated. Drag nodes to move, Ctrl-click or box select, middle-drag to pan, wheel to zoom."
	_status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	toolbar.add_child(_status_label)

	var graph_viewport := Control.new()
	graph_viewport.clip_contents = true
	graph_viewport.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	graph_viewport.size_flags_vertical = Control.SIZE_EXPAND_FILL
	graph_viewport.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(graph_viewport)

	_graph_canvas = DependencyGraphCanvas.new()
	_graph_canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_graph_canvas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_graph_canvas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	graph_viewport.add_child(_graph_canvas)

	_folder_dialog = EditorFileDialog.new()
	_folder_dialog.title = "Choose Script Folder"
	_folder_dialog.file_mode = EditorFileDialog.FILE_MODE_OPEN_DIR
	_folder_dialog.access = EditorFileDialog.ACCESS_RESOURCES
	_folder_dialog.current_dir = _scan_root_path
	_folder_dialog.dir_selected.connect(_on_folder_selected)
	add_child(_folder_dialog)


func _on_generate_graph_pressed() -> void:
	_clear_graph()

	var scanner := DependencyGraphScanner.new()
	var graph_data := scanner.scan(_scan_root_path)
	var nodes: Array = graph_data["nodes"]
	var edges: Array = graph_data["edges"]

	if nodes.is_empty():
		_status_label.text = "No .gd files found in %s." % _scan_root_path
		return

	var display_names := _build_display_names(nodes)
	var depths := _compute_dependency_depths(nodes, edges)
	_graph_canvas.set_graph(nodes, edges, display_names, depths)

	_status_label.text = "%d scripts, %d dependencies in %s" % [nodes.size(), edges.size(), _scan_root_path]


func _on_reset_view_pressed() -> void:
	_graph_canvas.reset_view()


func _on_choose_folder_pressed() -> void:
	_folder_dialog.current_dir = _scan_root_path
	_folder_dialog.popup_centered_ratio(0.7)


func _on_folder_selected(path: String) -> void:
	_scan_root_path = path
	_scan_folder_label.text = _scan_root_path
	_scan_folder_label.tooltip_text = _scan_root_path
	_status_label.text = "Scan folder set to %s." % _scan_root_path


func _clear_graph() -> void:
	_graph_canvas.clear_graph()


func _build_display_names(paths: Array) -> Dictionary:
	var paths_by_file_name := {}

	for path in paths:
		var file_name: String = String(path).get_file()
		if not paths_by_file_name.has(file_name):
			paths_by_file_name[file_name] = []
		paths_by_file_name[file_name].append(path)

	var display_names := {}
	for path in paths:
		var file_name: String = String(path).get_file()
		if paths_by_file_name[file_name].size() == 1:
			display_names[path] = file_name
		else:
			display_names[path] = "%s/%s" % [String(path).get_base_dir().get_file(), file_name]

	return display_names


func _compute_dependency_depths(paths: Array, edges: Array) -> Dictionary:
	var dependents_by_path := {}
	for path in paths:
		dependents_by_path[path] = []

	for edge in edges:
		var source_path: String = edge["from"]
		var target_path: String = edge["to"]
		if dependents_by_path.has(target_path):
			dependents_by_path[target_path].append(source_path)

	var depths := {}
	for path in paths:
		depths[path] = _dependency_depth(path, dependents_by_path, {}, {})

	return depths


func _dependency_depth(
	path: String,
	dependents_by_path: Dictionary,
	visited: Dictionary,
	stack: Dictionary
) -> int:
	if visited.has(path):
		return visited[path]

	if stack.has(path):
		return 0

	stack[path] = true

	var max_parent_depth := -1
	for dependent_path in dependents_by_path.get(path, []):
		var dependent_depth := _dependency_depth(dependent_path, dependents_by_path, visited, stack)
		max_parent_depth = maxi(max_parent_depth, dependent_depth)

	stack.erase(path)

	var depth := max_parent_depth + 1
	visited[path] = depth
	return depth
