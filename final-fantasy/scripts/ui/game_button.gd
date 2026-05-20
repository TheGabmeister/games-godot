class_name GameButton
extends Label

var _selected := false

@export var button_text: String = "":
	set(value):
		button_text = value
		_update_display()

func set_selected(selected: bool) -> void:
	_selected = selected
	_update_display()

func _update_display() -> void:
	text = ("> " if _selected else "  ") + button_text
