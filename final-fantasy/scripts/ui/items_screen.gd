extends Node

const CURSOR_MOVE := preload("res://ui/cursor_move.ogg")
const CONFIRM_SFX := preload("res://ui/confirm.ogg")
const CANCEL_SFX := preload("res://ui/cancel.ogg")

var party_data: PartyData

var _active := false
var _selecting_target := false
var _cursor_index := 0
var _target_index := 0
var _item_labels: Array[Label] = []
var _target_labels: Array[Label] = []
var _items: Array[ItemData] = []

func open() -> void:
	_active = true
	_selecting_target = false
	_cursor_index = 0
	_refresh_item_list()

func _input(event: InputEvent) -> void:
	if not _active:
		return
	if not GameState.is_state(GameState.State.MENU):
		return

	if _selecting_target:
		_handle_target_input(event)
	else:
		_handle_list_input(event)

func _handle_list_input(event: InputEvent) -> void:
	if _items.is_empty():
		if event.is_action_pressed("cancel"):
			SfxManager.play(CANCEL_SFX)
			_close()
			get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("move_up"):
		_cursor_index = (_cursor_index - 1 + _items.size()) % _items.size()
		_update_item_cursor()
		SfxManager.play(CURSOR_MOVE)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("move_down"):
		_cursor_index = (_cursor_index + 1) % _items.size()
		_update_item_cursor()
		SfxManager.play(CURSOR_MOVE)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("confirm"):
		var item: ItemData = _items[_cursor_index]
		if item.effect_type == ItemData.EffectType.HEAL_HP:
			SfxManager.play(CONFIRM_SFX)
			_selecting_target = true
			_target_index = 0
			_show_target_select()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("cancel"):
		SfxManager.play(CANCEL_SFX)
		_close()
		get_viewport().set_input_as_handled()

func _handle_target_input(event: InputEvent) -> void:
	if event.is_action_pressed("move_up"):
		_target_index = (_target_index - 1 + party_data.party.size()) % party_data.party.size()
		_update_target_cursor()
		SfxManager.play(CURSOR_MOVE)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("move_down"):
		_target_index = (_target_index + 1) % party_data.party.size()
		_update_target_cursor()
		SfxManager.play(CURSOR_MOVE)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("confirm"):
		var item: ItemData = _items[_cursor_index]
		var target: PartyData.CharacterData = party_data.party[_target_index]
		if party_data.use_item(item, target):
			SfxManager.play(CONFIRM_SFX)
		_selecting_target = false
		_refresh_item_list()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("cancel"):
		SfxManager.play(CANCEL_SFX)
		_selecting_target = false
		_refresh_item_list()
		get_viewport().set_input_as_handled()

func _refresh_item_list() -> void:
	var menu: Node = get_meta(&"menu")
	var panel: VBoxContainer = menu.call(&"get_right_panel")
	for child: Node in panel.get_children():
		child.queue_free()

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
		panel.add_child(empty_label)
		return

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
	_update_item_cursor()

func _update_item_cursor() -> void:
	for i: int in _item_labels.size():
		var item: ItemData = _items[i]
		var qty: int = party_data.inventory[item]
		if i == _cursor_index:
			_item_labels[i].text = "> %s          x%d" % [item.item_name, qty]
		else:
			_item_labels[i].text = "  %s          x%d" % [item.item_name, qty]

func _show_target_select() -> void:
	var menu: Node = get_meta(&"menu")
	var panel: VBoxContainer = menu.call(&"get_right_panel")
	for child: Node in panel.get_children():
		child.queue_free()

	_target_labels.clear()
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

func _close() -> void:
	_active = false
	var menu: Node = get_meta(&"menu")
	menu.call(&"return_to_main")
