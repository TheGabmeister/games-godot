@tool
extends Control

const NODE_MIN_SIZE := Vector2(176.0, 48.0)
const COLUMN_SPACING := 240.0
const ROW_SPACING := 110.0
const MARGIN := Vector2(48.0, 48.0)
const ARROW_SIZE := 12.0
const ARROW_LINE_WIDTH := 1.5
const NODE_CONTENT_PADDING := 10.0
const NODE_CONTENT_SPACING := 8.0
const CROSSING_REDUCTION_SWEEPS := 6
const MIN_ZOOM := 0.25
const MAX_ZOOM := 3.0

var _nodes: Array = []
var _edges: Array = []
var _display_names := {}
var _depths := {}
var _node_rects := {}
var _graph_bounds := Rect2(Vector2.ZERO, Vector2.ZERO)
var _pan_offset := Vector2.ZERO
var _zoom := 1.0
var _is_panning := false
var _dragged_node_path := ""
var _selected_node_paths := {}
var _drag_start_node_positions := {}
var _node_drag_offset := Vector2.ZERO
var _box_selecting := false
var _box_select_start := Vector2.ZERO
var _box_select_end := Vector2.ZERO
var _last_mouse_position := Vector2.ZERO


func _ready() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_STOP


func set_graph(nodes: Array, edges: Array, display_names: Dictionary, depths: Dictionary) -> void:
	_nodes = nodes.duplicate()
	_edges = edges.duplicate()
	_display_names = display_names.duplicate()
	_depths = depths.duplicate()
	_rebuild_layout()
	reset_view()
	queue_redraw()


func clear_graph() -> void:
	_nodes.clear()
	_edges.clear()
	_display_names.clear()
	_depths.clear()
	_node_rects.clear()
	_graph_bounds = Rect2(Vector2.ZERO, Vector2.ZERO)
	_pan_offset = Vector2.ZERO
	_zoom = 1.0
	_is_panning = false
	_dragged_node_path = ""
	_selected_node_paths.clear()
	_drag_start_node_positions.clear()
	_box_selecting = false
	queue_redraw()


func reset_view() -> void:
	if _graph_bounds.size == Vector2.ZERO or size == Vector2.ZERO:
		_pan_offset = Vector2.ZERO
		_zoom = 1.0
		queue_redraw()
		return

	var padded_size := _graph_bounds.size + MARGIN * 2.0
	var zoom_x := size.x / maxf(padded_size.x, 1.0)
	var zoom_y := size.y / maxf(padded_size.y, 1.0)
	_zoom = clampf(minf(minf(zoom_x, zoom_y), 1.0), MIN_ZOOM, MAX_ZOOM)

	var graph_center := _graph_bounds.get_center()
	var screen_center := size * 0.5
	_pan_offset = screen_center - graph_center * _zoom
	queue_redraw()


func _rebuild_layout() -> void:
	_node_rects.clear()

	var node_sizes := {}
	var paths_by_row := {}
	var row_widths := {}
	var row_heights := {}

	for path in _nodes:
		var row: int = _depths.get(path, 0)
		if not paths_by_row.has(row):
			paths_by_row[row] = []
			row_widths[row] = 0.0
			row_heights[row] = 0.0

		var node_size := _measure_node_size(path)
		node_sizes[path] = node_size
		paths_by_row[row].append(path)
		row_widths[row] += node_size.x
		row_heights[row] = maxf(row_heights[row], node_size.y)

	if paths_by_row.is_empty():
		_graph_bounds = Rect2(Vector2.ZERO, Vector2.ZERO)
		return

	var sorted_rows := paths_by_row.keys()
	sorted_rows.sort()
	_reduce_crossings(paths_by_row, sorted_rows)
	_remeasure_rows(paths_by_row, node_sizes, row_widths, row_heights)

	var max_row_width := 0.0
	for row in sorted_rows:
		var row_paths: Array = paths_by_row[row]
		var row_width: float = row_widths[row] + maxf(row_paths.size() - 1, 0) * COLUMN_SPACING
		row_widths[row] = row_width
		max_row_width = maxf(max_row_width, row_width)

	for row in sorted_rows:
		var row_paths: Array = paths_by_row[row]
		var x: float = MARGIN.x + (max_row_width - row_widths[row]) * 0.5
		var y: float = MARGIN.y + row * ROW_SPACING

		for path in row_paths:
			var node_size: Vector2 = node_sizes[path]
			var row_y: float = y + (row_heights[row] - node_size.y) * 0.5
			_node_rects[path] = Rect2(Vector2(x, row_y), node_size)
			x += node_size.x + COLUMN_SPACING

	_rebuild_graph_bounds()


func _reduce_crossings(paths_by_row: Dictionary, sorted_rows: Array) -> void:
	if sorted_rows.size() <= 1:
		return

	var parents_by_path := {}
	var children_by_path := {}
	_build_adjacency(parents_by_path, children_by_path)

	for _sweep in CROSSING_REDUCTION_SWEEPS:
		for row_index in range(1, sorted_rows.size()):
			var row: int = sorted_rows[row_index]
			var previous_row: int = sorted_rows[row_index - 1]
			var reference_order := _build_order_map(paths_by_row[previous_row])
			paths_by_row[row] = _sort_row_by_barycenter(paths_by_row[row], reference_order, parents_by_path)

		for row_index in range(sorted_rows.size() - 2, -1, -1):
			var row: int = sorted_rows[row_index]
			var next_row: int = sorted_rows[row_index + 1]
			var reference_order := _build_order_map(paths_by_row[next_row])
			paths_by_row[row] = _sort_row_by_barycenter(paths_by_row[row], reference_order, children_by_path)

	for _pass_index in 2:
		for row_index in range(0, sorted_rows.size()):
			var row: int = sorted_rows[row_index]
			if row_index > 0:
				var previous_row: int = sorted_rows[row_index - 1]
				paths_by_row[row] = _reduce_adjacent_swaps(paths_by_row[previous_row], paths_by_row[row])
			if row_index < sorted_rows.size() - 1:
				var next_row: int = sorted_rows[row_index + 1]
				paths_by_row[row] = _reduce_adjacent_swaps(paths_by_row[next_row], paths_by_row[row])


func _build_adjacency(parents_by_path: Dictionary, children_by_path: Dictionary) -> void:
	for path in _nodes:
		parents_by_path[path] = []
		children_by_path[path] = []

	for edge in _edges:
		var from_path: String = edge["from"]
		var to_path: String = edge["to"]
		if not parents_by_path.has(to_path) or not children_by_path.has(from_path):
			continue

		parents_by_path[to_path].append(from_path)
		children_by_path[from_path].append(to_path)


func _sort_row_by_barycenter(row_paths: Array, reference_order: Dictionary, neighbors_by_path: Dictionary) -> Array:
	var records := []
	for index in row_paths.size():
		var path: String = row_paths[index]
		records.append({
			"path": path,
			"order": _calculate_barycenter(path, index, reference_order, neighbors_by_path),
			"original_index": index,
		})

	_insertion_sort_barycenter_records(records)

	var sorted_paths := []
	for record in records:
		sorted_paths.append(record["path"])

	return sorted_paths


func _calculate_barycenter(
	path: String,
	fallback_order: int,
	reference_order: Dictionary,
	neighbors_by_path: Dictionary
) -> float:
	if not neighbors_by_path.has(path):
		return float(fallback_order)

	var total := 0.0
	var count := 0
	for neighbor_path in neighbors_by_path[path]:
		if reference_order.has(neighbor_path):
			total += reference_order[neighbor_path]
			count += 1

	if count == 0:
		return float(fallback_order)

	return total / count


func _insertion_sort_barycenter_records(records: Array) -> void:
	for index in range(1, records.size()):
		var record: Dictionary = records[index]
		var insert_at := index - 1
		while insert_at >= 0 and _barycenter_record_less(record, records[insert_at]):
			records[insert_at + 1] = records[insert_at]
			insert_at -= 1

		records[insert_at + 1] = record


func _barycenter_record_less(left: Dictionary, right: Dictionary) -> bool:
	if not is_equal_approx(left["order"], right["order"]):
		return left["order"] < right["order"]

	return left["original_index"] < right["original_index"]


func _reduce_adjacent_swaps(reference_row_paths: Array, row_paths: Array) -> Array:
	if row_paths.size() <= 1:
		return row_paths

	var optimized := row_paths.duplicate()
	var reference_order := _build_order_map(reference_row_paths)
	var improved := true

	while improved:
		improved = false
		for index in range(optimized.size() - 1):
			var current_crossings := _count_crossings_between_rows(reference_order, optimized)
			var swapped := optimized.duplicate()
			var temp = swapped[index]
			swapped[index] = swapped[index + 1]
			swapped[index + 1] = temp
			var swapped_crossings := _count_crossings_between_rows(reference_order, swapped)

			if swapped_crossings < current_crossings:
				optimized = swapped
				improved = true

	return optimized


func _count_crossings_between_rows(reference_order: Dictionary, row_paths: Array) -> int:
	var row_order := _build_order_map(row_paths)
	var row_lookup := {}
	for path in row_paths:
		row_lookup[path] = true

	var row_edges := []
	for edge in _edges:
		var from_path: String = edge["from"]
		var to_path: String = edge["to"]

		if reference_order.has(from_path) and row_lookup.has(to_path):
			row_edges.append(Vector2i(reference_order[from_path], row_order[to_path]))
		elif reference_order.has(to_path) and row_lookup.has(from_path):
			row_edges.append(Vector2i(reference_order[to_path], row_order[from_path]))

	var crossings := 0
	for first_index in range(row_edges.size()):
		for second_index in range(first_index + 1, row_edges.size()):
			var first: Vector2i = row_edges[first_index]
			var second: Vector2i = row_edges[second_index]
			if (first.x - second.x) * (first.y - second.y) < 0:
				crossings += 1

	return crossings


func _build_order_map(paths: Array) -> Dictionary:
	var order := {}
	for index in paths.size():
		order[paths[index]] = index

	return order


func _remeasure_rows(paths_by_row: Dictionary, node_sizes: Dictionary, row_widths: Dictionary, row_heights: Dictionary) -> void:
	for row in paths_by_row.keys():
		row_widths[row] = 0.0
		row_heights[row] = 0.0
		for path in paths_by_row[row]:
			var node_size: Vector2 = node_sizes[path]
			row_widths[row] += node_size.x
			row_heights[row] = maxf(row_heights[row], node_size.y)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_button_event := event as InputEventMouseButton
		if mouse_button_event.button_index == MOUSE_BUTTON_WHEEL_UP and mouse_button_event.pressed:
			_zoom_at(mouse_button_event.position, 1.12)
			accept_event()
		elif mouse_button_event.button_index == MOUSE_BUTTON_WHEEL_DOWN and mouse_button_event.pressed:
			_zoom_at(mouse_button_event.position, 1.0 / 1.12)
			accept_event()
		elif mouse_button_event.button_index == MOUSE_BUTTON_LEFT:
			if mouse_button_event.pressed:
				var world_position := _screen_to_world(mouse_button_event.position)
				var hit_path := _hit_test_node(world_position)
				if hit_path != "":
					_handle_node_press(hit_path, world_position, mouse_button_event.ctrl_pressed)
				else:
					if not mouse_button_event.ctrl_pressed:
						_selected_node_paths.clear()
					_box_selecting = true
					_box_select_start = world_position
					_box_select_end = world_position
			else:
				_dragged_node_path = ""
				_drag_start_node_positions.clear()
				if _box_selecting:
					_apply_box_selection(mouse_button_event.ctrl_pressed)
				_box_selecting = false
			queue_redraw()
			accept_event()
		elif mouse_button_event.button_index == MOUSE_BUTTON_MIDDLE:
			_is_panning = mouse_button_event.pressed
			_last_mouse_position = mouse_button_event.position
			accept_event()
	elif event is InputEventMouseMotion and _dragged_node_path != "":
		var mouse_motion_event := event as InputEventMouseMotion
		var new_dragged_position := _screen_to_world(mouse_motion_event.position) - _node_drag_offset
		var drag_delta := new_dragged_position - (_drag_start_node_positions[_dragged_node_path] as Vector2)
		for path in _drag_start_node_positions.keys():
			var rect: Rect2 = _node_rects[path]
			rect.position = (_drag_start_node_positions[path] as Vector2) + drag_delta
			_node_rects[path] = rect
		_rebuild_graph_bounds()
		queue_redraw()
		accept_event()
	elif event is InputEventMouseMotion and _box_selecting:
		var mouse_motion_event := event as InputEventMouseMotion
		_box_select_end = _screen_to_world(mouse_motion_event.position)
		queue_redraw()
		accept_event()
	elif event is InputEventMouseMotion and _is_panning:
		var mouse_motion_event := event as InputEventMouseMotion
		_pan_offset += mouse_motion_event.position - _last_mouse_position
		_last_mouse_position = mouse_motion_event.position
		queue_redraw()
		accept_event()


func _zoom_at(screen_position: Vector2, zoom_factor: float) -> void:
	var old_zoom := _zoom
	var new_zoom := clampf(_zoom * zoom_factor, MIN_ZOOM, MAX_ZOOM)
	if is_equal_approx(old_zoom, new_zoom):
		return

	var world_position := _screen_to_world(screen_position)
	_zoom = new_zoom
	_pan_offset = screen_position - world_position * _zoom
	queue_redraw()


func _screen_to_world(screen_position: Vector2) -> Vector2:
	return (screen_position - _pan_offset) / _zoom


func _draw() -> void:
	_draw_background()
	draw_set_transform(_pan_offset, 0.0, Vector2(_zoom, _zoom))
	_draw_edges()
	_draw_nodes()
	_draw_box_selection()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_background() -> void:
	var panel_style := _get_stylebox("panel", "GraphStateMachine")
	if panel_style != null:
		draw_style_box(panel_style, Rect2(Vector2.ZERO, size))
	else:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.13, 0.13, 0.13, 1.0), true)


func _draw_edges() -> void:
	var line_color := _get_color("transition_color", "GraphStateMachine", Color(0.48, 0.72, 1.0, 0.95))

	for edge in _edges:
		var from_path: String = edge["from"]
		var to_path: String = edge["to"]
		if not _node_rects.has(from_path) or not _node_rects.has(to_path):
			continue

		var from_rect: Rect2 = _node_rects[from_path]
		var to_rect: Rect2 = _node_rects[to_path]
		var start := from_rect.get_center()
		var end := to_rect.get_center()
		start = _clip_line_to_rect(start, end, from_rect)
		end = _clip_line_to_rect(end, start, to_rect)

		_draw_arrow(start, end, line_color)


func _draw_arrow(start: Vector2, end: Vector2, color: Color) -> void:
	var direction := end - start
	if direction.length() <= 0.01:
		return

	var normalized := direction.normalized()
	var tip := end
	var line_end := tip - normalized * ARROW_SIZE
	draw_line(start, line_end, color, ARROW_LINE_WIDTH, true)

	var perpendicular := Vector2(-normalized.y, normalized.x)
	var arrow_points := PackedVector2Array([
		tip,
		tip - normalized * ARROW_SIZE + perpendicular * (ARROW_SIZE * 0.55),
		tip - normalized * ARROW_SIZE - perpendicular * (ARROW_SIZE * 0.55),
	])
	draw_colored_polygon(arrow_points, color)


func _draw_nodes() -> void:
	var node_style := _make_readable_node_style(_get_stylebox("node_frame", "GraphStateMachine"))
	var selected_node_style := _get_stylebox("node_frame_selected", "GraphStateMachine")
	var font := _get_font("node_title_font", "GraphStateMachine")
	var font_size := _get_font_size("node_title_font_size", "GraphStateMachine", 16)
	var title_color := _get_color("node_title_font_color", "GraphStateMachine", Color(0.86, 0.86, 0.86, 1.0))
	var icon := _get_icon("Script", "EditorIcons")

	for path in _nodes:
		if not _node_rects.has(path):
			continue

		var rect: Rect2 = _node_rects[path]
		var active_style := selected_node_style if _selected_node_paths.has(path) and selected_node_style != null else node_style
		if active_style != null:
			draw_style_box(active_style, rect)
		else:
			draw_rect(rect, Color(0.12, 0.12, 0.13, 1.0), true)
			draw_rect(rect, Color(0.0, 0.0, 0.0, 0.55), false, 1.0)

		var title := String(_display_names.get(path, path.get_file()))
		var content_x := rect.position.x + NODE_CONTENT_PADDING
		if icon != null:
			var icon_position := Vector2(
				content_x,
				rect.position.y + (rect.size.y - icon.get_height()) * 0.5
			).floor()
			draw_texture(icon, icon_position)
			content_x += icon.get_width() + NODE_CONTENT_SPACING

		var text_height := font.get_height(font_size)
		var text_position := Vector2(
			content_x,
			rect.position.y + (rect.size.y - text_height) * 0.5 + font.get_ascent(font_size)
		).floor()
		draw_string(font, text_position, title, HORIZONTAL_ALIGNMENT_LEFT, rect.end.x - content_x - NODE_CONTENT_PADDING, font_size, title_color)


func _draw_box_selection() -> void:
	if not _box_selecting:
		return

	var rect := _make_positive_rect(_box_select_start, _box_select_end)
	var fill_color := _get_color("highlight_color", "GraphStateMachine", Color(0.4, 0.6, 1.0, 1.0))
	var border_color := fill_color
	fill_color.a = 0.18
	border_color.a = 0.75
	draw_rect(rect, fill_color, true)
	draw_rect(rect, border_color, false, 1.0)


func _measure_node_size(path: String) -> Vector2:
	var title := String(_display_names.get(path, path.get_file()))
	var font := _get_font("node_title_font", "GraphStateMachine")
	var font_size := _get_font_size("node_title_font_size", "GraphStateMachine", 16)
	var icon := _get_icon("Script", "EditorIcons")
	var icon_width: float = icon.get_width() if icon != null else 0.0
	var icon_height: float = icon.get_height() if icon != null else 0.0
	var text_size: Vector2 = font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var width: float = NODE_CONTENT_PADDING * 2.0 + icon_width + NODE_CONTENT_SPACING + text_size.x
	var height: float = NODE_CONTENT_PADDING * 2.0 + maxf(icon_height, font.get_height(font_size))
	return Vector2(maxf(NODE_MIN_SIZE.x, width), maxf(NODE_MIN_SIZE.y, height))


func _make_readable_node_style(style: StyleBox) -> StyleBox:
	if style == null:
		return null

	var adjusted := style.duplicate()
	if adjusted is StyleBoxFlat:
		var flat_style := adjusted as StyleBoxFlat
		var bg_color := flat_style.bg_color
		var border_color := flat_style.border_color

		bg_color.a = maxf(bg_color.a, 0.92)
		bg_color = bg_color.lightened(0.08)
		border_color = border_color.lightened(0.18)
		border_color.a = maxf(border_color.a, 0.7)

		flat_style.bg_color = bg_color
		flat_style.border_color = border_color

	return adjusted


func _hit_test_node(world_position: Vector2) -> String:
	for index in range(_nodes.size() - 1, -1, -1):
		var path: String = _nodes[index]
		if _node_rects.has(path) and (_node_rects[path] as Rect2).has_point(world_position):
			return path

	return ""


func _bring_node_to_front(path: String) -> void:
	var index := _nodes.find(path)
	if index == -1:
		return

	_nodes.remove_at(index)
	_nodes.append(path)


func _select_single_node(path: String) -> void:
	_selected_node_paths.clear()
	_selected_node_paths[path] = true


func _handle_node_press(path: String, world_position: Vector2, toggle_selection: bool) -> void:
	if toggle_selection and _selected_node_paths.has(path):
		_selected_node_paths.erase(path)
		_dragged_node_path = ""
		_drag_start_node_positions.clear()
		return

	if toggle_selection:
		_selected_node_paths[path] = true
	elif not _selected_node_paths.has(path):
		_select_single_node(path)

	_dragged_node_path = path
	_node_drag_offset = world_position - (_node_rects[path] as Rect2).position
	_capture_drag_start_positions()
	_bring_node_to_front(path)


func _capture_drag_start_positions() -> void:
	_drag_start_node_positions.clear()
	if _dragged_node_path == "":
		return

	if not _selected_node_paths.has(_dragged_node_path):
		_selected_node_paths[_dragged_node_path] = true

	for path in _selected_node_paths.keys():
		if _node_rects.has(path):
			_drag_start_node_positions[path] = (_node_rects[path] as Rect2).position


func _apply_box_selection(add_to_selection: bool) -> void:
	var selection_rect := _make_positive_rect(_box_select_start, _box_select_end)
	if not add_to_selection:
		_selected_node_paths.clear()

	for path in _nodes:
		if _node_rects.has(path) and selection_rect.intersects(_node_rects[path], true):
			_selected_node_paths[path] = true


func _make_positive_rect(from_position: Vector2, to_position: Vector2) -> Rect2:
	return Rect2(from_position, to_position - from_position).abs()


func _rebuild_graph_bounds() -> void:
	if _node_rects.is_empty():
		_graph_bounds = Rect2(Vector2.ZERO, Vector2.ZERO)
		return

	var first := true
	var bounds := Rect2(Vector2.ZERO, Vector2.ZERO)
	for rect in _node_rects.values():
		if first:
			bounds = rect
			first = false
		else:
			bounds = bounds.merge(rect)

	_graph_bounds = bounds


func _clip_line_to_rect(inside: Vector2, outside: Vector2, rect: Rect2) -> Vector2:
	var d := outside - inside
	if d.is_zero_approx():
		return inside

	var best_t := INF
	var t: float
	var cross: float

	if not is_zero_approx(d.x):
		t = (rect.position.x - inside.x) / d.x
		if t > 0.0 and t < best_t:
			cross = inside.y + t * d.y
			if cross >= rect.position.y and cross <= rect.end.y:
				best_t = t

		t = (rect.end.x - inside.x) / d.x
		if t > 0.0 and t < best_t:
			cross = inside.y + t * d.y
			if cross >= rect.position.y and cross <= rect.end.y:
				best_t = t

	if not is_zero_approx(d.y):
		t = (rect.position.y - inside.y) / d.y
		if t > 0.0 and t < best_t:
			cross = inside.x + t * d.x
			if cross >= rect.position.x and cross <= rect.end.x:
				best_t = t

		t = (rect.end.y - inside.y) / d.y
		if t > 0.0 and t < best_t:
			cross = inside.x + t * d.x
			if cross >= rect.position.x and cross <= rect.end.x:
				best_t = t

	if best_t == INF:
		return inside

	return inside + best_t * d


func _get_stylebox(name: StringName, theme_type: StringName) -> StyleBox:
	if has_theme_stylebox(name, theme_type):
		return get_theme_stylebox(name, theme_type)
	return null


func _get_color(name: StringName, theme_type: StringName, fallback: Color) -> Color:
	if has_theme_color(name, theme_type):
		return get_theme_color(name, theme_type)
	return fallback


func _get_font(name: StringName, theme_type: StringName) -> Font:
	if has_theme_font(name, theme_type):
		return get_theme_font(name, theme_type)
	if has_theme_font("bold", "EditorFonts"):
		return get_theme_font("bold", "EditorFonts")
	return get_theme_font("font", "Label")


func _get_font_size(name: StringName, theme_type: StringName, fallback: int) -> int:
	if has_theme_font_size(name, theme_type):
		return get_theme_font_size(name, theme_type)
	return fallback


func _get_icon(name: StringName, theme_type: StringName) -> Texture2D:
	if has_theme_icon(name, theme_type):
		return get_theme_icon(name, theme_type)
	return null
