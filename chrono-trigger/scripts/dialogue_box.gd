extends CanvasLayer

const CHARS_PER_SECOND := 30.0

@onready var panel: PanelContainer = $PanelContainer
@onready var name_label: Label = $PanelContainer/MarginContainer/VBoxContainer/NameLabel
@onready var text_label: Label = $PanelContainer/MarginContainer/VBoxContainer/TextLabel

var _lines: PackedStringArray
var _current_line_index := 0
var _visible_chars := 0.0
var _current_line_length := 0
var _typewriting := false

func _ready() -> void:
	add_to_group(Groups.DIALOGUE_BOX)
	panel.visible = false

func _process(delta: float) -> void:
	if GameState.current != GameState.State.DIALOGUE:
		return

	if _typewriting:
		_visible_chars += CHARS_PER_SECOND * delta
		var chars_to_show := int(_visible_chars)
		if chars_to_show >= _current_line_length:
			text_label.text = _lines[_current_line_index]
			_typewriting = false
		else:
			text_label.text = _lines[_current_line_index].substr(0, chars_to_show)

	if Input.is_action_just_pressed("interact"):
		if _typewriting:
			text_label.text = _lines[_current_line_index]
			_typewriting = false
		else:
			_advance()

func start(data: DialogueData) -> void:
	_lines = data.lines
	_current_line_index = 0
	name_label.text = data.speaker_name
	panel.visible = true
	GameState.change(GameState.State.DIALOGUE)
	_begin_line()

func _begin_line() -> void:
	_visible_chars = 0.0
	_current_line_length = _lines[_current_line_index].length()
	text_label.text = ""
	_typewriting = true

func _advance() -> void:
	_current_line_index += 1
	if _current_line_index >= _lines.size():
		_close()
	else:
		_begin_line()

func _close() -> void:
	panel.visible = false
	GameState.change(GameState.State.FIELD)
