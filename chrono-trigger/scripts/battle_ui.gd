extends CanvasLayer

enum MenuState { HIDDEN, COMMAND, ITEM_LIST, TARGET_ENEMY, TARGET_ALLY }

@export var battle_manager_path: NodePath

var _menu_state: MenuState = MenuState.HIDDEN
var _active_member_index := -1
var _command_cursor := 0
var _target_cursor := 0
var _item_cursor := 0
var _living_enemies: Array = []
var _items: Array = []
var _selected_item: ItemData = null

var _party_rows: Array = []
var _enemy_bars: Array = []
var _battle_panel: PanelContainer
var _command_menu: PanelContainer
var _command_labels: Array = []
var _target_label: Label
var _results_label: Label
var _game_over_label: Label
var _escape_label: Label
var _root: Control

func _ready() -> void:
	_build_ui()
	_root.visible = false

	var bm := get_node(battle_manager_path)
	bm.battle_started.connect(_on_battle_started)
	bm.battle_ended.connect(_on_battle_ended)
	bm.atb_updated.connect(_on_atb_updated)
	bm.command_ready_changed.connect(_on_command_ready_changed)
	bm.party_hp_changed.connect(_on_party_hp_changed)
	bm.enemy_hp_changed.connect(_on_enemy_hp_changed)
	bm.damage_dealt.connect(_on_damage_dealt)
	bm.heal_applied.connect(_on_heal_applied)
	bm.victory_achieved.connect(_on_victory_achieved)
	bm.player_defeated.connect(_on_player_defeated)
	bm.enemy_died.connect(_on_enemy_died)
	bm.combatant_ko.connect(_on_combatant_ko)
	bm.active_member_changed.connect(_on_active_member_changed)
	bm.escaped.connect(_on_escaped)

func _build_ui() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_root)

	_battle_panel = PanelContainer.new()
	_battle_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_battle_panel.offset_top = -160
	_root.add_child(_battle_panel)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_bottom", 8)
	_battle_panel.add_child(margin)

	var vbox := VBoxContainer.new()
	margin.add_child(vbox)

	for i in 3:
		var row := _create_party_row()
		vbox.add_child(row["container"])
		_party_rows.append(row)

	var separator := HSeparator.new()
	vbox.add_child(separator)

	var enemy_row := HBoxContainer.new()
	enemy_row.add_theme_constant_override("separation", 16)
	vbox.add_child(enemy_row)
	for i in 4:
		var bar := _create_enemy_bar()
		enemy_row.add_child(bar["container"])
		bar["container"].visible = false
		_enemy_bars.append(bar)

	_command_menu = PanelContainer.new()
	_command_menu.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_command_menu.offset_left = -170
	_command_menu.offset_top = -270
	_command_menu.offset_right = -20
	_command_menu.offset_bottom = -170
	_command_menu.visible = false
	_root.add_child(_command_menu)

	var cmd_margin := MarginContainer.new()
	cmd_margin.add_theme_constant_override("margin_left", 14)
	cmd_margin.add_theme_constant_override("margin_top", 10)
	cmd_margin.add_theme_constant_override("margin_right", 14)
	cmd_margin.add_theme_constant_override("margin_bottom", 10)
	_command_menu.add_child(cmd_margin)

	var cmd_vbox := VBoxContainer.new()
	cmd_margin.add_child(cmd_vbox)

	for text in ["Attack", "Item"]:
		var lbl := Label.new()
		lbl.text = text
		lbl.add_theme_font_size_override("font_size", 20)
		cmd_vbox.add_child(lbl)
		_command_labels.append(lbl)

	_target_label = Label.new()
	_target_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_target_label.offset_top = 20
	_target_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_target_label.add_theme_font_size_override("font_size", 20)
	_target_label.visible = false
	_root.add_child(_target_label)

	_results_label = Label.new()
	_results_label.set_anchors_preset(Control.PRESET_CENTER)
	_results_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_results_label.add_theme_font_size_override("font_size", 24)
	_results_label.visible = false
	_root.add_child(_results_label)

	_game_over_label = Label.new()
	_game_over_label.set_anchors_preset(Control.PRESET_CENTER)
	_game_over_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_game_over_label.add_theme_font_size_override("font_size", 32)
	_game_over_label.text = "Game Over"
	_game_over_label.visible = false
	_root.add_child(_game_over_label)

	_escape_label = Label.new()
	_escape_label.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_escape_label.offset_top = -180
	_escape_label.offset_left = 16
	_escape_label.add_theme_font_size_override("font_size", 18)
	_escape_label.text = "Escaping..."
	_escape_label.visible = false
	_root.add_child(_escape_label)

func _create_party_row() -> Dictionary:
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)

	var marker := Label.new()
	marker.text = " "
	marker.custom_minimum_size = Vector2(20, 0)
	marker.add_theme_font_size_override("font_size", 16)
	hbox.add_child(marker)

	var name_lbl := Label.new()
	name_lbl.custom_minimum_size = Vector2(80, 0)
	name_lbl.add_theme_font_size_override("font_size", 16)
	hbox.add_child(name_lbl)

	var hp_lbl := Label.new()
	hp_lbl.custom_minimum_size = Vector2(120, 0)
	hp_lbl.add_theme_font_size_override("font_size", 16)
	hbox.add_child(hp_lbl)

	var hp_bar := ProgressBar.new()
	hp_bar.custom_minimum_size = Vector2(150, 18)
	hp_bar.show_percentage = false
	hbox.add_child(hp_bar)

	var atb_lbl := Label.new()
	atb_lbl.text = "ATB"
	atb_lbl.add_theme_font_size_override("font_size", 14)
	hbox.add_child(atb_lbl)

	var atb_bar := ProgressBar.new()
	atb_bar.custom_minimum_size = Vector2(120, 18)
	atb_bar.show_percentage = false
	hbox.add_child(atb_bar)

	return {
		"container": hbox,
		"marker": marker,
		"name": name_lbl,
		"hp_label": hp_lbl,
		"hp_bar": hp_bar,
		"atb_bar": atb_bar,
	}

func _create_enemy_bar() -> Dictionary:
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 4)

	var name_lbl := Label.new()
	name_lbl.add_theme_font_size_override("font_size", 14)
	hbox.add_child(name_lbl)

	var hp_bar := ProgressBar.new()
	hp_bar.custom_minimum_size = Vector2(100, 16)
	hp_bar.show_percentage = false
	hbox.add_child(hp_bar)

	return { "container": hbox, "name": name_lbl, "hp_bar": hp_bar }

func _process(_delta: float) -> void:
	if GameState.current != GameState.State.BATTLE:
		return

	_escape_label.visible = Input.is_action_pressed("escape_left") and Input.is_action_pressed("escape_right")

	if _menu_state == MenuState.HIDDEN:
		return

	if _menu_state == MenuState.COMMAND:
		if Input.is_action_just_pressed("move_up"):
			_command_cursor = max(0, _command_cursor - 1)
			_update_command_cursor()
		elif Input.is_action_just_pressed("move_down"):
			_command_cursor = min(1, _command_cursor + 1)
			_update_command_cursor()
		elif Input.is_action_just_pressed("interact"):
			if _command_cursor == 0:
				_enter_target_enemy()
			elif _command_cursor == 1:
				_enter_item_list()

	elif _menu_state == MenuState.TARGET_ENEMY:
		if Input.is_action_just_pressed("move_left"):
			_cycle_enemy_target(-1)
		elif Input.is_action_just_pressed("move_right"):
			_cycle_enemy_target(1)
		elif Input.is_action_just_pressed("interact"):
			_confirm_attack()
		elif Input.is_action_just_pressed("cancel"):
			_return_to_command()

	elif _menu_state == MenuState.ITEM_LIST:
		if Input.is_action_just_pressed("move_up"):
			_item_cursor = max(0, _item_cursor - 1)
			_update_item_display()
		elif Input.is_action_just_pressed("move_down"):
			_item_cursor = min(_items.size() - 1, _item_cursor + 1)
			_update_item_display()
		elif Input.is_action_just_pressed("interact"):
			if _items.size() > 0:
				_selected_item = _items[_item_cursor]["item"]
				_enter_target_ally()
		elif Input.is_action_just_pressed("cancel"):
			_return_to_command()

	elif _menu_state == MenuState.TARGET_ALLY:
		if Input.is_action_just_pressed("move_up"):
			_cycle_ally_target(-1)
		elif Input.is_action_just_pressed("move_down"):
			_cycle_ally_target(1)
		elif Input.is_action_just_pressed("interact"):
			_confirm_item()
		elif Input.is_action_just_pressed("cancel"):
			_enter_item_list()

func _enter_target_enemy() -> void:
	var bm := get_node(battle_manager_path)
	_living_enemies = bm.get_living_enemies()
	if _living_enemies.is_empty():
		return
	if _living_enemies.size() == 1:
		_target_cursor = 0
		_confirm_attack()
		return
	_target_cursor = 0
	_menu_state = MenuState.TARGET_ENEMY
	_command_menu.visible = false
	_target_label.visible = true
	_update_enemy_target_display()
	bm.set_in_submenu(true)

func _enter_item_list() -> void:
	var bm := get_node(battle_manager_path)
	var inventory := get_tree().get_first_node_in_group(Groups.INVENTORY)
	if inventory == null:
		return
	_items = inventory.get_all_items()
	if _items.is_empty():
		return
	_item_cursor = 0
	_menu_state = MenuState.ITEM_LIST
	_update_item_display()
	bm.set_in_submenu(true)

func _enter_target_ally() -> void:
	_target_cursor = 0
	_menu_state = MenuState.TARGET_ALLY
	_command_menu.visible = false
	_update_ally_target_display()

func _return_to_command() -> void:
	var bm := get_node(battle_manager_path)
	bm.set_in_submenu(false)
	_menu_state = MenuState.COMMAND
	_command_menu.visible = true
	_target_label.visible = false
	_command_cursor = 0
	_update_command_cursor()
	_clear_row_cursors()

func _confirm_attack() -> void:
	var bm := get_node(battle_manager_path)
	if bm._animating:
		return
	bm.set_in_submenu(false)
	_menu_state = MenuState.HIDDEN
	_command_menu.visible = false
	_target_label.visible = false
	var enemy_idx: int = _living_enemies[_target_cursor]
	bm._on_attack_selected(enemy_idx)

func _confirm_item() -> void:
	var bm := get_node(battle_manager_path)
	if bm._animating:
		return
	bm.set_in_submenu(false)
	_menu_state = MenuState.HIDDEN
	_command_menu.visible = false
	_clear_row_cursors()
	bm._on_item_used(_selected_item, _target_cursor)

func _cycle_enemy_target(dir: int) -> void:
	_target_cursor = (_target_cursor + dir) % _living_enemies.size()
	if _target_cursor < 0:
		_target_cursor += _living_enemies.size()
	_update_enemy_target_display()

func _cycle_ally_target(dir: int) -> void:
	var size := _party_rows.size()
	_target_cursor = (_target_cursor + dir) % size
	if _target_cursor < 0:
		_target_cursor += size
	_update_ally_target_display()

func _update_command_cursor() -> void:
	for i in _command_labels.size():
		_command_labels[i].text = ("> " if i == _command_cursor else "  ") + ["Attack", "Item"][i]

func _update_enemy_target_display() -> void:
	var bm := get_node(battle_manager_path)
	var enemy_idx: int = _living_enemies[_target_cursor]
	var node: Node2D = bm.get_enemy_node(enemy_idx)
	if node:
		_target_label.text = "▼ " + str(node.data.get("enemy_name"))
		var screen_pos := get_viewport().get_canvas_transform() * node.global_position
		_target_label.position = screen_pos - Vector2(40, 50)

func _update_item_display() -> void:
	var window_size := _command_labels.size()
	var start := clampi(_item_cursor - window_size + 1, 0, maxi(0, _items.size() - window_size))
	for i in window_size:
		var item_idx := start + i
		if item_idx < _items.size():
			var prefix := "> " if item_idx == _item_cursor else "  "
			_command_labels[i].text = prefix + _items[item_idx]["item"].item_name + " " + str(_items[item_idx]["count"])
			_command_labels[i].visible = true
		else:
			_command_labels[i].text = ""
			_command_labels[i].visible = false

func _update_ally_target_display() -> void:
	_clear_row_cursors()
	if _target_cursor >= 0 and _target_cursor < _party_rows.size():
		_party_rows[_target_cursor]["marker"].text = ">"

func _clear_row_cursors() -> void:
	for row in _party_rows:
		if row["marker"].text == ">":
			row["marker"].text = " "

func _on_battle_started(party_data: Array, enemy_data: Array) -> void:
	_root.visible = true
	_results_label.visible = false
	_game_over_label.visible = false
	_command_menu.visible = false
	_target_label.visible = false
	_menu_state = MenuState.HIDDEN

	for i in _party_rows.size():
		if i < party_data.size():
			var p: Dictionary = party_data[i]
			_party_rows[i]["container"].visible = true
			_party_rows[i]["name"].text = str(p["name"])
			_party_rows[i]["hp_label"].text = "HP: %d/%d" % [p["hp"], p["max_hp"]]
			_party_rows[i]["hp_bar"].value = (float(int(p["hp"])) / float(int(p["max_hp"]))) * 100.0
			_party_rows[i]["atb_bar"].value = 0
			_party_rows[i]["marker"].text = " "
		else:
			_party_rows[i]["container"].visible = false

	for i in _enemy_bars.size():
		if i < enemy_data.size():
			var e: Dictionary = enemy_data[i]
			_enemy_bars[i]["container"].visible = true
			_enemy_bars[i]["name"].text = str(e["name"])
			_enemy_bars[i]["hp_bar"].value = 100.0
		else:
			_enemy_bars[i]["container"].visible = false

func _on_battle_ended() -> void:
	_results_label.visible = false
	_root.visible = false
	_menu_state = MenuState.HIDDEN
	_command_menu.visible = false
	_target_label.visible = false
	_active_member_index = -1

func _on_atb_updated(combatant_index: int, is_player: bool, value: float) -> void:
	if is_player and combatant_index < _party_rows.size():
		_party_rows[combatant_index]["atb_bar"].value = clampf(value, 0.0, 1.0) * 100.0

func _on_command_ready_changed(combatant_index: int, is_ready: bool) -> void:
	if is_ready and _menu_state == MenuState.HIDDEN:
		_menu_state = MenuState.COMMAND
		_command_menu.visible = true
		_command_cursor = 0
		_update_command_cursor()

	if not is_ready and _menu_state != MenuState.HIDDEN:
		if combatant_index == _active_member_index or combatant_index == -1:
			_menu_state = MenuState.HIDDEN
			_command_menu.visible = false
			_target_label.visible = false

func _on_active_member_changed(combatant_index: int) -> void:
	_active_member_index = combatant_index
	for i in _party_rows.size():
		_party_rows[i]["marker"].text = "★" if i == combatant_index else " "

func _on_party_hp_changed(combatant_index: int, current_hp: int, max_hp: int) -> void:
	if combatant_index < _party_rows.size():
		_party_rows[combatant_index]["hp_label"].text = "HP: %d/%d" % [max(current_hp, 0), max_hp]
		_party_rows[combatant_index]["hp_bar"].value = (float(max(current_hp, 0)) / float(max_hp)) * 100.0

func _on_enemy_hp_changed(enemy_index: int, _enemy_name: String, current_hp: int, max_hp: int) -> void:
	if enemy_index < _enemy_bars.size():
		_enemy_bars[enemy_index]["hp_bar"].value = (float(max(current_hp, 0)) / float(max_hp)) * 100.0

func _on_damage_dealt(world_position: Vector2, amount: int, is_critical: bool) -> void:
	_spawn_floating_number(world_position, str(amount), Color(1.0, 0.86, 0.25) if is_critical else Color.WHITE, 28 if is_critical else 22)

func _on_heal_applied(world_position: Vector2, amount: int) -> void:
	_spawn_floating_number(world_position, str(amount), Color(0.3, 1.0, 0.3), 22)

func _spawn_floating_number(world_position: Vector2, text: String, color: Color, font_size: int) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	_root.add_child(label)
	var screen_position := get_viewport().get_canvas_transform() * world_position
	label.position = screen_position - Vector2(12, 44)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position", label.position - Vector2(0, 38), 0.6)
	tween.tween_property(label, "modulate:a", 0.0, 0.6)
	tween.finished.connect(label.queue_free)

func _on_victory_achieved(total_exp: int, total_gold: int, total_tp: int) -> void:
	_menu_state = MenuState.HIDDEN
	_command_menu.visible = false
	_results_label.text = "EXP +%d   G +%d   TP +%d" % [total_exp, total_gold, total_tp]
	_results_label.visible = true

func _on_player_defeated() -> void:
	_menu_state = MenuState.HIDDEN
	_command_menu.visible = false
	_game_over_label.visible = true

func _on_enemy_died(enemy_index: int) -> void:
	if enemy_index < _enemy_bars.size():
		_enemy_bars[enemy_index]["container"].visible = false

func _on_combatant_ko(combatant_index: int) -> void:
	if combatant_index < _party_rows.size():
		_party_rows[combatant_index]["atb_bar"].value = 0

func _on_escaped() -> void:
	_escape_label.visible = false
