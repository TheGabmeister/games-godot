class_name DialogueBox
extends CanvasLayer

signal dialogue_finished

@onready var panel: PanelContainer = $Panel
@onready var name_label: Label = $Panel/MarginContainer/VBoxContainer/NameLabel
@onready var text_label: RichTextLabel = $Panel/MarginContainer/VBoxContainer/TextLabel
@onready var advance_indicator: Label = $Panel/MarginContainer/VBoxContainer/AdvanceIndicator

const CHAR_DELAY := 0.03

var _lines: Array[String] = []
var _current_line := 0
var _revealing := false
var _active := false
var _reveal_tween: Tween

func _ready() -> void:
	add_to_group(Groups.DIALOGUE_BOX)
	panel.visible = false
	advance_indicator.visible = false

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
	_kill_reveal_tween()
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
	_kill_reveal_tween()
	_revealing = true
	advance_indicator.visible = false
	text_label.text = _lines[_current_line]
	text_label.visible_ratio = 0.0
	var total_chars := text_label.get_total_character_count()
	if total_chars == 0:
		_finish_reveal()
		return
	_reveal_tween = create_tween()
	var _prop := _reveal_tween.tween_property(text_label, "visible_ratio", 1.0, total_chars * CHAR_DELAY)
	var _cb := _reveal_tween.tween_callback(_on_reveal_tween_finished)

func _on_reveal_tween_finished() -> void:
	_reveal_tween = null
	_finish_reveal(false)

func _finish_reveal(kill_tween := true) -> void:
	if kill_tween:
		_kill_reveal_tween()
	_revealing = false
	text_label.visible_ratio = 1.0
	advance_indicator.visible = true

func _advance() -> void:
	_current_line += 1
	if _current_line >= _lines.size():
		_close()
	else:
		_reveal_line()

func _close() -> void:
	_kill_reveal_tween()
	_active = false
	panel.visible = false
	GameState.transition(GameState.State.FIELD)
	dialogue_finished.emit()

func _kill_reveal_tween() -> void:
	if _reveal_tween != null:
		_reveal_tween.kill()
		_reveal_tween = null
