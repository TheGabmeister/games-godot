class_name BattleScene
extends CanvasLayer

enum BattlePhase {
	INACTIVE,
	INTRO,
	COMMAND_SELECT,
	TARGETING,
	ITEM_SELECT,
	ITEM_TARGET,
	MAGIC_LEVEL_SELECT,
	MAGIC_SPELL_SELECT,
	MAGIC_TARGET,
	ANIMATING,
	VICTORY,
	GAME_OVER,
}

const Battler = BattleTypes.Battler
const BattleCommand = BattleTypes.BattleCommand
const CommandType = BattleTypes.CommandType

const PARTY_POSITIONS: Array[Vector2] = [
	Vector2(900, 160),
	Vector2(940, 260),
	Vector2(980, 360),
	Vector2(1020, 460),
]

const BATTLE_TEXTURE: Dictionary = {
	PartyData.Job.WARRIOR: preload("res://characters/warrior/warrior_battle.png"),
	PartyData.Job.MONK: preload("res://characters/monk/monk_battle.png"),
	PartyData.Job.WHITE_MAGE: preload("res://characters/white_mage/white_mage_battle.png"),
	PartyData.Job.BLACK_MAGE: preload("res://characters/black_mage/black_mage_battle.png"),
}

signal battle_ended

var party_data: PartyData
var _battle_phase := BattlePhase.INACTIVE
var _encounter_table: EncounterTable
var _can_flee := true

var _party_battlers: Array[Battler] = []
var _enemy_battlers: Array[Battler] = []
var _commands: Array[BattleCommand] = []
var _command_index := 0
var _target_cursor := 0
var _command_cursor := 0
var _item_cursor := 0
var _item_target_cursor := 0
var _battle_items: Array[ItemData] = []
var _item_buttons: Array[GameButton] = []
var _item_target_buttons: Array[GameButton] = []
var _magic_level_cursor := 0
var _magic_spell_cursor := 0
var _magic_level_buttons: Array[GameButton] = []
var _magic_spell_buttons: Array[GameButton] = []
var _magic_spells_for_level: Array[SpellData] = []
var _selected_spell: SpellData
var _magic_target_cursor := 0
var _magic_target_buttons: Array[GameButton] = []
var _pending_magic_command_type: SpellData.TargetType

var _total_exp := 0
var _total_gil := 0
var _victory_state := 0
var _victory_level_ups: Array[Dictionary] = []
var _victory_level_index := 0

@onready var _resolver: BattleResolver = %Resolver

@onready var _transition_rect: ColorRect = %TransitionRect
@onready var _battle_container: Control = %BattleContainer
@onready var _battler_container: Node2D = %BattlerContainer
@onready var _damage_container: Node2D = %DamageContainer
@onready var _background: TextureRect = %Background

# HUD
@onready var _bottom_bar: HBoxContainer = %BottomBar
@onready var _char_names: Array[Label] = [%CharName0, %CharName1, %CharName2, %CharName3]
@onready var _char_hps: Array[Label] = [%CharHP0, %CharHP1, %CharHP2, %CharHP3]
@onready var _enemy_list_container: VBoxContainer = %EnemyListContainer

# Command menu
@onready var _command_panel: PanelContainer = %CommandPanel
@onready var _command_label: Label = %ActiveCharLabel
@onready var _cmd_attack: Label = %CmdAttack
@onready var _cmd_magic: Label = %CmdMagic
@onready var _cmd_item: Label = %CmdItem
@onready var _cmd_run: Label = %CmdRun

# Target cursor
@onready var _target_arrow: Label = %TargetArrow

# Item panel
@onready var _item_panel: PanelContainer = %ItemPanel
@onready var _item_list_container: VBoxContainer = %ItemListContainer

# Item target panel
@onready var _item_target_panel: PanelContainer = %ItemTargetPanel
@onready var _item_target_container: VBoxContainer = %ItemTargetContainer

# Victory panel
@onready var _victory_panel: PanelContainer = %VictoryPanel
@onready var _victory_label: Label = %VictoryLabel

# Game over
@onready var _game_over_overlay: ColorRect = %GameOverOverlay
@onready var _game_over_label: Label = %GameOverLabel

# Message
@onready var _message_panel: PanelContainer = %MessagePanel
@onready var _message_label: Label = %MessageLabel

@export var cursor_move_sfx: AudioStream
@export var confirm_sfx: AudioStream
@export var cancel_sfx: AudioStream
@export var level_up_sfx: AudioStream
@export var battle_start_sfx: AudioStream
@export var run_fail_sfx: AudioStream
@export var battle_theme: AudioStream
@export var victory_fanfare: AudioStream
@export var game_over_theme: AudioStream

func _ready() -> void:
	add_to_group(Groups.BATTLE_SCENE)
	var _c1 := _resolver.round_completed.connect(_begin_command_phase)
	var _c2 := _resolver.battle_won.connect(_start_victory)
	var _c3 := _resolver.battle_lost.connect(_start_game_over)
	var _c4 := _resolver.hud_update_requested.connect(_update_hud)
	var _c5 := _resolver.enemy_list_update_requested.connect(_update_enemy_list)
	_battle_container.visible = false
	_transition_rect.visible = false
	_command_panel.visible = false
	_item_panel.visible = false
	_item_target_panel.visible = false
	_victory_panel.visible = false
	_game_over_overlay.visible = false
	_message_panel.visible = false
	_target_arrow.visible = false

func start_battle(formation: EncounterFormation, encounter_table: EncounterTable) -> void:
	_encounter_table = encounter_table
	_can_flee = encounter_table.can_flee if encounter_table else true
	_setup_battlers(formation)
	_resolver.party_battlers = _party_battlers
	_resolver.enemy_battlers = _enemy_battlers
	_resolver.party_data = party_data
	_total_exp = 0
	_total_gil = 0
	for b: Battler in _enemy_battlers:
		_total_exp += b.enemy_data.exp_reward
		_total_gil += b.enemy_data.gil_reward
	GameState.transition(GameState.State.BATTLE)
	await _play_intro_transition()
	_setup_hud()
	_begin_command_phase()

func _input(event: InputEvent) -> void:
	if not GameState.is_state(GameState.State.BATTLE):
		return
	match _battle_phase:
		BattlePhase.COMMAND_SELECT:
			_handle_command_input(event)
		BattlePhase.TARGETING:
			_handle_targeting_input(event)
		BattlePhase.ITEM_SELECT:
			_handle_item_select_input(event)
		BattlePhase.ITEM_TARGET:
			_handle_item_target_input(event)
		BattlePhase.MAGIC_LEVEL_SELECT:
			_handle_magic_level_input(event)
		BattlePhase.MAGIC_SPELL_SELECT:
			_handle_magic_spell_input(event)
		BattlePhase.MAGIC_TARGET:
			_handle_magic_target_input(event)
		BattlePhase.VICTORY:
			_handle_victory_input(event)
		BattlePhase.GAME_OVER:
			_handle_game_over_input(event)

# --- INTRO / TRANSITION ---

func _play_intro_transition() -> void:
	_battle_phase = BattlePhase.INTRO
	_transition_rect.visible = true
	_transition_rect.color = Color(1, 1, 1, 0)

	_play_sfx(battle_start_sfx, -12.0)

	var tw := create_tween()
	var _t1 := tw.tween_property(_transition_rect, "color", Color(1, 1, 1, 1), 0.1)
	var _t2 := tw.tween_interval(0.05)
	var _t3 := tw.tween_property(_transition_rect, "color", Color(0, 0, 0, 1), 0.3)
	var _t4 := tw.tween_callback(_show_battle_scene)
	var _t5 := tw.tween_property(_transition_rect, "color", Color(0, 0, 0, 0), 0.3)
	var _t6 := tw.tween_callback(func() -> void: _transition_rect.visible = false)
	await tw.finished

func _show_battle_scene() -> void:
	_battle_container.visible = true
	if _encounter_table and _encounter_table.battle_background:
		_background.texture = _encounter_table.battle_background
	_spawn_sprites()
	if battle_theme:
		MusicManager.play(battle_theme)

# --- BATTLER SETUP ---

func _setup_battlers(formation: EncounterFormation) -> void:
	_party_battlers.clear()
	_enemy_battlers.clear()
	_commands.clear()

	for i: int in party_data.party.size():
		var c: PartyData.CharacterData = party_data.party[i]
		var b := Battler.new()
		b.display_name = c.char_name
		b.max_hp = c.max_hp
		b.current_hp = c.current_hp
		b.attack_power = c.get_attack_power()
		b.accuracy = c.get_hit_percent()
		b.defense = c.get_absorb()
		b.agility = c.agility
		b.evade = c.get_evade()
		b.crit_rate = c.get_crit_rate()
		b.max_hits = c.get_max_hits()
		b.magic_defense = c.magic_defense
		b.is_party = true
		b.party_index = i
		b.character_data = c
		b.home_position = PARTY_POSITIONS[i]
		_party_battlers.append(b)

	for entry: EnemyEntry in formation.enemies:
		for j: int in entry.count:
			var e: EnemyData = entry.enemy
			var b := Battler.new()
			b.display_name = e.enemy_name
			b.max_hp = e.max_hp
			b.current_hp = e.max_hp
			b.attack_power = e.attack
			b.accuracy = e.accuracy
			b.defense = e.defense
			b.agility = e.agility
			b.evade = e.evade
			b.crit_rate = 0
			b.max_hits = e.num_hits
			b.magic_defense = e.magic_defense
			b.is_party = false
			b.enemy_data = e
			_enemy_battlers.append(b)

	_assign_enemy_positions()

func _assign_enemy_positions() -> void:
	var count := _enemy_battlers.size()
	var spacing := 100.0 if count <= 4 else 80.0
	var total_height := (count - 1) * spacing
	var start_y := 310.0 - total_height / 2.0
	for i: int in count:
		var b: Battler = _enemy_battlers[i]
		var x_offset := randf_range(-20.0, 20.0)
		b.home_position = Vector2(250.0 + x_offset, start_y + i * spacing)

func _spawn_sprites() -> void:
	_clear_children(_battler_container)

	for b: Battler in _party_battlers:
		var sprite := Sprite2D.new()
		if b.character_data:
			sprite.texture = BATTLE_TEXTURE.get(b.character_data.job)
		sprite.position = b.home_position
		_battler_container.add_child(sprite)
		b.sprite = sprite
		if b.is_dead():
			sprite.modulate.a = 0.3

	for b: Battler in _enemy_battlers:
		var sprite := Sprite2D.new()
		if b.enemy_data and b.enemy_data.sprite:
			sprite.texture = b.enemy_data.sprite
		else:
			sprite.modulate = Color.RED
		sprite.position = b.home_position
		_battler_container.add_child(sprite)
		b.sprite = sprite

# --- HUD ---

func _setup_hud() -> void:
	_bottom_bar.visible = true
	_update_hud()
	_update_enemy_list()

func _update_hud() -> void:
	for i: int in 4:
		var b: Battler = _party_battlers[i]
		var abbrev := b.display_name.substr(0, 3)
		_char_names[i].text = abbrev
		_char_hps[i].text = "%d/ %d" % [maxi(0, b.current_hp), b.max_hp]

func _update_enemy_list() -> void:
	_clear_children(_enemy_list_container)
	var counts: Dictionary = {}
	for b: Battler in _enemy_battlers:
		if b.is_dead():
			continue
		if b.display_name in counts:
			counts[b.display_name] += 1
		else:
			counts[b.display_name] = 1
	for enemy_name: String in counts:
		var label := Label.new()
		var count: int = counts[enemy_name]
		label.text = "%s    %d" % [enemy_name, count] if count > 1 else enemy_name
		_enemy_list_container.add_child(label)

# --- COMMAND PHASE ---

func _begin_command_phase() -> void:
	_commands.clear()
	_command_index = 0
	_show_command_menu()

func _show_command_menu() -> void:
	while _command_index < _party_battlers.size() and _party_battlers[_command_index].is_dead():
		_commands.append(_make_skip_command(_command_index))
		_command_index += 1

	if _command_index >= _party_battlers.size():
		_command_panel.visible = false
		_resolve_round()
		return

	_battle_phase = BattlePhase.COMMAND_SELECT
	_command_cursor = 0
	_command_panel.visible = true
	_command_label.text = _party_battlers[_command_index].display_name
	_update_command_cursor()

func _make_skip_command(idx: int) -> BattleCommand:
	var cmd := BattleCommand.new()
	cmd.type = CommandType.ATTACK
	cmd.actor_index = idx
	cmd.target_index = -1
	return cmd

func _update_command_cursor() -> void:
	var labels: Array[Label] = [_cmd_attack, _cmd_magic, _cmd_item, _cmd_run]
	for i: int in labels.size():
		if i == _command_cursor:
			labels[i].text = "> " + _get_cmd_name(i)
		else:
			labels[i].text = "  " + _get_cmd_name(i)

func _get_cmd_name(idx: int) -> String:
	match idx:
		0: return "Attack"
		1: return "Magic"
		2: return "Item"
		3: return "Run"
	return ""

func _handle_command_input(event: InputEvent) -> void:
	if event.is_action_pressed("move_up"):
		_command_cursor = (_command_cursor - 1 + 4) % 4
		_update_command_cursor()
		_play_sfx(cursor_move_sfx)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("move_down"):
		_command_cursor = (_command_cursor + 1) % 4
		_update_command_cursor()
		_play_sfx(cursor_move_sfx)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("confirm"):
		_select_command()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("cancel"):
		if _command_index > 0:
			_command_index -= 1
			while _command_index > 0 and _party_battlers[_command_index].is_dead():
				_command_index -= 1
			var _ok := _commands.resize(_command_index)
			_show_command_menu()
			_play_sfx(cancel_sfx)
		get_viewport().set_input_as_handled()

func _select_command() -> void:
	match _command_cursor:
		0: # Attack
			_play_sfx(confirm_sfx)
			_enter_targeting()
		1: # Magic
			var battler := _party_battlers[_command_index]
			if battler.statuses.get(&"silence", 0) != 0:
				_play_sfx(cancel_sfx)
				return
			_play_sfx(confirm_sfx)
			_enter_magic_level_select()
		2: # Item
			_play_sfx(confirm_sfx)
			_enter_item_select()
		3: # Run
			_play_sfx(confirm_sfx)
			_attempt_run()

# --- TARGETING ---

func _enter_targeting() -> void:
	_battle_phase = BattlePhase.TARGETING
	_command_panel.visible = false
	_selected_spell = null
	_target_cursor = 0
	_find_alive_enemy_target()
	_update_target_cursor()

func _find_alive_enemy_target() -> void:
	while _target_cursor < _enemy_battlers.size() and _enemy_battlers[_target_cursor].is_dead():
		_target_cursor += 1
	if _target_cursor >= _enemy_battlers.size():
		_target_cursor = 0
		while _target_cursor < _enemy_battlers.size() and _enemy_battlers[_target_cursor].is_dead():
			_target_cursor += 1

func _update_target_cursor() -> void:
	if _target_cursor < _enemy_battlers.size():
		_target_arrow.visible = true
		var enemy_b: Battler = _enemy_battlers[_target_cursor]
		_target_arrow.position = enemy_b.sprite.position + Vector2(-50, -10)
	else:
		_target_arrow.visible = false

func _handle_targeting_input(event: InputEvent) -> void:
	var alive_enemies := _resolver.get_alive_indices(_enemy_battlers)
	if alive_enemies.is_empty():
		return

	if event.is_action_pressed("move_up"):
		var cur_pos := alive_enemies.find(_target_cursor)
		cur_pos = (cur_pos - 1 + alive_enemies.size()) % alive_enemies.size()
		_target_cursor = alive_enemies[cur_pos]
		_update_target_cursor()
		_play_sfx(cursor_move_sfx)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("move_down"):
		var cur_pos := alive_enemies.find(_target_cursor)
		cur_pos = (cur_pos + 1) % alive_enemies.size()
		_target_cursor = alive_enemies[cur_pos]
		_update_target_cursor()
		_play_sfx(cursor_move_sfx)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("confirm"):
		_play_sfx(confirm_sfx)
		if _selected_spell != null and _pending_magic_command_type == SpellData.TargetType.SINGLE_ENEMY:
			_commit_magic_command(_target_cursor)
			_selected_spell = null
		else:
			var cmd := BattleCommand.new()
			cmd.type = CommandType.ATTACK
			cmd.actor_index = _command_index
			cmd.target_index = _target_cursor
			_commands.append(cmd)
			_target_arrow.visible = false
			_command_index += 1
			_show_command_menu()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("cancel"):
		_target_arrow.visible = false
		if _selected_spell != null:
			_item_panel.visible = true
			_build_magic_spell_list()
			_battle_phase = BattlePhase.MAGIC_SPELL_SELECT
			_selected_spell = null
		else:
			_command_panel.visible = true
			_battle_phase = BattlePhase.COMMAND_SELECT
		_play_sfx(cancel_sfx)
		get_viewport().set_input_as_handled()

# --- ITEM SELECT ---

func _enter_item_select() -> void:
	_battle_phase = BattlePhase.ITEM_SELECT
	_command_panel.visible = false
	_item_cursor = 0
	_battle_items.clear()

	for item_key: ItemData in party_data.inventory:
		var item: ItemData = item_key
		if item:
			_battle_items.append(item)

	if _battle_items.is_empty():
		_command_panel.visible = true
		_battle_phase = BattlePhase.COMMAND_SELECT
		return

	_build_item_list()
	_item_panel.visible = true

func _build_item_list() -> void:
	_clear_children(_item_list_container)
	_item_buttons.clear()
	for i: int in _battle_items.size():
		var item: ItemData = _battle_items[i]
		var qty: int = party_data.inventory.get(item, 0)
		var btn := GameButton.new()
		btn.button_text = "%s  x%d" % [item.item_name, qty]
		btn.set_selected(i == _item_cursor)
		_item_list_container.add_child(btn)
		_item_buttons.append(btn)

func _update_item_cursor() -> void:
	for i: int in _item_buttons.size():
		_item_buttons[i].set_selected(i == _item_cursor)

func _handle_item_select_input(event: InputEvent) -> void:
	if _battle_items.is_empty():
		return
	if event.is_action_pressed("move_up"):
		_item_cursor = (_item_cursor - 1 + _battle_items.size()) % _battle_items.size()
		_update_item_cursor()
		_play_sfx(cursor_move_sfx)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("move_down"):
		_item_cursor = (_item_cursor + 1) % _battle_items.size()
		_update_item_cursor()
		_play_sfx(cursor_move_sfx)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("confirm"):
		_play_sfx(confirm_sfx)
		_enter_item_target()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("cancel"):
		_item_panel.visible = false
		_command_panel.visible = true
		_battle_phase = BattlePhase.COMMAND_SELECT
		_play_sfx(cancel_sfx)
		get_viewport().set_input_as_handled()

# --- ITEM TARGET ---

func _enter_item_target() -> void:
	_battle_phase = BattlePhase.ITEM_TARGET
	_item_panel.visible = false
	_item_target_cursor = 0
	_build_item_target_list()
	_item_target_panel.visible = true

func _build_item_target_list() -> void:
	_clear_children(_item_target_container)
	_item_target_buttons.clear()
	for i: int in _party_battlers.size():
		var b: Battler = _party_battlers[i]
		var btn := GameButton.new()
		btn.button_text = "%s  %d/%d" % [b.display_name, maxi(0, b.current_hp), b.max_hp]
		btn.set_selected(i == _item_target_cursor)
		_item_target_container.add_child(btn)
		_item_target_buttons.append(btn)

func _update_item_target_cursor() -> void:
	for i: int in _item_target_buttons.size():
		_item_target_buttons[i].set_selected(i == _item_target_cursor)

func _handle_item_target_input(event: InputEvent) -> void:
	if event.is_action_pressed("move_up"):
		_item_target_cursor = (_item_target_cursor - 1 + _party_battlers.size()) % _party_battlers.size()
		_update_item_target_cursor()
		_play_sfx(cursor_move_sfx)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("move_down"):
		_item_target_cursor = (_item_target_cursor + 1) % _party_battlers.size()
		_update_item_target_cursor()
		_play_sfx(cursor_move_sfx)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("confirm"):
		var cmd := BattleCommand.new()
		cmd.type = CommandType.ITEM
		cmd.actor_index = _command_index
		cmd.target_index = _item_target_cursor
		cmd.item = _battle_items[_item_cursor]
		_commands.append(cmd)
		_item_target_panel.visible = false
		_command_index += 1
		_play_sfx(confirm_sfx)
		_show_command_menu()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("cancel"):
		_item_target_panel.visible = false
		_item_panel.visible = true
		_battle_phase = BattlePhase.ITEM_SELECT
		_play_sfx(cancel_sfx)
		get_viewport().set_input_as_handled()

# --- MAGIC LEVEL SELECT ---

func _enter_magic_level_select() -> void:
	_battle_phase = BattlePhase.MAGIC_LEVEL_SELECT
	_command_panel.visible = false
	_magic_level_cursor = 0
	_build_magic_level_list()
	_item_panel.visible = true

func _build_magic_level_list() -> void:
	_clear_children(_item_list_container)
	_magic_level_buttons.clear()
	var char_data: PartyData.CharacterData = _party_battlers[_command_index].character_data
	for i: int in 8:
		var spell_level := i + 1
		var spells := char_data.get_spells_for_level(spell_level)
		var charges := char_data.spell_charges[i]
		var max_charges := char_data.max_spell_charges[i]
		var btn := GameButton.new()
		if spells.is_empty():
			btn.button_text = "Lv %d  --" % spell_level
		else:
			btn.button_text = "Lv %d  %d/%d" % [spell_level, charges, max_charges]
		btn.set_selected(i == _magic_level_cursor)
		_item_list_container.add_child(btn)
		_magic_level_buttons.append(btn)

func _update_magic_level_cursor() -> void:
	for i: int in _magic_level_buttons.size():
		_magic_level_buttons[i].set_selected(i == _magic_level_cursor)

func _handle_magic_level_input(event: InputEvent) -> void:
	if event.is_action_pressed("move_up"):
		_magic_level_cursor = (_magic_level_cursor - 1 + 8) % 8
		_update_magic_level_cursor()
		_play_sfx(cursor_move_sfx)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("move_down"):
		_magic_level_cursor = (_magic_level_cursor + 1) % 8
		_update_magic_level_cursor()
		_play_sfx(cursor_move_sfx)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("confirm"):
		var char_data: PartyData.CharacterData = _party_battlers[_command_index].character_data
		var spell_level := _magic_level_cursor + 1
		var spells := char_data.get_spells_for_level(spell_level)
		var charges := char_data.spell_charges[_magic_level_cursor]
		if spells.is_empty() or charges <= 0:
			_play_sfx(cancel_sfx)
		else:
			_play_sfx(confirm_sfx)
			_magic_spells_for_level = spells
			_enter_magic_spell_select()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("cancel"):
		_item_panel.visible = false
		_command_panel.visible = true
		_battle_phase = BattlePhase.COMMAND_SELECT
		_play_sfx(cancel_sfx)
		get_viewport().set_input_as_handled()

# --- MAGIC SPELL SELECT ---

func _enter_magic_spell_select() -> void:
	_battle_phase = BattlePhase.MAGIC_SPELL_SELECT
	_magic_spell_cursor = 0
	_build_magic_spell_list()

func _build_magic_spell_list() -> void:
	_clear_children(_item_list_container)
	_magic_spell_buttons.clear()
	for i: int in _magic_spells_for_level.size():
		var spell: SpellData = _magic_spells_for_level[i]
		var btn := GameButton.new()
		btn.button_text = spell.spell_name
		btn.set_selected(i == _magic_spell_cursor)
		_item_list_container.add_child(btn)
		_magic_spell_buttons.append(btn)

func _update_magic_spell_cursor() -> void:
	for i: int in _magic_spell_buttons.size():
		_magic_spell_buttons[i].set_selected(i == _magic_spell_cursor)

func _handle_magic_spell_input(event: InputEvent) -> void:
	if event.is_action_pressed("move_up"):
		_magic_spell_cursor = (_magic_spell_cursor - 1 + _magic_spells_for_level.size()) % _magic_spells_for_level.size()
		_update_magic_spell_cursor()
		_play_sfx(cursor_move_sfx)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("move_down"):
		_magic_spell_cursor = (_magic_spell_cursor + 1) % _magic_spells_for_level.size()
		_update_magic_spell_cursor()
		_play_sfx(cursor_move_sfx)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("confirm"):
		_selected_spell = _magic_spells_for_level[_magic_spell_cursor]
		_play_sfx(confirm_sfx)
		_pending_magic_command_type = _selected_spell.target_type
		match _selected_spell.target_type:
			SpellData.TargetType.SINGLE_ENEMY:
				_item_panel.visible = false
				_enter_magic_enemy_targeting()
			SpellData.TargetType.SINGLE_ALLY:
				_item_panel.visible = false
				_enter_magic_ally_targeting()
			SpellData.TargetType.ALL_ENEMIES, SpellData.TargetType.ALL_ALLIES, SpellData.TargetType.SELF:
				_commit_magic_command(-1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("cancel"):
		_play_sfx(cancel_sfx)
		_build_magic_level_list()
		_battle_phase = BattlePhase.MAGIC_LEVEL_SELECT
		get_viewport().set_input_as_handled()

# --- MAGIC TARGETING ---

func _enter_magic_enemy_targeting() -> void:
	_battle_phase = BattlePhase.TARGETING
	_target_cursor = 0
	_find_alive_enemy_target()
	_update_target_cursor()

func _enter_magic_ally_targeting() -> void:
	_battle_phase = BattlePhase.MAGIC_TARGET
	_magic_target_cursor = 0
	_build_magic_target_list()
	_item_target_panel.visible = true

func _build_magic_target_list() -> void:
	_clear_children(_item_target_container)
	_magic_target_buttons.clear()
	for i: int in _party_battlers.size():
		var b: Battler = _party_battlers[i]
		var btn := GameButton.new()
		btn.button_text = "%s  %d/%d" % [b.display_name, maxi(0, b.current_hp), b.max_hp]
		btn.set_selected(i == _magic_target_cursor)
		_item_target_container.add_child(btn)
		_magic_target_buttons.append(btn)

func _update_magic_target_cursor() -> void:
	for i: int in _magic_target_buttons.size():
		_magic_target_buttons[i].set_selected(i == _magic_target_cursor)

func _handle_magic_target_input(event: InputEvent) -> void:
	if event.is_action_pressed("move_up"):
		_magic_target_cursor = (_magic_target_cursor - 1 + _party_battlers.size()) % _party_battlers.size()
		_update_magic_target_cursor()
		_play_sfx(cursor_move_sfx)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("move_down"):
		_magic_target_cursor = (_magic_target_cursor + 1) % _party_battlers.size()
		_update_magic_target_cursor()
		_play_sfx(cursor_move_sfx)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("confirm"):
		_play_sfx(confirm_sfx)
		_item_target_panel.visible = false
		_commit_magic_command(_magic_target_cursor)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("cancel"):
		_item_target_panel.visible = false
		_item_panel.visible = true
		_build_magic_spell_list()
		_battle_phase = BattlePhase.MAGIC_SPELL_SELECT
		_play_sfx(cancel_sfx)
		get_viewport().set_input_as_handled()

func _commit_magic_command(target_idx: int) -> void:
	var cmd := BattleCommand.new()
	cmd.type = CommandType.MAGIC
	cmd.actor_index = _command_index
	cmd.target_index = target_idx
	cmd.spell = _selected_spell
	_commands.append(cmd)
	_item_panel.visible = false
	_item_target_panel.visible = false
	_target_arrow.visible = false
	_command_index += 1
	_show_command_menu()

# --- RUN ---

func _attempt_run() -> void:
	if not _can_flee:
		_show_battle_message("Can't escape!")
		return

	var avg_luck := 0.0
	var alive_count := 0
	for b: Battler in _party_battlers:
		if not b.is_dead():
			avg_luck += b.character_data.luck
			alive_count += 1
	if alive_count > 0:
		avg_luck /= alive_count

	var avg_enemy_agi := 0.0
	for b: Battler in _enemy_battlers:
		avg_enemy_agi += b.agility
	if not _enemy_battlers.is_empty():
		avg_enemy_agi /= _enemy_battlers.size()

	if BattleFormulas.run_chance(avg_luck, avg_enemy_agi):
		_command_panel.visible = false
		await _show_battle_message_await("Got away safely!")
		_end_battle_no_rewards()
	else:
		_play_sfx(run_fail_sfx)
		await _show_battle_message_await("Can't escape!")
		_command_index = _party_battlers.size()
		_command_panel.visible = false
		_resolve_round()

# --- TURN RESOLUTION ---

func _resolve_round() -> void:
	_battle_phase = BattlePhase.ANIMATING
	_resolver.resolve_round(_commands)

# --- BATTLE END ---

func _start_victory() -> void:
	_battle_phase = BattlePhase.VICTORY
	_command_panel.visible = false
	_target_arrow.visible = false

	if victory_fanfare:
		MusicManager.play(victory_fanfare)

	var alive_count := 0
	for b: Battler in _party_battlers:
		if not b.is_dead():
			alive_count += 1

	var exp_each := BattleFormulas.distribute_exp(_total_exp, alive_count)

	_victory_label.text = "Enemies defeated!\n\nEXP: %d    Gil: %d" % [_total_exp, _total_gil]
	_victory_panel.visible = true
	party_data.gil += _total_gil

	_victory_state = 0
	_victory_level_ups.clear()

	for b: Battler in _party_battlers:
		if not b.is_dead() and b.character_data:
			var ups := b.character_data.add_exp(exp_each)
			if not ups.is_empty():
				_victory_level_ups.append({"name": b.display_name, "ups": ups})

func _handle_victory_input(event: InputEvent) -> void:
	if not event.is_action_pressed("confirm"):
		return
	get_viewport().set_input_as_handled()

	if _victory_state == 0:
		if _victory_level_ups.is_empty():
			_end_battle_with_rewards()
			return
		_victory_level_index = 0
		_show_next_level_up()
		_victory_state = 1
	elif _victory_state == 1:
		_victory_level_index += 1
		if _victory_level_index >= _victory_level_ups.size():
			_end_battle_with_rewards()
		else:
			_show_next_level_up()

func _show_next_level_up() -> void:
	var data: Dictionary = _victory_level_ups[_victory_level_index]
	var name_str: String = data["name"]
	var ups: Array = data["ups"]
	var text := "%s reached Level Up!\n" % name_str
	for up: Dictionary in ups:
		text += "\nHP +%d  STR +%d  AGI +%d  VIT +%d  INT +%d  LCK +%d" % [
			up.get("hp", 0), up.get("str", 0), up.get("agi", 0),
			up.get("vit", 0), up.get("int", 0), up.get("lck", 0),
		]
	_victory_label.text = text
	_play_sfx(level_up_sfx)

func _end_battle_with_rewards() -> void:
	_victory_panel.visible = false
	await _play_exit_transition()
	_cleanup_battle()
	battle_ended.emit()

func _end_battle_no_rewards() -> void:
	await _play_exit_transition()
	_cleanup_battle()
	battle_ended.emit()

func _play_exit_transition() -> void:
	_transition_rect.visible = true
	_transition_rect.color = Color(0, 0, 0, 0)
	var tw := create_tween()
	var _t1 := tw.tween_property(_transition_rect, "color", Color(0, 0, 0, 1), 0.3)
	var _t2 := tw.tween_callback(func() -> void: _battle_container.visible = false)
	var _t3 := tw.tween_property(_transition_rect, "color", Color(0, 0, 0, 0), 0.3)
	var _t4 := tw.tween_callback(func() -> void: _transition_rect.visible = false)
	await tw.finished

func _cleanup_battle() -> void:
	_clear_children(_battler_container)
	_clear_children(_damage_container)
	_party_battlers.clear()
	_enemy_battlers.clear()
	_commands.clear()
	_battle_phase = BattlePhase.INACTIVE
	_bottom_bar.visible = false
	_command_panel.visible = false
	_item_panel.visible = false
	_item_target_panel.visible = false
	_victory_panel.visible = false
	_game_over_overlay.visible = false
	_message_panel.visible = false
	_target_arrow.visible = false
	GameState.transition(GameState.State.FIELD)

# --- GAME OVER ---

func _start_game_over() -> void:
	_battle_phase = BattlePhase.GAME_OVER
	_command_panel.visible = false
	_target_arrow.visible = false
	_bottom_bar.visible = false

	if game_over_theme:
		MusicManager.play(game_over_theme)

	_game_over_overlay.visible = true
	_game_over_overlay.color = Color(0, 0, 0, 0)
	_game_over_label.visible = false

	var tw := create_tween()
	var _t1 := tw.tween_property(_game_over_overlay, "color", Color(0, 0, 0, 0.85), 1.0)
	var _t2 := tw.tween_callback(func() -> void: _game_over_label.visible = true)
	await tw.finished

func _handle_game_over_input(event: InputEvent) -> void:
	if event.is_action_pressed("confirm"):
		get_viewport().set_input_as_handled()
		var _err := get_tree().change_scene_to_file("res://title_screen.tscn")

# --- MESSAGES ---

func _show_battle_message(text: String) -> void:
	_message_label.text = text
	_message_panel.visible = true

func _show_battle_message_await(text: String) -> void:
	_message_label.text = text
	_message_panel.visible = true
	await get_tree().create_timer(1.0).timeout
	_message_panel.visible = false

# --- HELPERS ---

func _play_sfx(stream: AudioStream, volume_db := 0.0) -> void:
	if stream:
		SfxManager.play(stream, volume_db)

func _clear_children(node: Node) -> void:
	for child: Node in node.get_children():
		child.queue_free()
