extends Control
## Game Over screen with Continue and Save & Quit options.

var _selected: int = 0  # 0=Continue, 1=Save & Quit
var _active: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	set_process_unhandled_input(false)


func show_game_over() -> void:
	_selected = 0
	_active = true
	visible = true
	set_process_unhandled_input(true)
	AudioManager.play_bgm(&"game_over")
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if not _active:
		return
	if event.is_action_pressed("move_up") or event.is_action_pressed("move_down"):
		_selected = 1 - _selected
		AudioManager.play_sfx(&"menu_move")
		queue_redraw()
	elif event.is_action_pressed("action_sword") or event.is_action_pressed("interact"):
		_active = false
		visible = false
		set_process_unhandled_input(false)
		AudioManager.play_sfx(&"menu_select")
		if _selected == 0:
			EventBus.game_over_continue.emit()
		else:
			EventBus.game_over_save_quit.emit()


func _draw() -> void:
	# Full screen dark overlay
	draw_rect(Rect2(0, 0, 256, 224), Color(0.0, 0.0, 0.0, 0.85))

	# "GAME OVER" text
	var center_x := 128.0
	_draw_text("GAME OVER", Vector2(center_x, 60), Color(0.9, 0.2, 0.2), 2.0)

	# Menu options
	var continue_color := Color.WHITE if _selected == 0 else Color(0.5, 0.5, 0.5)
	var quit_color := Color.WHITE if _selected == 1 else Color(0.5, 0.5, 0.5)

	_draw_text("Continue", Vector2(center_x, 120), continue_color, 1.0)
	_draw_text("Save and Quit", Vector2(center_x, 148), quit_color, 1.0)

	# Selection cursor
	var cursor_y := 120.0 if _selected == 0 else 148.0
	draw_colored_polygon(PackedVector2Array([
		Vector2(center_x - 55, cursor_y - 1),
		Vector2(center_x - 50, cursor_y + 3),
		Vector2(center_x - 55, cursor_y + 7),
	]), Color.WHITE)


func _draw_text(text: String, pos: Vector2, color: Color, scale: float) -> void:
	# Simple block-letter rendering for pixel art aesthetic
	var char_w := 5.0 * scale
	var char_h := 7.0 * scale
	var spacing := 1.0 * scale
	var total_w := text.length() * (char_w + spacing) - spacing
	var start_x := pos.x - total_w * 0.5
	for i in text.length():
		var c := text[i]
		if c == " ":
			continue
		var cx := start_x + i * (char_w + spacing)
		draw_rect(Rect2(cx, pos.y, char_w, char_h), color)
