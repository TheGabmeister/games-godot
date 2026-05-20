extends MenuScreen

var _selected_index := -1
var _formation_labels: Array[Label] = []

func _on_open() -> void:
	_selected_index = -1
	_show_formation()

func _get_item_count() -> int:
	return party_data.party.size()

func _on_confirm() -> void:
	if _selected_index < 0:
		_selected_index = _cursor_index
		SfxManager.play(confirm_sfx)
		_update_display()
	else:
		var temp: PartyData.CharacterData = party_data.party[_selected_index]
		party_data.party[_selected_index] = party_data.party[_cursor_index]
		party_data.party[_cursor_index] = temp
		_selected_index = -1
		SfxManager.play(confirm_sfx)
		_show_formation()

func _on_cancel() -> void:
	if _selected_index >= 0:
		_selected_index = -1
		SfxManager.play(cancel_sfx)
		_update_display()
	else:
		super()

func _update_display() -> void:
	for i: int in _formation_labels.size():
		var character: PartyData.CharacterData = party_data.party[i]
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

func _show_formation() -> void:
	_clear_panel()
	_formation_labels.clear()
	var panel := _get_panel()
	for i: int in party_data.party.size():
		var character: PartyData.CharacterData = party_data.party[i]
		var label := Label.new()
		label.text = "  %d. %s" % [i + 1, character.char_name]
		label.add_theme_font_size_override(&"font_size", 22)
		label.add_theme_color_override(&"font_color", Color(1.0, 1.0, 1.0))
		panel.add_child(label)
		_formation_labels.append(label)
	_update_display()
