class_name DialogueBox
extends CanvasLayer

signal dialogue_finished

@onready var panel: PanelContainer = $Panel
@onready var name_label: Label = $Panel/MarginContainer/VBoxContainer/NameLabel
@onready var text_label: RichTextLabel = $Panel/MarginContainer/VBoxContainer/TextLabel
@onready var advance_indicator: Label = $Panel/MarginContainer/VBoxContainer/AdvanceIndicator

const CHAR_DELAY := 0.03
const TEXT_TICK := preload("res://ui/text_tick.ogg")
const TEXT_ADVANCE := preload("res://ui/text_advance.ogg")
const TICK_VOLUME := -10.0

var _lines: Array[String] = []
var _current_line := 0
var _revealing := false
var _active := false
var _char_timer := 0.0
var _chars_shown := 0

func _ready() -> void:
	add_to_group(Groups.DIALOGUE_BOX)
	panel.visible = false
	advance_indicator.visible = false

func _process(delta: float) -> void:
	if not _revealing:
		return
	_char_timer -= delta
	if _char_timer <= 0.0:
		_char_timer += CHAR_DELAY
		_chars_shown += 1
		text_label.visible_characters = _chars_shown
		if _chars_shown >= text_label.get_total_character_count():
			_finish_reveal()
		else:
			SfxManager.play(TEXT_TICK, TICK_VOLUME)

func _input(event: InputEvent) -> void:
	if not _active:
		return
	if event.is_action_pressed("confirm"):
		if _revealing:
			_finish_reveal()
		else:
			_advance()
		get_viewport().set_input_as_handled()

func start(npc_name: String, lines: Array[String]) -> void:
	_lines = lines.duplicate()
	if _lines.is_empty():
		_lines = ["..."]
	_current_line = 0
	_active = true
	name_label.text = npc_name
	panel.visible = true
	advance_indicator.visible = false
	_reveal_line()

func _reveal_line() -> void:
	_revealing = true
	_chars_shown = 0
	_char_timer = 0.0
	advance_indicator.visible = false
	text_label.text = _lines[_current_line]
	text_label.visible_characters = 0
	if text_label.get_total_character_count() == 0:
		_finish_reveal()

func _finish_reveal() -> void:
	_revealing = false
	text_label.visible_characters = -1
	advance_indicator.visible = true

func _advance() -> void:
	SfxManager.play(TEXT_ADVANCE)
	_current_line += 1
	if _current_line >= _lines.size():
		_close()
	else:
		_reveal_line()

func _close() -> void:
	_active = false
	_revealing = false
	panel.visible = false
	GameState.transition(GameState.State.FIELD)
	dialogue_finished.emit()
