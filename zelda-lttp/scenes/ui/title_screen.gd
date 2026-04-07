extends Control

## Title screen with New Game, Continue (disabled until 6.6), Options placeholder.
## Animated background: slow-scrolling triforce pattern.

signal new_game_requested(slot: int)
signal continue_requested(slot: int)

enum Screen { TITLE, SLOT_SELECT, CONFIRM_OVERWRITE, CONFIRM_DELETE }

var _screen: int = Screen.TITLE
var _cursor: int = 0
var _slot_cursor: int = 0
var _is_new_game: bool = false
var _confirm_cursor: int = 1  # 0 = Yes, 1 = No (default No)
var _anim_time: float = 0.0

const MENU_ITEMS := ["New Game", "Continue", "Options"]
const SLOT_COUNT := 3


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_screen = Screen.TITLE
	_cursor = 0
	visible = true


func _process(delta: float) -> void:
	_anim_time += delta
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return

	match _screen:
		Screen.TITLE:
			_handle_title_input(event)
		Screen.SLOT_SELECT:
			_handle_slot_input(event)
		Screen.CONFIRM_OVERWRITE, Screen.CONFIRM_DELETE:
			_handle_confirm_input(event)


func _handle_title_input(event: InputEvent) -> void:
	if event.is_action_pressed("move_up"):
		_cursor = (_cursor - 1 + MENU_ITEMS.size()) % MENU_ITEMS.size()
		AudioManager.play_sfx(&"menu_move")
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("move_down"):
		_cursor = (_cursor + 1) % MENU_ITEMS.size()
		AudioManager.play_sfx(&"menu_move")
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("interact") or event.is_action_pressed("action_sword"):
		get_viewport().set_input_as_handled()
		match _cursor:
			0:  # New Game
				_is_new_game = true
				_slot_cursor = 0
				_screen = Screen.SLOT_SELECT
				AudioManager.play_sfx(&"menu_select")
			1:  # Continue
				if _any_saves_exist():
					_is_new_game = false
					_slot_cursor = _first_occupied_slot()
					_screen = Screen.SLOT_SELECT
					AudioManager.play_sfx(&"menu_select")
				else:
					AudioManager.play_sfx(&"error")
			2:  # Options (placeholder)
				AudioManager.play_sfx(&"error")


func _handle_slot_input(event: InputEvent) -> void:
	if event.is_action_pressed("move_up"):
		_move_slot_cursor(-1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("move_down"):
		_move_slot_cursor(1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("interact") or event.is_action_pressed("action_sword"):
		get_viewport().set_input_as_handled()
		var has: bool = SaveManager.has_save(_slot_cursor + 1)
		if _is_new_game:
			if has:
				_confirm_cursor = 1
				_screen = Screen.CONFIRM_OVERWRITE
				AudioManager.play_sfx(&"menu_select")
			else:
				_start_new_game(_slot_cursor + 1)
		else:  # Continue — empty slots are unselectable
			if has:
				_load_game(_slot_cursor + 1)
			else:
				AudioManager.play_sfx(&"error")
	elif event.is_action_pressed("action_item"):
		# Delete save (Continue mode only, occupied slots)
		if not _is_new_game and SaveManager.has_save(_slot_cursor + 1):
			_confirm_cursor = 1
			_screen = Screen.CONFIRM_DELETE
			AudioManager.play_sfx(&"menu_select")
			get_viewport().set_input_as_handled()
	elif event.is_action_pressed("pause"):
		_screen = Screen.TITLE
		AudioManager.play_sfx(&"menu_back")
		get_viewport().set_input_as_handled()


func _move_slot_cursor(direction: int) -> void:
	if not _is_new_game:
		# In Continue mode, skip empty slots
		var start := _slot_cursor
		for i in SLOT_COUNT:
			_slot_cursor = (_slot_cursor + direction + SLOT_COUNT) % SLOT_COUNT
			if SaveManager.has_save(_slot_cursor + 1):
				AudioManager.play_sfx(&"menu_move")
				return
		# No occupied slots found — stay put
		_slot_cursor = start
	else:
		_slot_cursor = (_slot_cursor + direction + SLOT_COUNT) % SLOT_COUNT
		AudioManager.play_sfx(&"menu_move")


func _handle_confirm_input(event: InputEvent) -> void:
	if event.is_action_pressed("move_left") or event.is_action_pressed("move_right"):
		_confirm_cursor = 1 - _confirm_cursor
		AudioManager.play_sfx(&"menu_move")
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("interact") or event.is_action_pressed("action_sword"):
		get_viewport().set_input_as_handled()
		if _confirm_cursor == 0:  # Yes
			if _screen == Screen.CONFIRM_OVERWRITE:
				SaveManager.delete_save(_slot_cursor + 1)
				_start_new_game(_slot_cursor + 1)
			elif _screen == Screen.CONFIRM_DELETE:
				SaveManager.delete_save(_slot_cursor + 1)
				_screen = Screen.SLOT_SELECT
				AudioManager.play_sfx(&"menu_select")
		else:  # No
			_screen = Screen.SLOT_SELECT
			AudioManager.play_sfx(&"menu_back")
	elif event.is_action_pressed("pause"):
		_screen = Screen.SLOT_SELECT
		AudioManager.play_sfx(&"menu_back")
		get_viewport().set_input_as_handled()


func _start_new_game(slot: int) -> void:
	AudioManager.play_sfx(&"menu_select")
	new_game_requested.emit(slot)


func _load_game(slot: int) -> void:
	AudioManager.play_sfx(&"menu_select")
	continue_requested.emit(slot)


func _first_occupied_slot() -> int:
	for i in SLOT_COUNT:
		if SaveManager.has_save(i + 1):
			return i
	return 0


func _any_saves_exist() -> bool:
	for i in SLOT_COUNT:
		if SaveManager.has_save(i + 1):
			return true
	return false


func _draw() -> void:
	# Background
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.02, 0.02, 0.06))

	# Animated background: slow-moving diagonal lines
	for i in range(20):
		var y_offset: float = fmod(_anim_time * 8.0 + float(i) * 20.0, size.y + 40.0) - 20.0
		draw_line(
			Vector2(0, y_offset),
			Vector2(size.x, y_offset - 30),
			Color(0.08, 0.06, 0.15, 0.3), 1.0
		)

	# Triforce decoration
	var cx: float = size.x / 2.0
	var tri_y: float = 30.0 + sin(_anim_time * 0.8) * 3.0
	var tri_size: float = 12.0
	_draw_triforce(Vector2(cx, tri_y), tri_size)

	match _screen:
		Screen.TITLE:
			_draw_title()
		Screen.SLOT_SELECT:
			_draw_slot_select()
		Screen.CONFIRM_OVERWRITE:
			_draw_slot_select()
			_draw_confirm("Overwrite this save?")
		Screen.CONFIRM_DELETE:
			_draw_slot_select()
			_draw_confirm("Delete this save?")


func _draw_title() -> void:
	# Title text
	var cx: float = size.x / 2.0
	var title := "ZELDA"
	var title_size: Vector2 = ThemeDB.fallback_font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, 16)
	draw_string(ThemeDB.fallback_font, Vector2(cx - title_size.x / 2.0, 64), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.9, 0.75, 0.2))

	var subtitle := "A Link to the Past"
	var sub_size: Vector2 = ThemeDB.fallback_font.get_string_size(subtitle, HORIZONTAL_ALIGNMENT_LEFT, -1, 8)
	draw_string(ThemeDB.fallback_font, Vector2(cx - sub_size.x / 2.0, 78), subtitle, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(0.7, 0.7, 0.8))

	# Menu items
	var menu_y: float = 110.0
	var continue_available := _any_saves_exist()
	for i in MENU_ITEMS.size():
		var item_text: String = MENU_ITEMS[i]
		var text_color := Color.WHITE
		if i == 1 and not continue_available:
			text_color = Color(0.4, 0.4, 0.4)  # Grayed out
		var text_size: Vector2 = ThemeDB.fallback_font.get_string_size(item_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10)
		var x: float = cx - text_size.x / 2.0
		var y: float = menu_y + float(i) * 18.0

		if i == _cursor:
			# Cursor arrow
			draw_string(ThemeDB.fallback_font, Vector2(x - 12, y), ">", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(1.0, 0.9, 0.3))
		draw_string(ThemeDB.fallback_font, Vector2(x, y), item_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, text_color)


func _draw_slot_select() -> void:
	var cx: float = size.x / 2.0
	var header := "Select Slot" if _is_new_game else "Select Save"
	var h_size: Vector2 = ThemeDB.fallback_font.get_string_size(header, HORIZONTAL_ALIGNMENT_LEFT, -1, 10)
	draw_string(ThemeDB.fallback_font, Vector2(cx - h_size.x / 2.0, 55), header, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.8, 0.8, 0.9))

	for i in SLOT_COUNT:
		var slot_y: float = 75.0 + float(i) * 36.0
		var slot_rect := Rect2(40, slot_y, size.x - 80, 30)

		# Slot background
		var bg_color := Color(0.12, 0.12, 0.18, 0.8) if i == _slot_cursor else Color(0.06, 0.06, 0.1, 0.6)
		draw_rect(slot_rect, bg_color)
		draw_rect(slot_rect, Color(0.5, 0.5, 0.6, 0.5) if i == _slot_cursor else Color(0.3, 0.3, 0.4, 0.3), false, 1.0)

		var meta: Dictionary = SaveManager.get_slot_metadata(i + 1)
		if meta.is_empty():
			var empty_text := "- Empty -"
			var et_size: Vector2 = ThemeDB.fallback_font.get_string_size(empty_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 8)
			draw_string(ThemeDB.fallback_font, Vector2(cx - et_size.x / 2.0, slot_y + 18), empty_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(0.4, 0.4, 0.5))
		else:
			# Show save info: hearts, play time
			var hearts: int = meta.get("max_health", 6) / 2
			var play_time: int = meta.get("play_time_seconds", 0)
			var hours: int = play_time / 3600
			var minutes: int = (play_time % 3600) / 60
			var info := "Slot %d   %d hearts   %02d:%02d" % [i + 1, hearts, hours, minutes]
			draw_string(ThemeDB.fallback_font, Vector2(slot_rect.position.x + 6, slot_y + 12), info, HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color.WHITE)
			var ts: String = meta.get("timestamp", "")
			if ts != "":
				draw_string(ThemeDB.fallback_font, Vector2(slot_rect.position.x + 6, slot_y + 24), ts.substr(0, 10), HORIZONTAL_ALIGNMENT_LEFT, -1, 6, Color(0.6, 0.6, 0.7))

		# Cursor (skip cursor on empty slots in Continue mode)
		if i == _slot_cursor:
			draw_string(ThemeDB.fallback_font, Vector2(30, slot_y + 18), ">", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(1.0, 0.9, 0.3))

	# Hint at bottom
	if not _is_new_game:
		draw_string(ThemeDB.fallback_font, Vector2(40, 190), "[B] Delete", HORIZONTAL_ALIGNMENT_LEFT, -1, 6, Color(0.5, 0.4, 0.4))


func _draw_confirm(prompt: String) -> void:
	# Overlay box
	var box := Rect2(40, 90, size.x - 80, 44)
	draw_rect(box, Color(0.05, 0.05, 0.1, 0.95))
	draw_rect(box, Color(0.7, 0.7, 0.7, 0.8), false, 1.0)

	var cx: float = size.x / 2.0
	var p_size: Vector2 = ThemeDB.fallback_font.get_string_size(prompt, HORIZONTAL_ALIGNMENT_LEFT, -1, 8)
	draw_string(ThemeDB.fallback_font, Vector2(cx - p_size.x / 2.0, 106), prompt, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color.WHITE)

	# Yes / No
	var yes_color := Color(1.0, 0.9, 0.3) if _confirm_cursor == 0 else Color(0.6, 0.6, 0.6)
	var no_color := Color(1.0, 0.9, 0.3) if _confirm_cursor == 1 else Color(0.6, 0.6, 0.6)
	draw_string(ThemeDB.fallback_font, Vector2(cx - 30, 125), "Yes", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, yes_color)
	draw_string(ThemeDB.fallback_font, Vector2(cx + 14, 125), "No", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, no_color)


func _draw_triforce(center: Vector2, s: float) -> void:
	var glow := 0.6 + sin(_anim_time * 1.5) * 0.2
	var gold := Color(0.9, 0.75, 0.2, glow)
	# Top triangle
	_draw_tri(center + Vector2(0, -s * 0.58), s, gold)
	# Bottom-left
	_draw_tri(center + Vector2(-s * 0.5, s * 0.29), s, gold)
	# Bottom-right
	_draw_tri(center + Vector2(s * 0.5, s * 0.29), s, gold)


func _draw_tri(center: Vector2, s: float, color: Color) -> void:
	var h: float = s * 0.866
	var pts := PackedVector2Array([
		center + Vector2(0, -h * 0.67),
		center + Vector2(s * 0.5, h * 0.33),
		center + Vector2(-s * 0.5, h * 0.33),
	])
	draw_colored_polygon(pts, color)
