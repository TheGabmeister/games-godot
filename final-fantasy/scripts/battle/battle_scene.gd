class_name BattleScene
extends CanvasLayer

enum BattlePhase {
	INACTIVE,
	INTRO,
	COMMAND_SELECT,
	TARGETING,
	ITEM_SELECT,
	ITEM_TARGET,
	RESOLVING,
	ANIMATING,
	VICTORY,
	GAME_OVER,
}

enum CommandType { ATTACK, ITEM, RUN }

class BattleCommand:
	var type: CommandType
	var actor_index: int
	var target_index: int = -1
	var item: ItemData
	var is_enemy_command: bool = false

class Battler:
	var display_name: String
	var max_hp: int
	var current_hp: int
	var attack_power: int
	var accuracy: int
	var defense: int
	var agility: int
	var evade: int
	var crit_rate: int
	var max_hits: int
	var is_party: bool
	var party_index: int = -1
	var character_data: PartyData.CharacterData
	var enemy_data: EnemyData
	var sprite: Sprite2D
	var home_position: Vector2

	func is_dead() -> bool:
		return current_hp <= 0

	func take_damage(amount: int) -> void:
		current_hp = maxi(0, current_hp - amount)
		if character_data:
			character_data.current_hp = current_hp

	func heal(amount: int) -> void:
		current_hp = mini(current_hp + amount, max_hp)
		if character_data:
			character_data.current_hp = current_hp

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

var _total_exp := 0
var _total_gil := 0

@onready var _transition_rect: ColorRect = %TransitionRect
@onready var _battle_container: Control = %BattleContainer
@onready var _battler_container: Node2D = %BattlerContainer
@onready var _damage_container: Node2D = %DamageContainer
@onready var _background: TextureRect = %Background

# HUD
@onready var _bottom_bar: PanelContainer = %BottomBar
@onready var _char_names: Array[Label] = [%CharName0, %CharName1, %CharName2, %CharName3]
@onready var _char_hps: Array[Label] = [%CharHP0, %CharHP1, %CharHP2, %CharHP3]

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
@export var attack_swing_sfx: AudioStream
@export var attack_hit_sfx: AudioStream
@export var attack_miss_sfx: AudioStream
@export var critical_hit_sfx: AudioStream
@export var enemy_death_sfx: AudioStream
@export var level_up_sfx: AudioStream
@export var battle_start_sfx: AudioStream
@export var run_fail_sfx: AudioStream
@export var battle_theme: AudioStream
@export var victory_fanfare: AudioStream
@export var game_over_theme: AudioStream

func _ready() -> void:
	add_to_group(Groups.BATTLE_SCENE)
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
		BattlePhase.VICTORY:
			_handle_victory_input(event)
		BattlePhase.GAME_OVER:
			_handle_game_over_input(event)

# --- INTRO / TRANSITION ---

func _play_intro_transition() -> void:
	_battle_phase = BattlePhase.INTRO
	_transition_rect.visible = true
	_transition_rect.color = Color(1, 1, 1, 0)

	if battle_start_sfx:
		SfxManager.play(battle_start_sfx)

	var tween := create_tween()
	tween.tween_property(_transition_rect, "color", Color(1, 1, 1, 1), 0.1)
	tween.tween_interval(0.05)
	tween.tween_property(_transition_rect, "color", Color(0, 0, 0, 1), 0.3)
	tween.tween_callback(_show_battle_scene)
	tween.tween_property(_transition_rect, "color", Color(0, 0, 0, 0), 0.3)
	tween.tween_callback(func() -> void: _transition_rect.visible = false)
	await tween.finished

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
	for child: Node in _battler_container.get_children():
		child.queue_free()

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

func _update_hud() -> void:
	for i: int in 4:
		var b: Battler = _party_battlers[i]
		_char_names[i].text = b.display_name
		_char_hps[i].text = "%d/%d" % [maxi(0, b.current_hp), b.max_hp]

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
		if _command_cursor == 1:
			_command_cursor = 0
		_update_command_cursor()
		if cursor_move_sfx:
			SfxManager.play(cursor_move_sfx)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("move_down"):
		_command_cursor = (_command_cursor + 1) % 4
		if _command_cursor == 1:
			_command_cursor = 2
		_update_command_cursor()
		if cursor_move_sfx:
			SfxManager.play(cursor_move_sfx)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("confirm"):
		_select_command()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("cancel"):
		if _command_index > 0:
			_command_index -= 1
			while _command_index > 0 and _party_battlers[_command_index].is_dead():
				_command_index -= 1
			_commands.resize(_command_index)
			_show_command_menu()
			if cancel_sfx:
				SfxManager.play(cancel_sfx)
		get_viewport().set_input_as_handled()

func _select_command() -> void:
	match _command_cursor:
		0: # Attack
			if confirm_sfx:
				SfxManager.play(confirm_sfx)
			_enter_targeting()
		1: # Magic - disabled
			pass
		2: # Item
			if confirm_sfx:
				SfxManager.play(confirm_sfx)
			_enter_item_select()
		3: # Run
			if confirm_sfx:
				SfxManager.play(confirm_sfx)
			_attempt_run()

# --- TARGETING ---

func _enter_targeting() -> void:
	_battle_phase = BattlePhase.TARGETING
	_command_panel.visible = false
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
	var alive_enemies := _get_alive_enemy_indices()
	if alive_enemies.is_empty():
		return

	if event.is_action_pressed("move_up"):
		var cur_pos := alive_enemies.find(_target_cursor)
		cur_pos = (cur_pos - 1 + alive_enemies.size()) % alive_enemies.size()
		_target_cursor = alive_enemies[cur_pos]
		_update_target_cursor()
		if cursor_move_sfx:
			SfxManager.play(cursor_move_sfx)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("move_down"):
		var cur_pos := alive_enemies.find(_target_cursor)
		cur_pos = (cur_pos + 1) % alive_enemies.size()
		_target_cursor = alive_enemies[cur_pos]
		_update_target_cursor()
		if cursor_move_sfx:
			SfxManager.play(cursor_move_sfx)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("confirm"):
		var cmd := BattleCommand.new()
		cmd.type = CommandType.ATTACK
		cmd.actor_index = _command_index
		cmd.target_index = _target_cursor
		_commands.append(cmd)
		_target_arrow.visible = false
		_command_index += 1
		if confirm_sfx:
			SfxManager.play(confirm_sfx)
		_show_command_menu()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("cancel"):
		_target_arrow.visible = false
		_command_panel.visible = true
		_battle_phase = BattlePhase.COMMAND_SELECT
		if cancel_sfx:
			SfxManager.play(cancel_sfx)
		get_viewport().set_input_as_handled()

# --- ITEM SELECT ---

func _enter_item_select() -> void:
	_battle_phase = BattlePhase.ITEM_SELECT
	_command_panel.visible = false
	_item_cursor = 0
	_battle_items.clear()

	for item_key: Variant in party_data.inventory:
		var item := item_key as ItemData
		if item and item.effect_type == ItemData.EffectType.HEAL_HP:
			_battle_items.append(item)

	if _battle_items.is_empty():
		_command_panel.visible = true
		_battle_phase = BattlePhase.COMMAND_SELECT
		return

	_rebuild_item_list()
	_item_panel.visible = true

func _rebuild_item_list() -> void:
	for child: Node in _item_list_container.get_children():
		child.queue_free()
	for i: int in _battle_items.size():
		var item: ItemData = _battle_items[i]
		var qty: int = party_data.inventory.get(item, 0)
		var label := Label.new()
		var prefix := "> " if i == _item_cursor else "  "
		label.text = "%s%s  x%d" % [prefix, item.item_name, qty]
		label.add_theme_font_size_override("font_size", 20)
		_item_list_container.add_child(label)

func _handle_item_select_input(event: InputEvent) -> void:
	if _battle_items.is_empty():
		return
	if event.is_action_pressed("move_up"):
		_item_cursor = (_item_cursor - 1 + _battle_items.size()) % _battle_items.size()
		_rebuild_item_list()
		if cursor_move_sfx:
			SfxManager.play(cursor_move_sfx)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("move_down"):
		_item_cursor = (_item_cursor + 1) % _battle_items.size()
		_rebuild_item_list()
		if cursor_move_sfx:
			SfxManager.play(cursor_move_sfx)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("confirm"):
		if confirm_sfx:
			SfxManager.play(confirm_sfx)
		_enter_item_target()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("cancel"):
		_item_panel.visible = false
		_command_panel.visible = true
		_battle_phase = BattlePhase.COMMAND_SELECT
		if cancel_sfx:
			SfxManager.play(cancel_sfx)
		get_viewport().set_input_as_handled()

# --- ITEM TARGET ---

func _enter_item_target() -> void:
	_battle_phase = BattlePhase.ITEM_TARGET
	_item_panel.visible = false
	_item_target_cursor = 0
	_rebuild_item_target_list()
	_item_target_panel.visible = true

func _rebuild_item_target_list() -> void:
	for child: Node in _item_target_container.get_children():
		child.queue_free()
	for i: int in _party_battlers.size():
		var b: Battler = _party_battlers[i]
		var label := Label.new()
		var prefix := "> " if i == _item_target_cursor else "  "
		label.text = "%s%s  %d/%d" % [prefix, b.display_name, maxi(0, b.current_hp), b.max_hp]
		label.add_theme_font_size_override("font_size", 20)
		_item_target_container.add_child(label)

func _handle_item_target_input(event: InputEvent) -> void:
	if event.is_action_pressed("move_up"):
		_item_target_cursor = (_item_target_cursor - 1 + _party_battlers.size()) % _party_battlers.size()
		_rebuild_item_target_list()
		if cursor_move_sfx:
			SfxManager.play(cursor_move_sfx)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("move_down"):
		_item_target_cursor = (_item_target_cursor + 1) % _party_battlers.size()
		_rebuild_item_target_list()
		if cursor_move_sfx:
			SfxManager.play(cursor_move_sfx)
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
		if confirm_sfx:
			SfxManager.play(confirm_sfx)
		_show_command_menu()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("cancel"):
		_item_target_panel.visible = false
		_item_panel.visible = true
		_battle_phase = BattlePhase.ITEM_SELECT
		if cancel_sfx:
			SfxManager.play(cancel_sfx)
		get_viewport().set_input_as_handled()

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
		if run_fail_sfx:
			SfxManager.play(run_fail_sfx)
		await _show_battle_message_await("Can't escape!")
		_command_index = _party_battlers.size()
		_command_panel.visible = false
		_resolve_round()

# --- TURN RESOLUTION ---

func _resolve_round() -> void:
	_battle_phase = BattlePhase.RESOLVING

	for i: int in _enemy_battlers.size():
		if _enemy_battlers[i].is_dead():
			continue
		var cmd := BattleCommand.new()
		cmd.type = CommandType.ATTACK
		cmd.actor_index = i
		cmd.is_enemy_command = true
		var alive_indices := _get_alive_party_indices()
		if alive_indices.is_empty():
			continue
		cmd.target_index = BattleFormulas.pick_party_target(_party_battlers, alive_indices)
		_commands.append(cmd)

	var actions: Array[Dictionary] = []
	for cmd: BattleCommand in _commands:
		if cmd.target_index == -1 and cmd.type == CommandType.ATTACK:
			continue
		var actor_b: Battler
		if cmd.is_enemy_command:
			actor_b = _enemy_battlers[cmd.actor_index]
		else:
			actor_b = _party_battlers[cmd.actor_index]
		actions.append({
			"cmd": cmd,
			"actor": actor_b,
			"is_enemy": cmd.is_enemy_command,
			"agility": actor_b.agility + randf() * 0.5,
		})

	actions.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["agility"] > b["agility"])

	_battle_phase = BattlePhase.ANIMATING
	await _execute_actions(actions)

func _execute_actions(actions: Array[Dictionary]) -> void:
	for action: Dictionary in actions:
		var cmd: BattleCommand = action["cmd"]
		var actor: Battler = action["actor"]
		var is_enemy: bool = action["is_enemy"]

		if actor.is_dead():
			continue

		match cmd.type:
			CommandType.ATTACK:
				await _execute_attack(actor, cmd, is_enemy)
			CommandType.ITEM:
				await _execute_item(actor, cmd)

		_update_hud()

		if _check_all_enemies_dead():
			_start_victory()
			return
		if _check_all_party_dead():
			_start_game_over()
			return

	_begin_command_phase()

func _execute_attack(actor: Battler, cmd: BattleCommand, is_enemy: bool) -> void:
	var target: Battler
	if is_enemy:
		# Enemy attacks party
		var idx := cmd.target_index
		if idx >= 0 and idx < _party_battlers.size() and _party_battlers[idx].is_dead():
			idx = _retarget_party(idx)
		if idx < 0:
			return
		target = _party_battlers[idx]
	else:
		# Party attacks enemy
		var idx := cmd.target_index
		if idx >= 0 and idx < _enemy_battlers.size() and _enemy_battlers[idx].is_dead():
			idx = _retarget_enemy(idx)
		if idx < 0:
			return
		target = _enemy_battlers[idx]

	# Attack animation
	if is_enemy:
		await _animate_enemy_attack(actor)
	else:
		await _animate_party_attack(actor, target)

	# Multi-hit resolution
	var total_damage := 0
	for hit_i: int in actor.max_hits:
		var hit := BattleFormulas.hit_check(actor.accuracy, target.evade)
		if hit:
			var is_crit := BattleFormulas.crit_check(actor.crit_rate)
			var dmg := BattleFormulas.physical_damage(actor.attack_power, target.defense, is_crit)
			total_damage += dmg
			target.take_damage(dmg)

			await _show_damage_number(target.sprite.position, dmg, is_crit)
			_flash_sprite(target.sprite)

			if is_crit and critical_hit_sfx:
				SfxManager.play(critical_hit_sfx)
			elif attack_hit_sfx:
				SfxManager.play(attack_hit_sfx)
		else:
			await _show_miss(target.sprite.position)
			if attack_miss_sfx:
				SfxManager.play(attack_miss_sfx)

		_update_hud()

		if target.is_dead():
			if not target.is_party:
				await _kill_enemy(target)
			break

		if hit_i < actor.max_hits - 1:
			await get_tree().create_timer(0.15).timeout

func _execute_item(actor: Battler, cmd: BattleCommand) -> void:
	if actor.is_dead():
		return
	var target: Battler = _party_battlers[cmd.target_index]
	var item: ItemData = cmd.item
	if not party_data.use_item(item, target.character_data):
		return
	target.current_hp = target.character_data.current_hp
	await _show_damage_number(target.sprite.position, item.potency, false, true)

# --- ANIMATIONS ---

func _animate_party_attack(actor: Battler, target: Battler) -> void:
	if attack_swing_sfx:
		SfxManager.play(attack_swing_sfx)
	var lunge_pos := Vector2(target.sprite.position.x + 60, actor.sprite.position.y)
	var tween := create_tween()
	tween.tween_property(actor.sprite, "position", lunge_pos, 0.15)
	tween.tween_interval(0.1)
	tween.tween_property(actor.sprite, "position", actor.home_position, 0.15)
	await tween.finished

func _animate_enemy_attack(actor: Battler) -> void:
	if attack_swing_sfx:
		SfxManager.play(attack_swing_sfx)
	var tween := create_tween()
	tween.tween_property(actor.sprite, "modulate", Color(3, 3, 3), 0.0)
	tween.tween_interval(0.1)
	tween.tween_property(actor.sprite, "modulate", Color.WHITE, 0.0)
	await tween.finished

func _flash_sprite(sprite: Sprite2D) -> void:
	var tween := create_tween()
	tween.tween_property(sprite, "modulate", Color(3, 3, 3), 0.0)
	tween.tween_interval(0.05)
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.0)

func _show_damage_number(pos: Vector2, amount: int, is_crit: bool, is_heal := false) -> void:
	var label := Label.new()
	label.text = str(amount)
	label.position = pos + Vector2(-20, -40)
	label.add_theme_font_size_override("font_size", 24)
	if is_heal:
		label.add_theme_color_override("font_color", Color.GREEN)
	elif is_crit:
		label.add_theme_color_override("font_color", Color.YELLOW)
	_damage_container.add_child(label)

	var tween := create_tween()
	tween.tween_property(label, "position:y", label.position.y - 40, 0.6)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.6).set_delay(0.3)
	tween.tween_callback(label.queue_free)
	await get_tree().create_timer(0.3).timeout

func _show_miss(pos: Vector2) -> void:
	var label := Label.new()
	label.text = "Miss"
	label.position = pos + Vector2(-20, -40)
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	_damage_container.add_child(label)

	var tween := create_tween()
	tween.tween_property(label, "position:y", label.position.y - 30, 0.5)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.5).set_delay(0.2)
	tween.tween_callback(label.queue_free)
	await get_tree().create_timer(0.25).timeout

func _kill_enemy(enemy: Battler) -> void:
	if enemy_death_sfx:
		SfxManager.play(enemy_death_sfx)
	var tween := create_tween()
	tween.tween_property(enemy.sprite, "modulate:a", 0.0, 0.3)
	await tween.finished

# --- RETARGETING ---

func _retarget_enemy(original: int) -> int:
	for i: int in _enemy_battlers.size():
		var idx := (original + i) % _enemy_battlers.size()
		if not _enemy_battlers[idx].is_dead():
			return idx
	return -1

func _retarget_party(original: int) -> int:
	for i: int in _party_battlers.size():
		var idx := (original + i) % _party_battlers.size()
		if not _party_battlers[idx].is_dead():
			return idx
	return -1

# --- BATTLE END CHECKS ---

func _check_all_enemies_dead() -> bool:
	for b: Battler in _enemy_battlers:
		if not b.is_dead():
			return false
	return true

func _check_all_party_dead() -> bool:
	for b: Battler in _party_battlers:
		if not b.is_dead():
			return false
	return true

# --- VICTORY ---

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
	_victory_exp_each = exp_each
	_victory_level_ups.clear()

	for b: Battler in _party_battlers:
		if not b.is_dead() and b.character_data:
			var ups := b.character_data.add_exp(exp_each)
			if not ups.is_empty():
				_victory_level_ups.append({"name": b.display_name, "ups": ups})

var _victory_state := 0
var _victory_exp_each := 0
var _victory_level_ups: Array[Dictionary] = []
var _victory_level_index := 0

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
	if level_up_sfx:
		SfxManager.play(level_up_sfx)

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
	var tween := create_tween()
	tween.tween_property(_transition_rect, "color", Color(0, 0, 0, 1), 0.3)
	tween.tween_callback(func() -> void: _battle_container.visible = false)
	tween.tween_property(_transition_rect, "color", Color(0, 0, 0, 0), 0.3)
	tween.tween_callback(func() -> void: _transition_rect.visible = false)
	await tween.finished

func _cleanup_battle() -> void:
	for child: Node in _battler_container.get_children():
		child.queue_free()
	for child: Node in _damage_container.get_children():
		child.queue_free()
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

	var tween := create_tween()
	tween.tween_property(_game_over_overlay, "color", Color(0, 0, 0, 0.85), 1.0)
	tween.tween_callback(func() -> void: _game_over_label.visible = true)
	await tween.finished

func _handle_game_over_input(event: InputEvent) -> void:
	if event.is_action_pressed("confirm"):
		get_viewport().set_input_as_handled()
		get_tree().change_scene_to_file("res://title_screen.tscn")

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

func _get_alive_enemy_indices() -> Array[int]:
	var result: Array[int] = []
	for i: int in _enemy_battlers.size():
		if not _enemy_battlers[i].is_dead():
			result.append(i)
	return result

func _get_alive_party_indices() -> Array[int]:
	var result: Array[int] = []
	for i: int in _party_battlers.size():
		if not _party_battlers[i].is_dead():
			result.append(i)
	return result
