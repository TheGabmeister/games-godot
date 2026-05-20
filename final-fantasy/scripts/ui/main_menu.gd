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

enum Screen { MAIN, ITEMS, MAGIC, EQUIPMENT, STATUS, FORMATION, CONFIG }

var _active := false
var _cursor_index := 0
var _current_screen: Screen = Screen.MAIN

var _left_panel: VBoxContainer
var _right_panel: VBoxContainer
var _cursor_labels: Array[Label] = []
var _time_label: Label
var _gil_label: Label
var _root: PanelContainer

var party_data: PartyData

var _items_screen: Node
var _status_screen: Node
var _formation_screen: Node

func _ready() -> void:
	layer = 10
	add_to_group(Groups.MAIN_MENU)
	_build_ui()
	_root.visible = false

func open() -> void:
	_active = true
	_current_screen = Screen.MAIN
	_cursor_index = 0
	_root.visible = true
	_update_cursor()
	_show_party_overview()
	SfxManager.play(menu_open_sfx)

func close() -> void:
	_active = false
	_root.visible = false
	GameState.transition(GameState.State.FIELD)
	closed.emit()

func _input(event: InputEvent) -> void:
	if not _active:
		return
	if not GameState.is_state(GameState.State.MENU):
		return

	if _current_screen in [Screen.MAGIC, Screen.EQUIPMENT, Screen.CONFIG]:
		if event.is_action_pressed("cancel"):
			SfxManager.play(cancel_sfx)
			return_to_main()
			get_viewport().set_input_as_handled()
		return

	if _current_screen != Screen.MAIN:
		return

	if event.is_action_pressed("move_up"):
		_cursor_index = (_cursor_index - 1 + MENU_ENTRIES.size()) % MENU_ENTRIES.size()
		_update_cursor()
		SfxManager.play(cursor_move_sfx)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("move_down"):
		_cursor_index = (_cursor_index + 1) % MENU_ENTRIES.size()
		_update_cursor()
		SfxManager.play(cursor_move_sfx)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("confirm"):
		_open_submenu(_cursor_index)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("cancel") or event.is_action_pressed("menu"):
		SfxManager.play(cancel_sfx)
		close()
		get_viewport().set_input_as_handled()

func _open_submenu(index: int) -> void:
	SfxManager.play(confirm_sfx)
	match index:
		0:
			_current_screen = Screen.ITEMS
			_items_screen.call(&"open")
		1:
			_current_screen = Screen.MAGIC
			_show_stub("Magic")
		2:
			_current_screen = Screen.EQUIPMENT
			_show_stub("Equipment")
		3:
			_current_screen = Screen.STATUS
			_status_screen.call(&"open")
		4:
			_current_screen = Screen.FORMATION
			_formation_screen.call(&"open")
		5:
			_current_screen = Screen.CONFIG
			_show_stub("Config")

func return_to_main() -> void:
	_current_screen = Screen.MAIN
	_show_party_overview()

func _show_stub(title: String) -> void:
	_clear_right_panel()
	var label := Label.new()
	label.text = title + " - Not yet available"
	label.add_theme_font_size_override(&"font_size", 22)
	label.add_theme_color_override(&"font_color", Color(0.6, 0.6, 0.8))
	_right_panel.add_child(label)

func _update_cursor() -> void:
	for i: int in _cursor_labels.size():
		_cursor_labels[i].text = "> " + MENU_ENTRIES[i] if i == _cursor_index else "  " + MENU_ENTRIES[i]
	_time_label.text = "Time  " + party_data.get_play_time_string()
	_gil_label.text = "Gil   " + str(party_data.gil)

func _show_party_overview() -> void:
	_clear_right_panel()
	for character: PartyData.CharacterData in party_data.party:
		var row := _create_character_row(character)
		_right_panel.add_child(row)
		var sep := HSeparator.new()
		sep.add_theme_stylebox_override(&"separator", _create_separator_style())
		_right_panel.add_child(sep)

func _clear_right_panel() -> void:
	for child: Node in _right_panel.get_children():
		child.queue_free()

func get_right_panel() -> VBoxContainer:
	return _right_panel

func _create_character_row(character: PartyData.CharacterData) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(0, 100)
	row.add_theme_constant_override(&"separation", 16)

	var sprite_rect := TextureRect.new()
	var atlas := AtlasTexture.new()
	atlas.atlas = SPRITE_SHEETS[character.job]
	atlas.region = Rect2(0, 0, 64, 96)
	sprite_rect.texture = atlas
	sprite_rect.custom_minimum_size = Vector2(64, 96)
	sprite_rect.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	row.add_child(sprite_rect)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var name_hp := HBoxContainer.new()
	var name_label := Label.new()
	name_label.text = character.char_name
	name_label.add_theme_font_size_override(&"font_size", 22)
	name_label.add_theme_color_override(&"font_color", Color(1.0, 1.0, 1.0))
	name_label.custom_minimum_size = Vector2(180, 0)
	name_hp.add_child(name_label)

	var hp_label := Label.new()
	hp_label.text = "HP"
	hp_label.add_theme_font_size_override(&"font_size", 20)
	hp_label.add_theme_color_override(&"font_color", Color(1.0, 0.85, 0.4))
	name_hp.add_child(hp_label)

	var hp_val := Label.new()
	hp_val.text = "  %3d / %3d" % [character.current_hp, character.max_hp]
	hp_val.add_theme_font_size_override(&"font_size", 20)
	hp_val.add_theme_color_override(&"font_color", Color(1.0, 1.0, 1.0))
	name_hp.add_child(hp_val)
	info.add_child(name_hp)

	var mp_line := Label.new()
	mp_line.text = "MP  0 /  0 /  0 /  0"
	mp_line.add_theme_font_size_override(&"font_size", 18)
	mp_line.add_theme_color_override(&"font_color", Color(0.8, 0.8, 1.0))
	info.add_child(mp_line)

	var lv_line := HBoxContainer.new()
	var lv_label := Label.new()
	lv_label.text = "Lv. %d" % character.level
	lv_label.add_theme_font_size_override(&"font_size", 18)
	lv_label.add_theme_color_override(&"font_color", Color(1.0, 1.0, 1.0))
	lv_line.add_child(lv_label)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lv_line.add_child(spacer)

	var next_label := Label.new()
	next_label.text = "Next Level in   0"
	next_label.add_theme_font_size_override(&"font_size", 18)
	next_label.add_theme_color_override(&"font_color", Color(0.8, 0.8, 1.0))
	lv_line.add_child(next_label)
	info.add_child(lv_line)

	row.add_child(info)
	return row

func _create_separator_style() -> StyleBoxLine:
	var style := StyleBoxLine.new()
	style.color = Color(0.5, 0.5, 0.8, 0.5)
	style.thickness = 1
	return style

func _build_ui() -> void:
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.05, 0.05, 0.2, 0.95)
	panel_style.border_width_left = 3
	panel_style.border_width_top = 3
	panel_style.border_width_right = 3
	panel_style.border_width_bottom = 3
	panel_style.border_color = Color(0.8, 0.8, 1.0, 1.0)
	panel_style.corner_radius_top_left = 4
	panel_style.corner_radius_top_right = 4
	panel_style.corner_radius_bottom_right = 4
	panel_style.corner_radius_bottom_left = 4
	panel_style.content_margin_left = 16.0
	panel_style.content_margin_top = 12.0
	panel_style.content_margin_right = 16.0
	panel_style.content_margin_bottom = 12.0

	_root = PanelContainer.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.offset_left = 20.0
	_root.offset_top = 20.0
	_root.offset_right = -20.0
	_root.offset_bottom = -20.0
	_root.add_theme_stylebox_override(&"panel", panel_style)
	add_child(_root)

	var main_hbox := HBoxContainer.new()
	main_hbox.add_theme_constant_override(&"separation", 0)
	_root.add_child(main_hbox)

	var left_container := PanelContainer.new()
	var left_style: StyleBoxFlat = panel_style.duplicate()
	left_style.bg_color = Color(0.03, 0.03, 0.15, 0.95)
	left_container.add_theme_stylebox_override(&"panel", left_style)
	left_container.custom_minimum_size = Vector2(230, 0)
	main_hbox.add_child(left_container)

	_left_panel = VBoxContainer.new()
	_left_panel.add_theme_constant_override(&"separation", 4)
	left_container.add_child(_left_panel)

	for entry: StringName in MENU_ENTRIES:
		var label := Label.new()
		label.text = "  " + entry
		label.add_theme_font_size_override(&"font_size", 22)
		label.add_theme_color_override(&"font_color", Color(1.0, 1.0, 1.0))
		_left_panel.add_child(label)
		_cursor_labels.append(label)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_left_panel.add_child(spacer)

	_time_label = Label.new()
	_time_label.text = "Time  00:00"
	_time_label.add_theme_font_size_override(&"font_size", 20)
	_time_label.add_theme_color_override(&"font_color", Color(1.0, 1.0, 1.0))
	_left_panel.add_child(_time_label)

	_gil_label = Label.new()
	_gil_label.text = "Gil   0"
	_gil_label.add_theme_font_size_override(&"font_size", 20)
	_gil_label.add_theme_color_override(&"font_color", Color(1.0, 1.0, 1.0))
	_left_panel.add_child(_gil_label)

	var right_container := PanelContainer.new()
	var right_style: StyleBoxFlat = panel_style.duplicate()
	right_style.bg_color = Color(0.05, 0.05, 0.2, 0.0)
	right_style.border_width_left = 0
	right_style.border_width_top = 0
	right_style.border_width_right = 0
	right_style.border_width_bottom = 0
	right_container.add_theme_stylebox_override(&"panel", right_style)
	right_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_hbox.add_child(right_container)

	_right_panel = VBoxContainer.new()
	_right_panel.add_theme_constant_override(&"separation", 2)
	right_container.add_child(_right_panel)

	_items_screen = _create_screen(preload("res://scripts/ui/items_screen.gd"), "ItemsScreen")
	add_child(_items_screen)

	_status_screen = _create_screen(preload("res://scripts/ui/status_screen.gd"), "StatusScreen")
	add_child(_status_screen)

	_formation_screen = _create_screen(preload("res://scripts/ui/formation_screen.gd"), "FormationScreen")
	add_child(_formation_screen)

func _create_screen(script: GDScript, screen_name: String) -> MenuScreen:
	var screen: MenuScreen = script.new()
	screen.name = screen_name
	screen.menu = self
	screen.party_data = party_data
	screen.cursor_move_sfx = cursor_move_sfx
	screen.confirm_sfx = confirm_sfx
	screen.cancel_sfx = cancel_sfx
	return screen
