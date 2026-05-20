class_name PartyMenu
extends CanvasLayer

signal closed

@export var cursor_move_sfx: AudioStream
@export var menu_open_sfx: AudioStream
@export var confirm_sfx: AudioStream
@export var cancel_sfx: AudioStream

enum Screen { MAIN, ITEMS, ITEMS_TARGET, MAGIC, EQUIPMENT, STATUS, STATUS_DETAIL, FORMATION, CONFIG }

var _active := false
var _main_cursor := 0
var _items_cursor := 0
var _status_cursor := 0
var _formation_cursor := 0
var _current_screen: Screen = Screen.MAIN
var party_data: PartyData

var _items: Array[ItemData] = []
var _item_labels: Array[GameButton] = []
var _item_target_index := 0
var _formation_selected_index := -1

@onready var _root: PanelContainer = %Panel
@onready var _time_label: Label = %TimeLabel
@onready var _gil_label: Label = %GilLabel

@onready var _cursor_labels: Array[GameButton] = [%Items, %Magic, %Equipment, %Status, %Formation, %Config]

@onready var _party_overview: VBoxContainer = %PartyOverview
@onready var _items_list: VBoxContainer = %ItemsList
@onready var _target_select: VBoxContainer = %TargetSelect
@onready var _status_select: VBoxContainer = %StatusSelect
@onready var _status_detail: VBoxContainer = %StatusDetail
@onready var _formation_list: VBoxContainer = %FormationList
@onready var _stub_panel: VBoxContainer = %StubPanel

@onready var _char_rows: Array[CharacterRow] = [%CharRow0, %CharRow1, %CharRow2, %CharRow3]

@onready var _target_labels: Array[GameButton] = [%Target0, %Target1, %Target2, %Target3]
@onready var _status_labels: Array[GameButton] = [%StatusChar0, %StatusChar1, %StatusChar2, %StatusChar3]

@onready var _detail_name: Label = %DetailName
@onready var _detail_level_value: Label = %LevelValue
@onready var _detail_hp_value: Label = %DetailHPValue
@onready var _stat_str: Label = %STRValue
@onready var _stat_agi: Label = %AGIValue
@onready var _stat_vit: Label = %VITValue
@onready var _stat_int: Label = %INTValue
@onready var _stat_lck: Label = %LCKValue

@onready var _formation_labels: Array[Label] = [%Formation0, %Formation1, %Formation2, %Formation3]
@onready var _stub_label: Label = %StubLabel

@onready var _screen_panels: Array[Control] = [
	_party_overview, _items_list, _target_select, _status_select,
	_status_detail, _formation_list, _stub_panel,
]

func _ready() -> void:
	add_to_group(Groups.PARTY_MENU)
	_root.visible = false
	var _err := GameState.state_changed.connect(_on_state_changed)

func open() -> void:
	_active = true
	_current_screen = Screen.MAIN
	_main_cursor = 0
	_root.visible = true
	_update_main_cursor()
	_show_party_overview()
	SfxManager.play(menu_open_sfx)

func _on_state_changed(_old_state: GameState.State, new_state: GameState.State) -> void:
	if new_state == GameState.State.MENU:
		open()
	elif _active:
		_close_menu()

func _close_menu() -> void:
	_active = false
	_root.visible = false
	closed.emit()

func _input(event: InputEvent) -> void:
	if not _active:
		return
	if not GameState.is_state(GameState.State.MENU):
		return

	match _current_screen:
		Screen.MAIN:
			_input_main(event)
		Screen.ITEMS:
			_input_items(event)
		Screen.ITEMS_TARGET:
			_input_items_target(event)
		Screen.STATUS:
			_input_status(event)
		Screen.STATUS_DETAIL:
			_input_status_detail(event)
		Screen.FORMATION:
			_input_formation(event)
		Screen.MAGIC, Screen.EQUIPMENT, Screen.CONFIG:
			_input_stub(event)

# --- Main screen ---

func _input_main(event: InputEvent) -> void:
	var prev := _main_cursor
	_main_cursor = _move_cursor(event, _main_cursor, _cursor_labels.size())
	if _main_cursor != prev:
		_update_main_cursor()
		SfxManager.play(cursor_move_sfx)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("confirm"):
		_open_submenu(_main_cursor)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("cancel") or event.is_action_pressed("menu"):
		SfxManager.play(cancel_sfx)
		GameState.transition(GameState.State.FIELD)
		get_viewport().set_input_as_handled()

func _update_main_cursor() -> void:
	for i: int in _cursor_labels.size():
		_cursor_labels[i].set_selected(i == _main_cursor)
	_time_label.text = "Time  " + party_data.get_play_time_string()
	_gil_label.text = "Gil   " + str(party_data.gil)

func _open_submenu(index: int) -> void:
	SfxManager.play(confirm_sfx)
	match index:
		0:
			_current_screen = Screen.ITEMS
			_items_cursor = 0
			_open_items()
		1:
			_current_screen = Screen.MAGIC
			_show_stub("Magic")
		2:
			_current_screen = Screen.EQUIPMENT
			_show_stub("Equipment")
		3:
			_current_screen = Screen.STATUS
			_status_cursor = 0
			_open_status_select()
		4:
			_current_screen = Screen.FORMATION
			_formation_cursor = 0
			_formation_selected_index = -1
			_open_formation()
		5:
			_current_screen = Screen.CONFIG
			_show_stub("Config")

func _return_to_main() -> void:
	_current_screen = Screen.MAIN
	_update_main_cursor()
	_show_party_overview()

# --- Party overview ---

func _show_party_overview() -> void:
	_switch_panel(_party_overview)
	for i: int in party_data.party.size():
		_char_rows[i].visible = true
		_char_rows[i].populate(party_data.party[i])
	for i: int in range(party_data.party.size(), 4):
		_char_rows[i].visible = false

# --- Items screen ---

func _open_items() -> void:
	_refresh_item_list()

func _input_items(event: InputEvent) -> void:
	var prev := _items_cursor
	_items_cursor = _move_cursor(event, _items_cursor, _items.size())
	if _items_cursor != prev:
		_update_items_cursor()
		SfxManager.play(cursor_move_sfx)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("confirm"):
		if not _items.is_empty():
			var item: ItemData = _items[_items_cursor]
			if item.effect_type == ItemData.EffectType.HEAL_HP:
				SfxManager.play(confirm_sfx)
				_current_screen = Screen.ITEMS_TARGET
				_item_target_index = 0
				_show_target_select()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("cancel"):
		SfxManager.play(cancel_sfx)
		_return_to_main()
		get_viewport().set_input_as_handled()

func _refresh_item_list() -> void:
	_switch_panel(_items_list)

	for child: Node in _items_list.get_children():
		child.queue_free()
	_item_labels.clear()
	_items.clear()

	for item: Variant in party_data.inventory:
		if item is ItemData:
			_items.append(item)

	if _items.is_empty():
		var label := Label.new()
		label.text = "No items"
		label.theme_type_variation = &"MutedLabel"
		_items_list.add_child(label)
		return

	for i: int in _items.size():
		var item: ItemData = _items[i]
		var qty: int = party_data.inventory[item]
		var btn := GameButton.new()
		btn.button_text = "%s          x%d" % [item.item_name, qty]
		_items_list.add_child(btn)
		_item_labels.append(btn)

	if _items_cursor >= _items.size():
		_items_cursor = maxi(_items.size() - 1, 0)
	_update_items_cursor()

func _update_items_cursor() -> void:
	for i: int in _item_labels.size():
		_item_labels[i].set_selected(i == _items_cursor)

# --- Items target select ---

func _show_target_select() -> void:
	_switch_panel(_target_select)
	_update_target_cursor()

func _input_items_target(event: InputEvent) -> void:
	var prev := _item_target_index
	_item_target_index = _move_cursor(event, _item_target_index, party_data.party.size())
	if _item_target_index != prev:
		_update_target_cursor()
		SfxManager.play(cursor_move_sfx)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("confirm"):
		var item: ItemData = _items[_items_cursor]
		var target: PartyData.CharacterData = party_data.party[_item_target_index]
		if party_data.use_item(item, target):
			SfxManager.play(confirm_sfx)
		_current_screen = Screen.ITEMS
		_refresh_item_list()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("cancel"):
		SfxManager.play(cancel_sfx)
		_current_screen = Screen.ITEMS
		_refresh_item_list()
		get_viewport().set_input_as_handled()

func _update_target_cursor() -> void:
	for i: int in party_data.party.size():
		var character: PartyData.CharacterData = party_data.party[i]
		_target_labels[i].button_text = "%s    HP %d / %d" % [character.char_name, character.current_hp, character.max_hp]
		_target_labels[i].set_selected(i == _item_target_index)

# --- Status screen ---

func _open_status_select() -> void:
	_switch_panel(_status_select)
	_update_status_cursor()

func _input_status(event: InputEvent) -> void:
	var prev := _status_cursor
	_status_cursor = _move_cursor(event, _status_cursor, party_data.party.size())
	if _status_cursor != prev:
		_update_status_cursor()
		SfxManager.play(cursor_move_sfx)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("confirm"):
		SfxManager.play(confirm_sfx)
		_current_screen = Screen.STATUS_DETAIL
		_show_status_detail(party_data.party[_status_cursor])
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("cancel"):
		SfxManager.play(cancel_sfx)
		_return_to_main()
		get_viewport().set_input_as_handled()

func _update_status_cursor() -> void:
	for i: int in party_data.party.size():
		var character: PartyData.CharacterData = party_data.party[i]
		_status_labels[i].button_text = character.char_name
		_status_labels[i].set_selected(i == _status_cursor)

func _input_status_detail(event: InputEvent) -> void:
	if event.is_action_pressed("cancel"):
		SfxManager.play(cancel_sfx)
		_current_screen = Screen.STATUS
		_open_status_select()
		get_viewport().set_input_as_handled()

func _show_status_detail(character: PartyData.CharacterData) -> void:
	_switch_panel(_status_detail)
	_detail_name.text = character.char_name
	_detail_level_value.text = str(character.level)
	_detail_hp_value.text = "%d / %d" % [character.current_hp, character.max_hp]
	_stat_str.text = "%3d" % character.strength
	_stat_agi.text = "%3d" % character.agility
	_stat_vit.text = "%3d" % character.vitality
	_stat_int.text = "%3d" % character.intelligence
	_stat_lck.text = "%3d" % character.luck

# --- Formation screen ---

func _open_formation() -> void:
	_switch_panel(_formation_list)
	_update_formation_display()

func _input_formation(event: InputEvent) -> void:
	var prev := _formation_cursor
	_formation_cursor = _move_cursor(event, _formation_cursor, party_data.party.size())
	if _formation_cursor != prev:
		_update_formation_display()
		SfxManager.play(cursor_move_sfx)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("confirm"):
		if _formation_selected_index < 0:
			_formation_selected_index = _formation_cursor
			SfxManager.play(confirm_sfx)
			_update_formation_display()
		else:
			var temp: PartyData.CharacterData = party_data.party[_formation_selected_index]
			party_data.party[_formation_selected_index] = party_data.party[_formation_cursor]
			party_data.party[_formation_cursor] = temp
			_formation_selected_index = -1
			SfxManager.play(confirm_sfx)
			_update_formation_display()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("cancel"):
		if _formation_selected_index >= 0:
			_formation_selected_index = -1
			SfxManager.play(cancel_sfx)
			_update_formation_display()
		else:
			SfxManager.play(cancel_sfx)
			_return_to_main()
		get_viewport().set_input_as_handled()

func _update_formation_display() -> void:
	for i: int in party_data.party.size():
		var character: PartyData.CharacterData = party_data.party[i]
		var prefix: String
		if i == _formation_cursor:
			prefix = "> "
		elif i == _formation_selected_index:
			prefix = "* "
		else:
			prefix = "  "
		_formation_labels[i].text = "%s%d. %s" % [prefix, i + 1, character.char_name]
		if i == _formation_selected_index:
			_formation_labels[i].add_theme_color_override(&"font_color", Color(1.0, 0.85, 0.4))
		else:
			_formation_labels[i].remove_theme_color_override(&"font_color")

# --- Stub screens ---

func _show_stub(title: String) -> void:
	_switch_panel(_stub_panel)
	_stub_label.text = title + " - Not yet available"

func _input_stub(event: InputEvent) -> void:
	if event.is_action_pressed("cancel"):
		SfxManager.play(cancel_sfx)
		_return_to_main()
		get_viewport().set_input_as_handled()

# --- Helpers ---

func _move_cursor(event: InputEvent, current: int, size: int) -> int:
	if size == 0:
		return current
	if event.is_action_pressed("move_up"):
		return (current - 1 + size) % size
	if event.is_action_pressed("move_down"):
		return (current + 1) % size
	return current

func _switch_panel(panel: Control) -> void:
	for p: Control in _screen_panels:
		p.visible = false
	panel.visible = true
