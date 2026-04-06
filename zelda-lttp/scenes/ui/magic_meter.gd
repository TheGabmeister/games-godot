extends Control

var _current_magic: int = 0
var _max_magic: int = 128

const BAR_WIDTH := 4.0
const BAR_HEIGHT := 32.0
const BORDER_COLOR := Color(0.6, 0.6, 0.6, 0.8)
const FILL_COLOR := Color(0.2, 0.8, 0.3)
const BG_COLOR := Color(0.1, 0.1, 0.1, 0.6)


func _ready() -> void:
	custom_minimum_size = Vector2(BAR_WIDTH + 4, BAR_HEIGHT + 4)
	EventBus.player_magic_changed.connect(_on_magic_changed)


func update_magic(current: int, max_magic: int) -> void:
	_current_magic = current
	_max_magic = max_magic
	queue_redraw()


func _on_magic_changed(current: int, max_magic: int) -> void:
	update_magic(current, max_magic)


func _draw() -> void:
	if _max_magic <= 0:
		return

	var x: float = 2.0
	var y: float = 2.0

	# Background
	draw_rect(Rect2(x, y, BAR_WIDTH, BAR_HEIGHT), BG_COLOR)

	# Fill from bottom up
	var fill_ratio: float = float(_current_magic) / float(_max_magic)
	var fill_height: float = BAR_HEIGHT * fill_ratio
	draw_rect(Rect2(x, y + BAR_HEIGHT - fill_height, BAR_WIDTH, fill_height), FILL_COLOR)

	# Border
	draw_rect(Rect2(x, y, BAR_WIDTH, BAR_HEIGHT), BORDER_COLOR, false, 1.0)
