extends Node

signal battle_started(party_data: Array, enemy_data: Array)
signal battle_ended
signal atb_updated(combatant_index: int, is_player: bool, value: float)
signal command_ready_changed(combatant_index: int, is_ready: bool)
signal party_hp_changed(combatant_index: int, current_hp: int, max_hp: int)
signal enemy_hp_changed(enemy_index: int, enemy_name: String, current_hp: int, max_hp: int)
signal damage_dealt(world_position: Vector2, amount: int, is_critical: bool)
signal heal_applied(world_position: Vector2, amount: int)
signal victory_achieved(total_exp: int, total_gold: int, total_tp: int)
signal player_defeated
signal enemy_died(enemy_index: int)
signal combatant_ko(combatant_index: int)
signal active_member_changed(combatant_index: int)
signal submenu_entered
signal submenu_exited
signal escaped

const ATB_SCALE := 0.02
const ESCAPE_RATE := 0.5

enum BattleMode { ACTIVE, WAIT }

@export var battle_music: AudioStream

var battle_mode: BattleMode = BattleMode.ACTIVE

var _party: Array = []
var _enemies: Array = []
var _enemy_nodes: Array = []
var _ready_queue: Array = []
var _active_member_index := -1
var _animating := false
var _battle_finished := false
var _in_submenu := false
var _escape_gauge := 0.0
var _is_boss_fight := false
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	add_to_group(Groups.BATTLE_MANAGER)
	_rng.randomize()

func _process(delta: float) -> void:
	if GameState.current != GameState.State.BATTLE:
		return
	if _battle_finished:
		return

	_process_escape(delta)

	if _animating:
		return

	var should_pause := battle_mode == BattleMode.WAIT and _in_submenu

	for i in _party.size():
		if _party[i]["is_ko"]:
			continue
		if should_pause and i != _active_member_index:
			continue
		_party[i]["atb"] = minf(1.0, _party[i]["atb"] + _party[i]["data"].speed * delta * ATB_SCALE)
		atb_updated.emit(i, true, _party[i]["atb"])
		if _party[i]["atb"] >= 1.0 and i not in _ready_queue and i != _active_member_index:
			_ready_queue.append(i)

	for i in _enemies.size():
		if _enemies[i]["is_dead"]:
			continue
		if should_pause:
			continue
		_enemies[i]["atb"] = minf(1.0, _enemies[i]["atb"] + _enemies[i]["data"].speed * delta * ATB_SCALE)
		if _enemies[i]["atb"] >= 1.0:
			_enemies[i]["atb"] = 0.0
			_enemy_act(i)
			return

	if _active_member_index == -1 and _ready_queue.size() > 0:
		_active_member_index = _ready_queue.pop_front()
		active_member_changed.emit(_active_member_index)
		command_ready_changed.emit(_active_member_index, true)

func start_battle(triggering_enemy: Area2D) -> void:
	var party_manager := get_tree().get_first_node_in_group(Groups.PARTY_MANAGER)
	if party_manager == null:
		return

	_party.clear()
	for m in party_manager.members:
		_party.append({
			"data": m["data"],
			"current_hp": m["current_hp"],
			"max_hp": m["data"].max_hp,
			"is_ko": m["is_ko"],
			"atb": 0.0,
			"node": m["node"],
		})

	_enemies.clear()
	_enemy_nodes.clear()
	_is_boss_fight = false

	if triggering_enemy.encounter_group != "":
		for node in get_tree().get_nodes_in_group("enemy_" + triggering_enemy.encounter_group):
			_add_enemy(node)
	else:
		_add_enemy(triggering_enemy)

	for e in _enemy_nodes:
		e.set_battle_collision_enabled(false)

	_ready_queue.clear()
	_active_member_index = -1
	_animating = false
	_battle_finished = false
	_in_submenu = false
	_escape_gauge = 0.0

	GameState.change(GameState.State.BATTLE)

	var party_info: Array = []
	for p in _party:
		party_info.append({ "name": p["data"].character_name, "hp": p["current_hp"], "max_hp": p["max_hp"], "is_ko": p["is_ko"] })
	var enemy_info: Array = []
	for e in _enemies:
		enemy_info.append({ "name": e["data"].enemy_name, "hp": e["current_hp"], "max_hp": e["max_hp"] })

	battle_started.emit(party_info, enemy_info)
	MusicManager.play_music(battle_music)

func _add_enemy(node: Area2D) -> void:
	_enemy_nodes.append(node)
	node.battle_started = true
	node.set_deferred("monitoring", false)
	if node.is_boss:
		_is_boss_fight = true
	_enemies.append({
		"data": node.data,
		"current_hp": int(node.data.get("max_hp")),
		"max_hp": int(node.data.get("max_hp")),
		"is_dead": false,
		"atb": 0.0,
		"node": node,
	})

func _consume_active_turn() -> int:
	var member_idx := _active_member_index
	_active_member_index = -1
	_in_submenu = false
	_party[member_idx]["atb"] = 0.0
	atb_updated.emit(member_idx, true, 0.0)
	return member_idx

func _on_attack_selected(target_index: int) -> void:
	if _active_member_index == -1 or _animating or _battle_finished:
		return
	if target_index < 0 or target_index >= _enemies.size():
		return
	if _enemies[target_index]["is_dead"]:
		return

	var member_idx := _consume_active_turn()
	var p: Dictionary = _party[member_idx]

	var damage_result := _calculate_damage(p["data"].power, p["data"].weapon_ap, int(_enemies[target_index]["data"].get("stamina")), p["data"].strike_percent)
	await _play_attack_sequence(p["node"], _enemies[target_index]["node"], damage_result["damage"], damage_result["critical"])

	_enemies[target_index]["current_hp"] = max(0, _enemies[target_index]["current_hp"] - damage_result["damage"])
	enemy_hp_changed.emit(target_index, str(_enemies[target_index]["data"].get("enemy_name")), _enemies[target_index]["current_hp"], _enemies[target_index]["max_hp"])

	if _enemies[target_index]["current_hp"] <= 0:
		_enemies[target_index]["is_dead"] = true
		enemy_died.emit(target_index)
		await _enemies[target_index]["node"].play_death()

	_check_battle_end()

func _on_item_used(item: ItemData, target_member_index: int) -> void:
	if _active_member_index == -1 or _animating or _battle_finished:
		return
	if target_member_index < 0 or target_member_index >= _party.size():
		return

	var member_idx := _consume_active_turn()

	var inventory := get_tree().get_first_node_in_group(Groups.INVENTORY)
	if inventory:
		inventory.remove_item(item)

	var target: Dictionary = _party[target_member_index]
	var old_hp: int = target["current_hp"]
	target["current_hp"] = mini(target["current_hp"] + item.heal_amount, target["max_hp"])
	var healed: int = target["current_hp"] - old_hp

	party_hp_changed.emit(target_member_index, target["current_hp"], target["max_hp"])
	heal_applied.emit(target["node"].global_position, healed)

func _enemy_act(enemy_index: int) -> void:
	if _animating or _battle_finished:
		return

	var living := get_living_party()
	if living.is_empty():
		return

	var target_idx: int = living[_rng.randi() % living.size()]
	var e: Dictionary = _enemies[enemy_index]
	var p: Dictionary = _party[target_idx]

	var damage_result := _calculate_damage(int(e["data"].get("power")), 0, p["data"].stamina, 0.0)
	await _play_attack_sequence(e["node"], p["node"], damage_result["damage"], damage_result["critical"])

	p["current_hp"] = max(0, p["current_hp"] - damage_result["damage"])
	party_hp_changed.emit(target_idx, p["current_hp"], p["max_hp"])

	if p["current_hp"] <= 0:
		p["is_ko"] = true
		combatant_ko.emit(target_idx)
		if target_idx in _ready_queue:
			_ready_queue.erase(target_idx)
		if _active_member_index == target_idx:
			_active_member_index = -1

	_check_battle_end()

func _calculate_damage(power: int, weapon_ap: int, stamina: int, strike_percent: float) -> Dictionary:
	var attack: int = power + weapon_ap
	var raw_damage: int = maxi(1, attack - stamina)
	var damage: int = maxi(1, int(round(raw_damage * _rng.randf_range(0.9, 1.1))))
	var critical: bool = _rng.randf() * 100.0 < strike_percent
	if critical:
		damage *= 2
	return { "damage": damage, "critical": critical }

func _play_attack_sequence(attacker: Node2D, target: Node2D, damage: int, critical: bool) -> void:
	_animating = true

	attacker.play_attack()

	var start_position := attacker.global_position
	var direction := (target.global_position - attacker.global_position).normalized()
	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT
	var lunge_position := start_position + direction * 16.0

	var lunge := create_tween()
	lunge.tween_property(attacker, "global_position", lunge_position, 0.15)
	await lunge.finished

	target.play_hit(direction)
	var flash_effect := target.get_node_or_null("FlashEffect")
	if flash_effect:
		flash_effect.flash()
	damage_dealt.emit(target.global_position, damage, critical)
	await get_tree().create_timer(0.3).timeout

	var retreat := create_tween()
	retreat.tween_property(attacker, "global_position", start_position, 0.15)
	await retreat.finished

	if not _battle_finished:
		attacker.play_idle()
	if _is_target_alive(target):
		target.play_idle()

	_animating = false

func _is_target_alive(target: Node2D) -> bool:
	for e in _enemies:
		if e["node"] == target:
			return not e["is_dead"]
	for p in _party:
		if p["node"] == target:
			return not p["is_ko"]
	return false

func _process_escape(delta: float) -> void:
	if _is_boss_fight:
		return
	if Input.is_action_pressed("escape_left") and Input.is_action_pressed("escape_right"):
		_escape_gauge += ESCAPE_RATE * delta
		if _escape_gauge >= 1.0:
			_battle_finished = true
			_write_back_state()
			MusicManager.stop_music()
			escaped.emit()
			battle_ended.emit()
			_free_enemies()
			_active_member_index = -1
			GameState.change(GameState.State.FIELD)
	else:
		_escape_gauge = maxf(0.0, _escape_gauge - ESCAPE_RATE * delta * 0.5)

func _check_battle_end() -> void:
	if _battle_finished:
		return

	var all_enemies_dead := true
	for e in _enemies:
		if not e["is_dead"]:
			all_enemies_dead = false
			break

	if all_enemies_dead:
		_victory()
		return

	var all_party_ko := true
	for p in _party:
		if not p["is_ko"]:
			all_party_ko = false
			break

	if all_party_ko:
		_game_over()

func _victory() -> void:
	_battle_finished = true
	command_ready_changed.emit(0, false)
	MusicManager.stop_music()
	_write_back_state()

	var total_exp := 0
	var total_gold := 0
	var total_tp := 0
	for e in _enemies:
		total_exp += int(e["data"].get("exp_reward"))
		total_gold += int(e["data"].get("gold_reward"))
		total_tp += int(e["data"].get("tp_reward"))

	victory_achieved.emit(total_exp, total_gold, total_tp)
	await get_tree().create_timer(2.0).timeout
	battle_ended.emit()

	_free_enemies()
	_active_member_index = -1
	GameState.change(GameState.State.FIELD)

func _game_over() -> void:
	_battle_finished = true
	player_defeated.emit()
	MusicManager.stop_music()
	await get_tree().create_timer(2.0).timeout
	get_tree().reload_current_scene()

func _write_back_state() -> void:
	var party_manager := get_tree().get_first_node_in_group(Groups.PARTY_MANAGER)
	if party_manager == null:
		return
	var state: Array = []
	for p in _party:
		state.append({ "current_hp": p["current_hp"] })
	party_manager.update_from_battle(state)

func _free_enemies() -> void:
	for node in _enemy_nodes:
		if is_instance_valid(node):
			node.queue_free()
	_enemy_nodes.clear()
	_enemies.clear()

func set_in_submenu(value: bool) -> void:
	_in_submenu = value
	if value:
		submenu_entered.emit()
	else:
		submenu_exited.emit()

func get_living_enemies() -> Array:
	var result: Array = []
	for i in _enemies.size():
		if not _enemies[i]["is_dead"]:
			result.append(i)
	return result

func get_living_party() -> Array:
	var result: Array = []
	for i in _party.size():
		if not _party[i]["is_ko"]:
			result.append(i)
	return result

func get_enemy_node(index: int) -> Node2D:
	if index >= 0 and index < _enemy_nodes.size():
		return _enemy_nodes[index]
	return null
