class_name MainMenu
extends CanvasLayer

signal closed

@export var cursor_move_sfx: AudioStream
@export var menu_open_sfx: AudioStream
@export var confirm_sfx: AudioStream
@export var cancel_sfx: AudioStream

const SPRITE_SHEETS: Dictionary[PartyData.Job, Texture2D] = {
	PartyData.Job.WARRIOR:    preload("res://characters/warrior/warrior_sheet.png"),
	PartyData.Job.MONK:       preload("res://characters/monk/monk_sheet.png"),
	PartyData.Job.WHITE_MAGE: preload("res://characters/white_mage/white_mage_sheet.png"),
	PartyData.Job.BLACK_MAGE: preload("res://characters/black_mage/black_mage_sheet.png"),
}

const MENU_ENTRIES: Array[StringName] = [&"Items", &"Magic", &"Equipment", &"Status", &"Formation", &"Config"]

enum Screen { MAIN, ITEMS, ITEMS_TARGET, MAGIC, EQUIPMENT, STATUS, STATUS_DETAIL, FORMATION, CONFIG }

var _active := false
var _cursor_index := 0
var _current_screen: Screen = Screen.MAIN
var party_data: PartyData

var _items: Array[ItemData] = []
var _item_labels: Array[Label] = []
var _item_target_index := 0
var _formation_selected_index := -1

@onready var _root: PanelContainer = $Panel
@onready var _time_label: Label = $Panel/HBox/LeftPanel/VBox/TimeLabel
@onready var _gil_label: Label = $Panel/HBox/LeftPanel/VBox/GilLabel

@onready var _cursor_labels: Array[Label] = [
	$Panel/HBox/LeftPanel/VBox/MenuEntries/Items,
	$Panel/HBox/LeftPanel/VBox/MenuEntries/Magic,
	$Panel/HBox/LeftPanel/VBox/MenuEntries/Equipment,
	$Panel/HBox/LeftPanel/VBox/MenuEntries/Status,
	$Panel/HBox/LeftPanel/VBox/MenuEntries/Formation,
	$Panel/HBox/LeftPanel/VBox/MenuEntries/Config,
]

@onready var _party_overview: VBoxContainer = $Panel/HBox/RightPanel/Screens/PartyOverview
@onready var _items_list: VBoxContainer = $Panel/HBox/RightPanel/Screens/ItemsList
@onready var _target_select: VBoxContainer = $Panel/HBox/RightPanel/Screens/TargetSelect
@onready var _status_select: VBoxContainer = $Panel/HBox/RightPanel/Screens/StatusSelect
@onready var _status_detail: VBoxContainer = $Panel/HBox/RightPanel/Screens/StatusDetail
@onready var _formation_list: VBoxContainer = $Panel/HBox/RightPanel/Screens/FormationList
@onready var _stub_panel: VBoxContainer = $Panel/HBox/RightPanel/Screens/StubPanel

@onready var _char_rows: Array[HBoxContainer] = [
	$Panel/HBox/RightPanel/Screens/PartyOverview/CharRow0,
	$Panel/HBox/RightPanel/Screens/PartyOverview/CharRow1,
	$Panel/HBox/RightPanel/Screens/PartyOverview/CharRow2,
	$Panel/HBox/RightPanel/Screens/PartyOverview/CharRow3,
]

@onready var _target_labels: Array[Label] = [
	$Panel/HBox/RightPanel/Screens/TargetSelect/Target0,
	$Panel/HBox/RightPanel/Screens/TargetSelect/Target1,
	$Panel/HBox/RightPanel/Screens/TargetSelect/Target2,
	$Panel/HBox/RightPanel/Screens/TargetSelect/Target3,
]

@onready var _status_labels: Array[Label] = [
	$Panel/HBox/RightPanel/Screens/StatusSelect/StatusChar0,
	$Panel/HBox/RightPanel/Screens/StatusSelect/StatusChar1,
	$Panel/HBox/RightPanel/Screens/StatusSelect/StatusChar2,
	$Panel/HBox/RightPanel/Screens/StatusSelect/StatusChar3,
]

@onready var _formation_labels: Array[Label] = [
	$Panel/HBox/RightPanel/Screens/FormationList/Formation0,
	$Panel/HBox/RightPanel/Screens/FormationList/Formation1,
	$Panel/HBox/RightPanel/Screens/FormationList/Formation2,
	$Panel/HBox/RightPanel/Screens/FormationList/Formation3,
]

@onready var _stub_label: Label = $Panel/HBox/RightPanel/Screens/StubPanel/StubLabel

@onready var _screen_panels: Array[Control] = [
	_party_overview, _items_list, _target_select, _status_select,
	_status_detail, _formation_list, _stub_panel,
]

func _ready() -> void:
	add_to_group(Groups.MAIN_MENU)
	_root.visible = false
	var _err := GameState.state_changed.connect(_on_state_changed)

func open() -> void:
	_active = true
	_current_screen = Screen.MAIN
	_cursor_index = 0
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

# --- Input dispatch ---

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
	if event.is_action_pressed("move_up"):
		_cursor_index = (_cursor_index - 1 + MENU_ENTRIES.size()) % MENU_ENTRIES.size()
		_update_main_cursor()
		SfxManager.play(cursor_move_sfx)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("move_down"):
		_cursor_index = (_cursor_index + 1) % MENU_ENTRIES.size()
		_update_main_cursor()
		SfxManager.play(cursor_move_sfx)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("confirm"):
		_open_submenu(_cursor_index)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("cancel") or event.is_action_pressed("menu"):
		SfxManager.play(cancel_sfx)
		GameState.transition(GameState.State.FIELD)
		get_viewport().set_input_as_handled()

func _update_main_cursor() -> void:
	for i: int in _cursor_labels.size():
		_cursor_labels[i].text = "> " + MENU_ENTRIES[i] if i == _cursor_index else "  " + MENU_ENTRIES[i]
	_time_label.text = "Time  " + party_data.get_play_time_string()
	_gil_label.text = "Gil   " + str(party_data.gil)

func _open_submenu(index: int) -> void:
	SfxManager.play(confirm_sfx)
	match index:
		0:
			_current_screen = Screen.ITEMS
			_cursor_index = 0
			_open_items()
		1:
			_current_screen = Screen.MAGIC
			_show_stub("Magic")
		2:
			_current_screen = Screen.EQUIPMENT
			_show_stub("Equipment")
		3:
			_current_screen = Screen.STATUS
			_cursor_index = 0
			_open_status_select()
		4:
			_current_screen = Screen.FORMATION
			_cursor_index = 0
			_formation_selected_index = -1
			_open_formation()
		5:
			_current_screen = Screen.CONFIG
			_show_stub("Config")

func _return_to_main() -> void:
	_current_screen = Screen.MAIN
	_cursor_index = 0
	_update_main_cursor()
	_show_party_overview()

# --- Party overview ---

func _show_party_overview() -> void:
	_switch_panel(_party_overview)
	for i: int in party_data.party.size():
		var character: PartyData.CharacterData = party_data.party[i]
		var row: HBoxContainer = _char_rows[i]
		row.visible = true

		var portrait := row.get_node(^"Portrait") as TextureRect
		var atlas := AtlasTexture.new()
		atlas.atlas = SPRITE_SHEETS[character.job]
		atlas.region = Rect2(0, 0, 64, 96)
		portrait.texture = atlas

		(row.get_node(^"Info/NameHP/Name") as Label).text = character.char_name
		(row.get_node(^"Info/NameHP/HPValue") as Label).text = "  %3d / %3d" % [character.current_hp, character.max_hp]
		(row.get_node(^"Info/MPLine") as Label).text = "MP  0 /  0 /  0 /  0"
		(row.get_node(^"Info/LvLine/LvLabel") as Label).text = "Lv. %d" % character.level
		(row.get_node(^"Info/LvLine/NextLabel") as Label).text = "Next Level in   0"

	for i: int in range(party_data.party.size(), 4):
		_char_rows[i].visible = false

# --- Items screen ---

func _open_items() -> void:
	_refresh_item_list()

func _input_items(event: InputEvent) -> void:
	if event.is_action_pressed("move_up"):
		if not _items.is_empty():
			_cursor_index = (_cursor_index - 1 + _items.size()) % _items.size()
			_update_items_cursor()
			SfxManager.play(cursor_move_sfx)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("move_down"):
		if not _items.is_empty():
			_cursor_index = (_cursor_index + 1) % _items.size()
			_update_items_cursor()
			SfxManager.play(cursor_move_sfx)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("confirm"):
		if not _items.is_empty():
			var item: ItemData = _items[_cursor_index]
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
		var label := Label.new()
		label.text = "  %s          x%d" % [item.item_name, qty]
		_items_list.add_child(label)
		_item_labels.append(label)

	if _cursor_index >= _items.size():
		_cursor_index = maxi(_items.size() - 1, 0)
	_update_items_cursor()

func _update_items_cursor() -> void:
	for i: int in _item_labels.size():
		var item: ItemData = _items[i]
		var qty: int = party_data.inventory[item]
		if i == _cursor_index:
			_item_labels[i].text = "> %s          x%d" % [item.item_name, qty]
		else:
			_item_labels[i].text = "  %s          x%d" % [item.item_name, qty]

# --- Items target select ---

func _show_target_select() -> void:
	_switch_panel(_target_select)
	_update_target_cursor()

func _input_items_target(event: InputEvent) -> void:
	if event.is_action_pressed("move_up"):
		_item_target_index = (_item_target_index - 1 + party_data.party.size()) % party_data.party.size()
		_update_target_cursor()
		SfxManager.play(cursor_move_sfx)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("move_down"):
		_item_target_index = (_item_target_index + 1) % party_data.party.size()
		_update_target_cursor()
		SfxManager.play(cursor_move_sfx)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("confirm"):
		var item: ItemData = _items[_cursor_index]
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
		if i == _item_target_index:
			_target_labels[i].text = "> %s    HP %d / %d" % [character.char_name, character.current_hp, character.max_hp]
		else:
			_target_labels[i].text = "  %s    HP %d / %d" % [character.char_name, character.current_hp, character.max_hp]

# --- Status screen ---

func _open_status_select() -> void:
	_switch_panel(_status_select)
	_update_status_cursor()

func _input_status(event: InputEvent) -> void:
	if event.is_action_pressed("move_up"):
		_cursor_index = (_cursor_index - 1 + party_data.party.size()) % party_data.party.size()
		_update_status_cursor()
		SfxManager.play(cursor_move_sfx)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("move_down"):
		_cursor_index = (_cursor_index + 1) % party_data.party.size()
		_update_status_cursor()
		SfxManager.play(cursor_move_sfx)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("confirm"):
		SfxManager.play(confirm_sfx)
		_current_screen = Screen.STATUS_DETAIL
		_show_status_detail(party_data.party[_cursor_index])
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("cancel"):
		SfxManager.play(cancel_sfx)
		_return_to_main()
		get_viewport().set_input_as_handled()

func _update_status_cursor() -> void:
	for i: int in party_data.party.size():
		var character: PartyData.CharacterData = party_data.party[i]
		if i == _cursor_index:
			_status_labels[i].text = "> %s" % character.char_name
		else:
			_status_labels[i].text = "  %s" % character.char_name

func _input_status_detail(event: InputEvent) -> void:
	if event.is_action_pressed("cancel"):
		SfxManager.play(cancel_sfx)
		_current_screen = Screen.STATUS
		_open_status_select()
		get_viewport().set_input_as_handled()

func _show_status_detail(character: PartyData.CharacterData) -> void:
	_switch_panel(_status_detail)
	(_status_detail.get_node(^"DetailName") as Label).text = character.char_name
	(_status_detail.get_node(^"DetailLevelLine/LevelValue") as Label).text = str(character.level)
	(_status_detail.get_node(^"DetailHPLine/HPValue") as Label).text = "%d / %d" % [character.current_hp, character.max_hp]
	var grid := _status_detail.get_node(^"StatGrid") as GridContainer
	(grid.get_node(^"STRValue") as Label).text = "%3d" % character.strength
	(grid.get_node(^"AGIValue") as Label).text = "%3d" % character.agility
	(grid.get_node(^"VITValue") as Label).text = "%3d" % character.vitality
	(grid.get_node(^"INTValue") as Label).text = "%3d" % character.intelligence
	(grid.get_node(^"LCKValue") as Label).text = "%3d" % character.luck

# --- Formation screen ---

func _open_formation() -> void:
	_switch_panel(_formation_list)
	_update_formation_display()

func _input_formation(event: InputEvent) -> void:
	if event.is_action_pressed("move_up"):
		_cursor_index = (_cursor_index - 1 + party_data.party.size()) % party_data.party.size()
		_update_formation_display()
		SfxManager.play(cursor_move_sfx)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("move_down"):
		_cursor_index = (_cursor_index + 1) % party_data.party.size()
		_update_formation_display()
		SfxManager.play(cursor_move_sfx)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("confirm"):
		if _formation_selected_index < 0:
			_formation_selected_index = _cursor_index
			SfxManager.play(confirm_sfx)
			_update_formation_display()
		else:
			var temp: PartyData.CharacterData = party_data.party[_formation_selected_index]
			party_data.party[_formation_selected_index] = party_data.party[_cursor_index]
			party_data.party[_cursor_index] = temp
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
		if i == _cursor_index:
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

# --- Panel switching ---

func _switch_panel(panel: Control) -> void:
	for p: Control in _screen_panels:
		p.visible = false
	panel.visible = true
