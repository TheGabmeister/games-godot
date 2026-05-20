class_name BattleResolver
extends Node

const Battler = BattleTypes.Battler
const BattleCommand = BattleTypes.BattleCommand
const CommandType = BattleTypes.CommandType

signal round_completed
signal battle_won
signal battle_lost
signal hud_update_requested
signal enemy_list_update_requested

var party_battlers: Array[Battler] = []
var enemy_battlers: Array[Battler] = []
var party_data: PartyData
var damage_container: Node2D

var attack_swing_sfx: AudioStream
var attack_hit_sfx: AudioStream
var attack_miss_sfx: AudioStream
var critical_hit_sfx: AudioStream
var enemy_death_sfx: AudioStream

func resolve_round(commands: Array[BattleCommand]) -> void:
	for i: int in enemy_battlers.size():
		if enemy_battlers[i].is_dead():
			continue
		var cmd := BattleCommand.new()
		cmd.type = CommandType.ATTACK
		cmd.actor_index = i
		cmd.is_enemy_command = true
		var alive_indices := get_alive_indices(party_battlers)
		if alive_indices.is_empty():
			continue
		cmd.target_index = BattleFormulas.pick_party_target(alive_indices)
		commands.append(cmd)

	var actions: Array[Dictionary] = []
	for cmd: BattleCommand in commands:
		if cmd.target_index == -1 and cmd.type == CommandType.ATTACK:
			continue
		var actor_b: Battler
		if cmd.is_enemy_command:
			actor_b = enemy_battlers[cmd.actor_index]
		else:
			actor_b = party_battlers[cmd.actor_index]
		actions.append({
			"cmd": cmd,
			"actor": actor_b,
			"is_enemy": cmd.is_enemy_command,
			"agility": actor_b.agility + randf() * 0.5,
		})

	actions.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["agility"] > b["agility"])
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

		hud_update_requested.emit()

		if _all_dead(enemy_battlers):
			battle_won.emit()
			return
		if _all_dead(party_battlers):
			battle_lost.emit()
			return

	round_completed.emit()

func _execute_attack(actor: Battler, cmd: BattleCommand, is_enemy: bool) -> void:
	var target: Battler
	if is_enemy:
		var idx := cmd.target_index
		if idx >= 0 and idx < party_battlers.size() and party_battlers[idx].is_dead():
			idx = _retarget(party_battlers, idx)
		if idx < 0:
			return
		target = party_battlers[idx]
	else:
		var idx := cmd.target_index
		if idx >= 0 and idx < enemy_battlers.size() and enemy_battlers[idx].is_dead():
			idx = _retarget(enemy_battlers, idx)
		if idx < 0:
			return
		target = enemy_battlers[idx]

	if is_enemy:
		await _animate_enemy_attack(actor)
	else:
		await _animate_party_attack(actor, target)

	var _total_damage := 0
	for hit_i: int in actor.max_hits:
		var hit := BattleFormulas.hit_check(actor.accuracy, target.evade)
		if hit:
			var is_crit := BattleFormulas.crit_check(actor.crit_rate)
			var dmg := BattleFormulas.physical_damage(actor.attack_power, target.defense, is_crit)
			_total_damage += dmg
			target.take_damage(dmg)

			await _show_damage_number(target.sprite.position, dmg, is_crit)
			_flash_sprite(target.sprite)

			if is_crit and critical_hit_sfx:
				_play_sfx(critical_hit_sfx)
			else:
				_play_sfx(attack_hit_sfx)
		else:
			await _show_miss(target.sprite.position)
			_play_sfx(attack_miss_sfx)

		hud_update_requested.emit()

		if target.is_dead():
			if not target.is_party:
				await _kill_enemy(target)
			break

		if hit_i < actor.max_hits - 1:
			await get_tree().create_timer(0.15).timeout

func _execute_item(actor: Battler, cmd: BattleCommand) -> void:
	if actor.is_dead():
		return
	var target: Battler = party_battlers[cmd.target_index]
	var item: ItemData = cmd.item
	if not party_data.use_item(item, target.character_data):
		return
	target.current_hp = target.character_data.current_hp
	await _show_damage_number(target.sprite.position, item.potency, false, true)

# --- ANIMATIONS ---

func _animate_party_attack(actor: Battler, target: Battler) -> void:
	_play_sfx(attack_swing_sfx)
	var lunge_pos := Vector2(target.sprite.position.x + 60, actor.sprite.position.y)
	var tw := create_tween()
	var _t1 := tw.tween_property(actor.sprite, "position", lunge_pos, 0.15)
	var _t2 := tw.tween_interval(0.1)
	var _t3 := tw.tween_property(actor.sprite, "position", actor.home_position, 0.15)
	await tw.finished

func _animate_enemy_attack(actor: Battler) -> void:
	_play_sfx(attack_swing_sfx)
	var tw := create_tween()
	var _t1 := tw.tween_property(actor.sprite, "modulate", Color(3, 3, 3), 0.0)
	var _t2 := tw.tween_interval(0.1)
	var _t3 := tw.tween_property(actor.sprite, "modulate", Color.WHITE, 0.0)
	await tw.finished

func _flash_sprite(sprite: Sprite2D) -> void:
	var tw := create_tween()
	var _t1 := tw.tween_property(sprite, "modulate", Color(3, 3, 3), 0.0)
	var _t2 := tw.tween_interval(0.05)
	var _t3 := tw.tween_property(sprite, "modulate", Color.WHITE, 0.0)

func _show_damage_number(pos: Vector2, amount: int, is_crit: bool, is_heal := false) -> void:
	var label := Label.new()
	label.text = str(amount)
	label.position = pos + Vector2(-20, -40)
	label.add_theme_font_size_override("font_size", 24)
	if is_heal:
		label.add_theme_color_override("font_color", Color.GREEN)
	elif is_crit:
		label.add_theme_color_override("font_color", Color.YELLOW)
	damage_container.add_child(label)

	var tw := create_tween()
	var _t1 := tw.tween_property(label, "position:y", label.position.y - 40, 0.6)
	var _t2 := tw.parallel().tween_property(label, "modulate:a", 0.0, 0.6).set_delay(0.3)
	var _t3 := tw.tween_callback(label.queue_free)
	await get_tree().create_timer(0.3).timeout

func _show_miss(pos: Vector2) -> void:
	var label := Label.new()
	label.text = "Miss"
	label.position = pos + Vector2(-20, -40)
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	damage_container.add_child(label)

	var tw := create_tween()
	var _t1 := tw.tween_property(label, "position:y", label.position.y - 30, 0.5)
	var _t2 := tw.parallel().tween_property(label, "modulate:a", 0.0, 0.5).set_delay(0.2)
	var _t3 := tw.tween_callback(label.queue_free)
	await get_tree().create_timer(0.25).timeout

func _kill_enemy(enemy: Battler) -> void:
	_play_sfx(enemy_death_sfx)
	var tw := create_tween()
	var _t1 := tw.tween_property(enemy.sprite, "modulate:a", 0.0, 0.3)
	await tw.finished
	enemy_list_update_requested.emit()

# --- HELPERS ---

func _play_sfx(stream: AudioStream, volume_db := 0.0) -> void:
	if stream:
		SfxManager.play(stream, volume_db)

func get_alive_indices(battlers: Array[Battler]) -> Array[int]:
	var result: Array[int] = []
	for i: int in battlers.size():
		if not battlers[i].is_dead():
			result.append(i)
	return result

func _retarget(battlers: Array[Battler], original: int) -> int:
	for i: int in battlers.size():
		var idx := (original + i) % battlers.size()
		if not battlers[idx].is_dead():
			return idx
	return -1

func _all_dead(battlers: Array[Battler]) -> bool:
	for b: Battler in battlers:
		if not b.is_dead():
			return false
	return true
