extends Control

var _cursor_pos: Vector2i = Vector2i.ZERO
var _skill_ids: Array[StringName] = []
const GRID_COLS := 5
const CELL_SIZE := 20
const GRID_ORIGIN := Vector2(60, 24)
const GEAR_ORIGIN := Vector2(20, 100)
const RESOURCE_ORIGIN := Vector2(20, 160)


func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	focus_mode = Control.FOCUS_NONE


func open() -> void:
	_refresh_skills()
	visible = true
	_cursor_pos = Vector2i.ZERO
	queue_redraw()


func close() -> void:
	visible = false


func _refresh_skills() -> void:
	_skill_ids.clear()
	for id: StringName in PlayerState.get_owned_skills():
		_skill_ids.append(id)


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return

	if event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		close()
		get_tree().paused = false
		return

	var moved := false
	if event.is_action_pressed("move_right"):
		_cursor_pos.x = mini(_cursor_pos.x + 1, GRID_COLS - 1)
		moved = true
	elif event.is_action_pressed("move_left"):
		_cursor_pos.x = maxi(_cursor_pos.x - 1, 0)
		moved = true
	elif event.is_action_pressed("move_down"):
		var max_row: int = (_skill_ids.size() - 1) / GRID_COLS if _skill_ids.size() > 0 else 0
		_cursor_pos.y = mini(_cursor_pos.y + 1, max_row)
		moved = true
	elif event.is_action_pressed("move_up"):
		_cursor_pos.y = maxi(_cursor_pos.y - 1, 0)
		moved = true

	if moved:
		get_viewport().set_input_as_handled()
		queue_redraw()

	if event.is_action_pressed("interact") or event.is_action_pressed("action_sword"):
		var idx: int = _cursor_pos.y * GRID_COLS + _cursor_pos.x
		if idx >= 0 and idx < _skill_ids.size():
			PlayerState.equip_skill(_skill_ids[idx])
			AudioManager.play_sfx(&"menu_select")
			queue_redraw()
		get_viewport().set_input_as_handled()


func _draw() -> void:
	if not visible:
		return

	# Full-screen dark background
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.05, 0.05, 0.1, 0.92))

	# --- Equipped skill display ---
	var equipped: ItemData = PlayerState.get_equipped_skill()
	_draw_text(Vector2(8, 14), "B:", 8, Color.WHITE)
	if equipped:
		_draw_item_icon(Vector2(28, 4), equipped)

	# --- Skill grid ---
	_draw_text(Vector2(GRID_ORIGIN.x, GRID_ORIGIN.y - 4), "ITEMS", 8, Color(0.8, 0.8, 0.8))

	for i in range(_skill_ids.size()):
		var col: int = i % GRID_COLS
		var row: int = i / GRID_COLS
		var cell_pos := GRID_ORIGIN + Vector2(col * CELL_SIZE, row * CELL_SIZE)

		# Cell background
		var is_equipped: bool = _skill_ids[i] == PlayerState.equipped_skill_id
		var bg_color := Color(0.2, 0.3, 0.5, 0.5) if is_equipped else Color(0.15, 0.15, 0.2, 0.4)
		draw_rect(Rect2(cell_pos, Vector2(CELL_SIZE - 2, CELL_SIZE - 2)), bg_color)

		# Item icon
		var skill_data: ItemData = PlayerState.owned_skills.get(_skill_ids[i]) as ItemData
		if skill_data:
			_draw_item_icon(cell_pos, skill_data)

	# Cursor
	if _skill_ids.size() > 0:
		var cursor_col: int = _cursor_pos.x
		var cursor_row: int = _cursor_pos.y
		var cursor_cell := GRID_ORIGIN + Vector2(cursor_col * CELL_SIZE, cursor_row * CELL_SIZE)
		draw_rect(Rect2(cursor_cell - Vector2(1, 1), Vector2(CELL_SIZE, CELL_SIZE)), Color(1.0, 0.9, 0.2, 0.8), false, 1.5)

	# --- Gear display ---
	_draw_text(Vector2(GEAR_ORIGIN.x, GEAR_ORIGIN.y - 4), "GEAR", 8, Color(0.8, 0.8, 0.8))

	_draw_upgrade_pips("SWD", &"sword", 4, GEAR_ORIGIN + Vector2(0, 0))
	_draw_upgrade_pips("ARM", &"armor", 3, GEAR_ORIGIN + Vector2(0, 12))
	_draw_upgrade_pips("SHD", &"shield", 3, GEAR_ORIGIN + Vector2(0, 24))
	_draw_upgrade_pips("GLV", &"gloves", 2, GEAR_ORIGIN + Vector2(110, 0))
	_draw_upgrade_bool("BOOT", &"boots", GEAR_ORIGIN + Vector2(110, 12))
	_draw_upgrade_bool("FLIP", &"flippers", GEAR_ORIGIN + Vector2(110, 24))

	# --- Resources ---
	_draw_text(Vector2(RESOURCE_ORIGIN.x, RESOURCE_ORIGIN.y - 4), "STATUS", 8, Color(0.8, 0.8, 0.8))

	_draw_text(RESOURCE_ORIGIN + Vector2(0, 10), "HP: %d/%d" % [PlayerState.current_health, PlayerState.max_health], 8, Color(0.9, 0.3, 0.3))
	_draw_text(RESOURCE_ORIGIN + Vector2(0, 22), "MP: %d/%d" % [PlayerState.current_magic, PlayerState.max_magic], 8, Color(0.3, 0.8, 0.4))
	_draw_text(RESOURCE_ORIGIN + Vector2(100, 10), "Rupees: %d" % PlayerState.rupees, 8, Color(0.3, 0.9, 0.3))
	_draw_text(RESOURCE_ORIGIN + Vector2(100, 22), "Arrows: %d  Bombs: %d" % [PlayerState.arrows, PlayerState.bombs], 8, Color.WHITE)
	_draw_text(RESOURCE_ORIGIN + Vector2(0, 38), "Heart Pieces: %d/4" % PlayerState.heart_pieces, 8, Color(1.0, 0.5, 0.5))


func _draw_text(pos: Vector2, text: String, font_size: int, color: Color) -> void:
	draw_string(ThemeDB.fallback_font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)


func _draw_item_icon(pos: Vector2, item: ItemData) -> void:
	var center := pos + Vector2(CELL_SIZE / 2.0 - 1, CELL_SIZE / 2.0 - 1)
	if item.icon_shape.size() > 0:
		var points := PackedVector2Array()
		for p in item.icon_shape:
			points.append(p * 0.7 + center)
		draw_colored_polygon(points, item.icon_color)
	else:
		draw_circle(center, 4.0, item.icon_color)


func _draw_upgrade_pips(label: String, key: StringName, max_tier: int, pos: Vector2) -> void:
	var current: int = PlayerState.get_upgrade(key)
	_draw_text(pos + Vector2(0, 9), label, 7, Color(0.7, 0.7, 0.7))
	for i in range(max_tier):
		var pip_x: float = pos.x + 30 + i * 10
		var pip_y: float = pos.y + 2
		var filled: bool = i < current
		var color := Color(0.2, 0.8, 0.3) if filled else Color(0.3, 0.3, 0.3, 0.5)
		draw_rect(Rect2(pip_x, pip_y, 7, 7), color)
		draw_rect(Rect2(pip_x, pip_y, 7, 7), Color(0.6, 0.6, 0.6, 0.5), false, 1.0)


func _draw_upgrade_bool(label: String, key: StringName, pos: Vector2) -> void:
	var owned: bool = PlayerState.has_upgrade(key)
	var color := Color(0.2, 0.8, 0.3) if owned else Color(0.4, 0.4, 0.4)
	_draw_text(pos + Vector2(0, 9), label, 7, color)
