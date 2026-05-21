class_name GameButton
extends Label

var _selected := false
var _marked := false
var _disabled := false

@export var button_text: String = "":
	set(value):
		button_text = value
		_update_display()

func set_selected(selected: bool) -> void:
	_selected = selected
	_update_display()

func set_marked(marked: bool) -> void:
	_marked = marked
	_update_display()

func set_disabled(disabled: bool) -> void:
	_disabled = disabled
	_update_display()

func _update_display() -> void:
	var prefix: String
	if _selected:
		prefix = "> "
	elif _marked:
		prefix = "* "
	else:
		prefix = "  "
	text = prefix + button_text
	if _disabled:
		modulate = Color(0.4, 0.4, 0.4, 1.0)
	elif _marked:
		add_theme_color_override(&"font_color", Color(1.0, 0.85, 0.4))
		modulate = Color.WHITE
	else:
		remove_theme_color_override(&"font_color")
		modulate = Color.WHITE
