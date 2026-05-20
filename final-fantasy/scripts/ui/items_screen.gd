extends MenuScreen

var _selecting_target := false
var _target_index := 0
var _item_labels: Array[Label] = []
var _target_labels: Array[Label] = []
var _items: Array[ItemData] = []

func _on_open() -> void:
	_selecting_target = false
	_refresh_item_list()

func _get_item_count() -> int:
	return _items.size()

func _handle_input(event: InputEvent) -> void:
	if _selecting_target:
		_handle_target_input(event)
	else:
		super(event)

func _on_confirm() -> void:
	if _items.is_empty():
		return
	var item: ItemData = _items[_cursor_index]
	if item.effect_type == ItemData.EffectType.HEAL_HP:
		SfxManager.play(confirm_sfx)
		_selecting_target = true
		_target_index = 0
		_show_target_select()

func _update_display() -> void:
	var pd: PartyData = party_data
	for i: int in _item_labels.size():
		var item: ItemData = _items[i]
		var qty: int = pd.inventory[item]
		if i == _cursor_index:
			_item_labels[i].text = "> %s          x%d" % [item.item_name, qty]
		else:
			_item_labels[i].text = "  %s          x%d" % [item.item_name, qty]

func _handle_target_input(event: InputEvent) -> void:
	if event.is_action_pressed("move_up"):
		_target_index = (_target_index - 1 + party_data.party.size()) % party_data.party.size()
		_update_target_cursor()
		SfxManager.play(cursor_move_sfx)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("move_down"):
		_target_index = (_target_index + 1) % party_data.party.size()
		_update_target_cursor()
		SfxManager.play(cursor_move_sfx)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("confirm"):
		var item: ItemData = _items[_cursor_index]
		var target: PartyData.CharacterData = party_data.party[_target_index]
		if party_data.use_item(item, target):
			SfxManager.play(confirm_sfx)
		_selecting_target = false
		_refresh_item_list()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("cancel"):
		SfxManager.play(cancel_sfx)
		_selecting_target = false
		_refresh_item_list()
		get_viewport().set_input_as_handled()

func _refresh_item_list() -> void:
	_clear_panel()
	_item_labels.clear()
	_items.clear()

	for item: Variant in party_data.inventory:
		if item is ItemData:
			_items.append(item)

	if _items.is_empty():
		var empty_label := Label.new()
		empty_label.text = "No items"
		empty_label.add_theme_font_size_override(&"font_size", 22)
		empty_label.add_theme_color_override(&"font_color", Color(0.6, 0.6, 0.8))
		_get_panel().add_child(empty_label)
		return

	var panel := _get_panel()
	for i: int in _items.size():
		var item: ItemData = _items[i]
		var qty: int = party_data.inventory[item]
		var label := Label.new()
		label.text = "  %s          x%d" % [item.item_name, qty]
		label.add_theme_font_size_override(&"font_size", 22)
		label.add_theme_color_override(&"font_color", Color(1.0, 1.0, 1.0))
		panel.add_child(label)
		_item_labels.append(label)

	if _cursor_index >= _items.size():
		_cursor_index = maxi(_items.size() - 1, 0)
	_update_display()

func _show_target_select() -> void:
	_clear_panel()
	_target_labels.clear()
	var panel := _get_panel()
	for i: int in party_data.party.size():
		var character: PartyData.CharacterData = party_data.party[i]
		var label := Label.new()
		label.text = "  %s    HP %d / %d" % [character.char_name, character.current_hp, character.max_hp]
		label.add_theme_font_size_override(&"font_size", 22)
		label.add_theme_color_override(&"font_color", Color(1.0, 1.0, 1.0))
		panel.add_child(label)
		_target_labels.append(label)
	_update_target_cursor()

func _update_target_cursor() -> void:
	for i: int in _target_labels.size():
		var character: PartyData.CharacterData = party_data.party[i]
		if i == _target_index:
			_target_labels[i].text = "> %s    HP %d / %d" % [character.char_name, character.current_hp, character.max_hp]
		else:
			_target_labels[i].text = "  %s    HP %d / %d" % [character.char_name, character.current_hp, character.max_hp]
