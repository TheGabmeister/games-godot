extends Control

## Dialog box with typewriter effect, multi-page support, and interact advancement.
## Sits on DialogLayer (CanvasLayer 15), process_mode ALWAYS.

var _lines: Array = []
var _current_line: int = 0
var _char_index: int = 0  # Characters revealed so far
var _char_timer: float = 0.0
var _is_active: bool = false
var _page_complete: bool = false

const BOX_MARGIN := 8.0
const BOX_HEIGHT := 40.0
const TEXT_PADDING := 6.0
const FONT_SIZE := 8
const CHARS_PER_SECOND := 30.0
const FAST_CHARS_PER_SECOND := 120.0

var _fast_forward: bool = false
var _paused_by_dialog: bool = false


func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	EventBus.dialog_requested.connect(_on_dialog_requested)
	EventBus.dialog_force_close.connect(_on_force_close)


func _on_dialog_requested(lines: Array) -> void:
	_lines = lines
	_current_line = 0
	_char_index = 0
	_char_timer = 0.0
	_page_complete = false
	_fast_forward = false
	_is_active = true
	visible = true
	# Pause the game if not already paused (e.g. by ItemGetState or pause menu)
	if not get_tree().paused:
		get_tree().paused = true
		_paused_by_dialog = true
	else:
		_paused_by_dialog = false
	queue_redraw()


func _on_force_close() -> void:
	if _is_active:
		_close_dialog()


func _close_dialog() -> void:
	_is_active = false
	visible = false
	_lines.clear()
	_current_line = 0
	_char_index = 0
	_page_complete = false
	_fast_forward = false
	# Unpause only if we were the ones who paused
	if _paused_by_dialog:
		get_tree().paused = false
		_paused_by_dialog = false
	queue_redraw()
	EventBus.dialog_closed.emit()


func _process(delta: float) -> void:
	if not _is_active or _lines.is_empty():
		return

	if _page_complete:
		return

	# Typewriter: reveal characters over time
	var current_text: String = str(_lines[_current_line])
	var speed: float = FAST_CHARS_PER_SECOND if _fast_forward else CHARS_PER_SECOND
	_char_timer += delta * speed
	while _char_timer >= 1.0 and _char_index < current_text.length():
		_char_index += 1
		_char_timer -= 1.0
		if _char_index % 3 == 0:
			AudioManager.play_sfx(&"text_blip")

	if _char_index >= current_text.length():
		_page_complete = true
		_fast_forward = false

	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if not _is_active:
		return

	if event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		if not _page_complete:
			# Fast-forward: reveal all text on current page
			_char_index = str(_lines[_current_line]).length()
			_page_complete = true
			_fast_forward = false
			queue_redraw()
		else:
			# Advance to next page or close
			_current_line += 1
			if _current_line >= _lines.size():
				_close_dialog()
			else:
				_char_index = 0
				_char_timer = 0.0
				_page_complete = false
				queue_redraw()


func _draw() -> void:
	if not _is_active or _lines.is_empty():
		return

	var box_y: float = size.y - BOX_HEIGHT - BOX_MARGIN
	var box_rect := Rect2(BOX_MARGIN, box_y, size.x - BOX_MARGIN * 2, BOX_HEIGHT)

	# Dark background
	draw_rect(box_rect, Color(0.05, 0.05, 0.12, 0.92))
	# Border
	draw_rect(box_rect, Color(0.7, 0.7, 0.7, 0.8), false, 1.0)

	# Text with typewriter reveal
	if _current_line < _lines.size():
		var full_text: String = str(_lines[_current_line])
		var revealed_text: String = full_text.substr(0, _char_index)
		var text_pos := Vector2(box_rect.position.x + TEXT_PADDING, box_rect.position.y + TEXT_PADDING + FONT_SIZE)
		var max_width: float = box_rect.size.x - TEXT_PADDING * 2

		# Word-wrap the revealed text
		var words: PackedStringArray = revealed_text.split(" ")
		var line_text := ""
		var y_offset: float = 0.0
		for word in words:
			var test_line: String = line_text + (" " if line_text != "" else "") + word
			var test_size: Vector2 = ThemeDB.fallback_font.get_string_size(test_line, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE)
			if test_size.x > max_width and line_text != "":
				draw_string(ThemeDB.fallback_font, text_pos + Vector2(0, y_offset), line_text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, Color.WHITE)
				y_offset += FONT_SIZE + 2
				line_text = word
			else:
				line_text = test_line
		if line_text != "":
			draw_string(ThemeDB.fallback_font, text_pos + Vector2(0, y_offset), line_text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, Color.WHITE)

	# Page indicator (small triangle) when page is complete and more pages remain
	if _page_complete and _current_line < _lines.size() - 1:
		var arrow_x: float = box_rect.position.x + box_rect.size.x - TEXT_PADDING - 4
		var arrow_y: float = box_rect.position.y + box_rect.size.y - TEXT_PADDING
		var tri := PackedVector2Array([
			Vector2(arrow_x, arrow_y - 4),
			Vector2(arrow_x + 4, arrow_y - 4),
			Vector2(arrow_x + 2, arrow_y),
		])
		draw_colored_polygon(tri, Color(1.0, 1.0, 1.0, 0.7))
