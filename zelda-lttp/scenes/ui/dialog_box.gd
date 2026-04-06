extends Control

## Simple dialog box that renders text from EventBus.dialog_requested.
## Sits on DialogLayer (CanvasLayer 15), process_mode ALWAYS.

var _lines: Array = []
var _current_line: int = 0

const BOX_MARGIN := 8.0
const BOX_HEIGHT := 40.0
const TEXT_PADDING := 6.0
const FONT_SIZE := 8


func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	EventBus.dialog_requested.connect(_on_dialog_requested)
	EventBus.dialog_closed.connect(_on_dialog_closed)


func _on_dialog_requested(lines: Array) -> void:
	_lines = lines
	_current_line = 0
	visible = true
	queue_redraw()


func _on_dialog_closed() -> void:
	visible = false
	_lines.clear()
	queue_redraw()


func _draw() -> void:
	if not visible or _lines.is_empty():
		return

	var box_y: float = size.y - BOX_HEIGHT - BOX_MARGIN
	var box_rect := Rect2(BOX_MARGIN, box_y, size.x - BOX_MARGIN * 2, BOX_HEIGHT)

	# Dark background
	draw_rect(box_rect, Color(0.05, 0.05, 0.12, 0.9))
	# Border
	draw_rect(box_rect, Color(0.7, 0.7, 0.7, 0.8), false, 1.0)

	# Text
	if _current_line < _lines.size():
		var text: String = str(_lines[_current_line])
		var text_pos := Vector2(box_rect.position.x + TEXT_PADDING, box_rect.position.y + TEXT_PADDING + FONT_SIZE)
		# Word-wrap manually for the small resolution
		var max_width: float = box_rect.size.x - TEXT_PADDING * 2
		var words: PackedStringArray = text.split(" ")
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
