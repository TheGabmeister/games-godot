extends Node

const CURSOR_MOVE := preload("res://ui/cursor_move.ogg")
const CONFIRM_SFX := preload("res://ui/confirm.ogg")
const CANCEL_SFX := preload("res://ui/cancel.ogg")

var _active := false
var _viewing_detail := false
var _cursor_index := 0
var _character_labels: Array[Label] = []

func _get_party_data() -> PartyData:
	return get_tree().get_first_node_in_group(Groups.PARTY_DATA) as PartyData

func open() -> void:
	_active = true
	_viewing_detail = false
	_cursor_index = 0
	_show_character_select()

func _input(event: InputEvent) -> void:
	if not _active:
		return
	if not GameState.is_state(GameState.State.MENU):
		return

	if _viewing_detail:
		if event.is_action_pressed("cancel"):
			SfxManager.play(CANCEL_SFX)
			_viewing_detail = false
			_show_character_select()
			get_viewport().set_input_as_handled()
		return

	var pd: PartyData = _get_party_data()
	if event.is_action_pressed("move_up"):
		_cursor_index = (_cursor_index - 1 + pd.party.size()) % pd.party.size()
		_update_cursor()
		SfxManager.play(CURSOR_MOVE)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("move_down"):
		_cursor_index = (_cursor_index + 1) % pd.party.size()
		_update_cursor()
		SfxManager.play(CURSOR_MOVE)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("confirm"):
		SfxManager.play(CONFIRM_SFX)
		_viewing_detail = true
		_show_detail(pd.party[_cursor_index])
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("cancel"):
		SfxManager.play(CANCEL_SFX)
		_close()
		get_viewport().set_input_as_handled()

func _show_character_select() -> void:
	var menu: Node = get_meta(&"menu")
	var panel: VBoxContainer = menu.call(&"get_right_panel")
	for child: Node in panel.get_children():
		child.queue_free()

	var pd: PartyData = _get_party_data()
	_character_labels.clear()
	for i: int in pd.party.size():
		var character: PartyData.CharacterData = pd.party[i]
		var label := Label.new()
		label.text = "  %s" % character.char_name
		label.add_theme_font_size_override(&"font_size", 22)
		label.add_theme_color_override(&"font_color", Color(1.0, 1.0, 1.0))
		panel.add_child(label)
		_character_labels.append(label)

	_update_cursor()

func _update_cursor() -> void:
	var pd: PartyData = _get_party_data()
	for i: int in _character_labels.size():
		var character: PartyData.CharacterData = pd.party[i]
		if i == _cursor_index:
			_character_labels[i].text = "> %s" % character.char_name
		else:
			_character_labels[i].text = "  %s" % character.char_name

func _show_detail(character: PartyData.CharacterData) -> void:
	var menu: Node = get_meta(&"menu")
	var panel: VBoxContainer = menu.call(&"get_right_panel")
	for child: Node in panel.get_children():
		child.queue_free()

	var title := Label.new()
	title.text = character.char_name
	title.add_theme_font_size_override(&"font_size", 24)
	title.add_theme_color_override(&"font_color", Color(1.0, 0.85, 0.4))
	panel.add_child(title)

	_add_stat_line(panel, "Level", str(character.level))
	_add_stat_line(panel, "HP", "%d / %d" % [character.current_hp, character.max_hp])

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 16)
	panel.add_child(spacer)

	var stat_grid := GridContainer.new()
	stat_grid.columns = 4
	stat_grid.add_theme_constant_override(&"h_separation", 24)
	stat_grid.add_theme_constant_override(&"v_separation", 8)

	_add_stat_pair(stat_grid, "STR", character.strength)
	_add_stat_pair(stat_grid, "AGI", character.agility)
	_add_stat_pair(stat_grid, "VIT", character.vitality)
	_add_stat_pair(stat_grid, "INT", character.intelligence)
	_add_stat_pair(stat_grid, "LCK", character.luck)

	panel.add_child(stat_grid)

func _add_stat_line(panel: VBoxContainer, label_text: String, value_text: String) -> void:
	var hbox := HBoxContainer.new()
	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(100, 0)
	label.add_theme_font_size_override(&"font_size", 22)
	label.add_theme_color_override(&"font_color", Color(0.8, 0.8, 1.0))
	hbox.add_child(label)

	var value := Label.new()
	value.text = value_text
	value.add_theme_font_size_override(&"font_size", 22)
	value.add_theme_color_override(&"font_color", Color(1.0, 1.0, 1.0))
	hbox.add_child(value)

	panel.add_child(hbox)

func _add_stat_pair(grid: GridContainer, stat_name: String, stat_value: int) -> void:
	var name_label := Label.new()
	name_label.text = stat_name
	name_label.add_theme_font_size_override(&"font_size", 20)
	name_label.add_theme_color_override(&"font_color", Color(0.8, 0.8, 1.0))
	grid.add_child(name_label)

	var value_label := Label.new()
	value_label.text = "%3d" % stat_value
	value_label.add_theme_font_size_override(&"font_size", 20)
	value_label.add_theme_color_override(&"font_color", Color(1.0, 1.0, 1.0))
	grid.add_child(value_label)

func _close() -> void:
	_active = false
	var menu: Node = get_meta(&"menu")
	menu.call(&"return_to_main")
