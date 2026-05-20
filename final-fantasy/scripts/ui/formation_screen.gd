extends Node

const CURSOR_MOVE := preload("res://ui/cursor_move.ogg")
const CONFIRM_SFX := preload("res://ui/confirm.ogg")
const CANCEL_SFX := preload("res://ui/cancel.ogg")

var _active := false
var _cursor_index := 0
var _selected_index := -1
var _formation_labels: Array[Label] = []

func open() -> void:
	_active = true
	_cursor_index = 0
	_selected_index = -1
	_show_formation()

func _input(event: InputEvent) -> void:
	if not _active:
		return
	if not GameState.is_state(GameState.State.MENU):
		return

	if event.is_action_pressed("move_up"):
		_cursor_index = (_cursor_index - 1 + PartyData.party.size()) % PartyData.party.size()
		_update_cursor()
		SfxManager.play(CURSOR_MOVE)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("move_down"):
		_cursor_index = (_cursor_index + 1) % PartyData.party.size()
		_update_cursor()
		SfxManager.play(CURSOR_MOVE)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("confirm"):
		if _selected_index < 0:
			_selected_index = _cursor_index
			SfxManager.play(CONFIRM_SFX)
			_update_cursor()
		else:
			var temp: PartyData.CharacterData = PartyData.party[_selected_index]
			PartyData.party[_selected_index] = PartyData.party[_cursor_index]
			PartyData.party[_cursor_index] = temp
			_selected_index = -1
			SfxManager.play(CONFIRM_SFX)
			_show_formation()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("cancel"):
		if _selected_index >= 0:
			_selected_index = -1
			SfxManager.play(CANCEL_SFX)
			_update_cursor()
		else:
			SfxManager.play(CANCEL_SFX)
			_close()
		get_viewport().set_input_as_handled()

func _show_formation() -> void:
	var menu: Node = get_meta(&"menu")
	var panel: VBoxContainer = menu.call(&"get_right_panel")
	for child: Node in panel.get_children():
		child.queue_free()

	_formation_labels.clear()
	for i: int in PartyData.party.size():
		var character: PartyData.CharacterData = PartyData.party[i]
		var label := Label.new()
		label.text = "  %d. %s" % [i + 1, character.char_name]
		label.add_theme_font_size_override(&"font_size", 22)
		label.add_theme_color_override(&"font_color", Color(1.0, 1.0, 1.0))
		panel.add_child(label)
		_formation_labels.append(label)

	_update_cursor()

func _update_cursor() -> void:
	for i: int in _formation_labels.size():
		var character: PartyData.CharacterData = PartyData.party[i]
		var prefix: String
		if i == _cursor_index:
			prefix = "> "
		elif i == _selected_index:
			prefix = "* "
		else:
			prefix = "  "
		_formation_labels[i].text = "%s%d. %s" % [prefix, i + 1, character.char_name]
		if i == _selected_index:
			_formation_labels[i].add_theme_color_override(&"font_color", Color(1.0, 0.85, 0.4))
		else:
			_formation_labels[i].add_theme_color_override(&"font_color", Color(1.0, 1.0, 1.0))

func _close() -> void:
	_active = false
	var menu: Node = get_meta(&"menu")
	menu.call(&"return_to_main")
