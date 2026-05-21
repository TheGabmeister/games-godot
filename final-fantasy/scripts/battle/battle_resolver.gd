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

@onready var damage_container: Node2D = %DamageContainer

@export var attack_swing_sfx: AudioStream
@export var attack_hit_sfx: AudioStream
@export var attack_miss_sfx: AudioStream
@export var critical_hit_sfx: AudioStream
@export var enemy_death_sfx: AudioStream

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
		if actor.statuses.get(&"sleep", 0) != 0:
			await _show_status_text(actor.sprite.position, "Sleep")
			continue

		match cmd.type:
			CommandType.ATTACK:
				await _execute_attack(actor, cmd, is_enemy)
			CommandType.ITEM:
				await _execute_item(actor, cmd)
			CommandType.MAGIC:
				await _execute_spell(actor, cmd, is_enemy)

		hud_update_requested.emit()

		if _all_dead(enemy_battlers):
			battle_won.emit()
			return
		if _all_dead(party_battlers):
			battle_lost.emit()
			return

	_tick_statuses()
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

	var effective_accuracy := actor.accuracy
	if actor.statuses.get(&"darkness", 0) != 0:
		effective_accuracy -= 40
	var effective_atk := actor.attack_power + actor.buff_atk
	var effective_def := target.defense + target.buff_def
	var effective_evade := target.evade + target.buff_evade
	var effective_hits := maxi(1, actor.max_hits + actor.debuff_hits)

	var _total_damage := 0
	for hit_i: int in effective_hits:
		var hit := BattleFormulas.hit_check(effective_accuracy, effective_evade)
		if hit:
			var is_crit := BattleFormulas.crit_check(actor.crit_rate)
			var dmg := BattleFormulas.physical_damage(effective_atk, effective_def, is_crit)
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

		if target.statuses.get(&"sleep", 0) != 0:
			target.statuses[&"sleep"] = 0
			_update_status_indicators(target)

		if target.is_dead():
			if not target.is_party:
				await _kill_enemy(target)
			break

		if hit_i < effective_hits - 1:
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

func _execute_spell(actor: Battler, cmd: BattleCommand, is_enemy: bool) -> void:
	var spell: SpellData = cmd.spell
	if actor.character_data:
		var _spent := actor.character_data.spend_charge(spell.level)

	var targets: Array[Battler] = _resolve_spell_targets(spell, cmd, is_enemy)
	if targets.is_empty():
		return

	if spell.sfx:
		_play_sfx(spell.sfx)
	_flash_spell_color(spell.element)
	await _show_status_text(actor.sprite.position, spell.spell_name)

	for target: Battler in targets:
		if target.is_dead():
			continue
		for entry: SpellEffectEntry in spell.effects:
			await _apply_spell_effect(entry, spell, actor, target)
		hud_update_requested.emit()

func _apply_spell_effect(entry: SpellEffectEntry, spell: SpellData, _actor: Battler, target: Battler) -> void:
	match entry.type:
		SpellData.SpellEffect.DAMAGE:
			var weaknesses: Array[SpellData.Element] = []
			if target.enemy_data:
				weaknesses = target.enemy_data.weaknesses
			_play_spell_vfx(spell.element, entry.type, target.sprite.position)
			var hit := true
			if spell.spell_accuracy > 0:
				hit = BattleFormulas.spell_hit_with_element(spell.spell_accuracy, target.magic_defense, spell.element, weaknesses)
			if hit:
				var raw := BattleFormulas.magic_damage(entry.power)
				var result: Dictionary = BattleFormulas.apply_elemental_modifiers(raw, spell.element, weaknesses, target.resistances)
				var dmg: int = result["damage"]
				target.take_damage(dmg)
				await _show_damage_number(target.sprite.position, dmg, false)
				_flash_sprite(target.sprite)
				if result["weak"]:
					await _show_popup_text(target.sprite.position, "Weak!", Color(1.0, 0.6, 0.2))
				elif result["resist"]:
					await _show_popup_text(target.sprite.position, "Resist!", Color(0.4, 0.6, 1.0))
			else:
				var raw := BattleFormulas.magic_damage(entry.power)
				var half := maxi(1, floori(float(raw) * 0.5))
				target.take_damage(half)
				await _show_damage_number(target.sprite.position, half, false)
			if target.is_dead() and not target.is_party:
				await _kill_enemy(target)

		SpellData.SpellEffect.HEAL:
			_play_spell_vfx(spell.element, entry.type, target.sprite.position)
			var amount := BattleFormulas.magic_damage(entry.power)
			target.heal(amount)
			await _show_damage_number(target.sprite.position, amount, false, true)

		SpellData.SpellEffect.BUFF:
			_shimmer_sprite(target.sprite, Color(1.0, 0.9, 0.5))
			if entry.resist_element != SpellData.Element.NONE:
				if entry.resist_element not in target.resistances:
					target.resistances.append(entry.resist_element)
				await _show_status_text(target.sprite.position, spell.spell_name)
			else:
				_apply_buff(target, entry.buff_stat, entry.buff_amount)
				var sign_str := "+" if entry.buff_amount > 0 else ""
				await _show_status_text(target.sprite.position, "%s%d %s" % [sign_str, entry.buff_amount, entry.buff_stat.to_upper()])

		SpellData.SpellEffect.DEBUFF:
			var weaknesses: Array[SpellData.Element] = []
			if target.enemy_data:
				weaknesses = target.enemy_data.weaknesses
			var hit := true
			if spell.spell_accuracy > 0:
				hit = BattleFormulas.spell_hit_with_element(spell.spell_accuracy, target.magic_defense, spell.element, weaknesses)
			if hit:
				_shimmer_sprite(target.sprite, Color(0.7, 0.4, 0.9))
				_apply_buff(target, entry.buff_stat, entry.buff_amount)
				var sign_str := "+" if entry.buff_amount > 0 else ""
				await _show_status_text(target.sprite.position, "%s%d %s" % [sign_str, entry.buff_amount, entry.buff_stat.to_upper()])
			else:
				await _show_miss(target.sprite.position)

		SpellData.SpellEffect.STATUS_INFLICT:
			var weaknesses: Array[SpellData.Element] = []
			if target.enemy_data:
				weaknesses = target.enemy_data.weaknesses
			var hit := BattleFormulas.spell_hit_with_element(spell.spell_accuracy, target.magic_defense, spell.element, weaknesses)
			if hit:
				target.statuses[entry.status_name] = -1
				_update_status_indicators(target)
				await _show_status_text(target.sprite.position, entry.status_name.capitalize())
			else:
				await _show_miss(target.sprite.position)

		SpellData.SpellEffect.STATUS_CURE:
			target.statuses[entry.status_name] = 0
			_update_status_indicators(target)
			await _show_status_text(target.sprite.position, "Cured")

func _apply_buff(target: Battler, stat: StringName, amount: int) -> void:
	match stat:
		&"atk":
			target.buff_atk += amount
		&"def":
			target.buff_def += amount
		&"evade":
			target.buff_evade += amount
		&"hits":
			target.debuff_hits += amount

func _resolve_spell_targets(spell: SpellData, cmd: BattleCommand, is_enemy: bool) -> Array[Battler]:
	var targets: Array[Battler] = []
	match spell.target_type:
		SpellData.TargetType.SINGLE_ENEMY:
			var pool := party_battlers if is_enemy else enemy_battlers
			var idx := cmd.target_index
			if idx >= 0 and idx < pool.size():
				if pool[idx].is_dead():
					idx = _retarget(pool, idx)
				if idx >= 0:
					targets.append(pool[idx])
		SpellData.TargetType.ALL_ENEMIES:
			var pool := party_battlers if is_enemy else enemy_battlers
			for b: Battler in pool:
				if not b.is_dead():
					targets.append(b)
		SpellData.TargetType.SINGLE_ALLY:
			var pool := enemy_battlers if is_enemy else party_battlers
			var idx := cmd.target_index
			if idx >= 0 and idx < pool.size():
				targets.append(pool[idx])
		SpellData.TargetType.ALL_ALLIES:
			var pool := enemy_battlers if is_enemy else party_battlers
			for b: Battler in pool:
				if not b.is_dead():
					targets.append(b)
		SpellData.TargetType.SELF:
			var pool := enemy_battlers if is_enemy else party_battlers
			if cmd.actor_index >= 0 and cmd.actor_index < pool.size():
				targets.append(pool[cmd.actor_index])
	return targets

func _tick_statuses() -> void:
	var all_battlers: Array[Battler] = []
	all_battlers.append_array(party_battlers)
	all_battlers.append_array(enemy_battlers)
	for b: Battler in all_battlers:
		if b.is_dead():
			continue
		for status_name: StringName in b.statuses:
			var val: int = b.statuses[status_name]
			if val > 0:
				b.statuses[status_name] = val - 1

const ELEMENT_COLORS: Dictionary = {
	SpellData.Element.FIRE: Color(1.0, 0.4, 0.2),
	SpellData.Element.ICE: Color(0.4, 0.8, 1.0),
	SpellData.Element.LIGHTNING: Color(1.0, 1.0, 0.3),
	SpellData.Element.DEATH: Color(1.0, 1.0, 0.8),
}

const ELEMENT_VFX: Dictionary = {
	SpellData.Element.FIRE: preload("res://_scenes/vfx/vfx_fire.tscn"),
	SpellData.Element.ICE: preload("res://_scenes/vfx/vfx_ice.tscn"),
	SpellData.Element.LIGHTNING: preload("res://_scenes/vfx/vfx_thunder.tscn"),
	SpellData.Element.DEATH: preload("res://_scenes/vfx/vfx_holy.tscn"),
}

const HEAL_VFX: PackedScene = preload("res://_scenes/vfx/vfx_heal.tscn")

func _flash_spell_color(element: SpellData.Element) -> void:
	var color: Color = ELEMENT_COLORS.get(element, Color(0.8, 0.8, 1.0))
	var canvas := damage_container.get_parent()
	if canvas:
		var tw := create_tween()
		var _t1 := tw.tween_property(canvas, "modulate", color, 0.0)
		var _t2 := tw.tween_interval(0.08)
		var _t3 := tw.tween_property(canvas, "modulate", Color.WHITE, 0.0)

func _spawn_vfx_at(pos: Vector2, vfx_scene: PackedScene) -> void:
	var vfx: GPUParticles2D = vfx_scene.instantiate()
	vfx.position = pos
	damage_container.add_child(vfx)
	var lifetime: float = vfx.lifetime
	var _c := get_tree().create_timer(lifetime + 0.2).timeout.connect(vfx.queue_free)

func _play_spell_vfx(element: SpellData.Element, effect_type: SpellData.SpellEffect, pos: Vector2) -> void:
	if effect_type == SpellData.SpellEffect.HEAL:
		_spawn_vfx_at(pos, HEAL_VFX)
		return
	var scene: PackedScene = ELEMENT_VFX.get(element)
	if scene:
		_spawn_vfx_at(pos, scene)

func _shimmer_sprite(sprite: Sprite2D, color: Color) -> void:
	var tw := create_tween()
	var _t1 := tw.tween_property(sprite, "modulate", color, 0.1)
	var _t2 := tw.tween_property(sprite, "modulate", Color.WHITE, 0.2)

func _show_popup_text(pos: Vector2, text: String, color: Color) -> void:
	var label := Label.new()
	label.text = text
	label.position = pos + Vector2(-25, -60)
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", color)
	damage_container.add_child(label)

	var tw := create_tween()
	var _t1 := tw.tween_property(label, "position:y", label.position.y - 20, 0.5)
	var _t2 := tw.parallel().tween_property(label, "modulate:a", 0.0, 0.5).set_delay(0.2)
	var _t3 := tw.tween_callback(label.queue_free)
	await get_tree().create_timer(0.3).timeout

const STATUS_INDICATOR_GROUP := &"status_indicator"

func _update_status_indicators(battler: Battler) -> void:
	if not battler.sprite:
		return
	for child: Node in battler.sprite.get_children():
		if child.is_in_group(STATUS_INDICATOR_GROUP):
			child.queue_free()

	if battler.statuses.get(&"sleep", 0) != 0:
		var label := Label.new()
		label.text = "Zzz"
		label.position = Vector2(-10, -50)
		label.add_theme_font_size_override("font_size", 14)
		label.add_theme_color_override("font_color", Color(0.7, 0.7, 1.0))
		label.add_to_group(STATUS_INDICATOR_GROUP)
		battler.sprite.add_child(label)
		var tw := create_tween().set_loops()
		var _t1 := tw.tween_property(label, "position:y", -55.0, 0.6)
		var _t2 := tw.tween_property(label, "position:y", -50.0, 0.6)

	if battler.statuses.get(&"darkness", 0) != 0:
		var overlay := ColorRect.new()
		overlay.color = Color(0.2, 0.0, 0.3, 0.4)
		overlay.size = Vector2(64, 96)
		overlay.position = Vector2(-32, -48)
		overlay.add_to_group(STATUS_INDICATOR_GROUP)
		battler.sprite.add_child(overlay)

	if battler.statuses.get(&"silence", 0) != 0:
		var label := Label.new()
		label.text = "X"
		label.position = Vector2(20, -40)
		label.add_theme_font_size_override("font_size", 16)
		label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
		label.add_to_group(STATUS_INDICATOR_GROUP)
		battler.sprite.add_child(label)

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

func _show_status_text(pos: Vector2, text: String) -> void:
	var label := Label.new()
	label.text = text
	label.position = pos + Vector2(-30, -50)
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", Color(0.6, 0.9, 1.0))
	damage_container.add_child(label)

	var tw := create_tween()
	var _t1 := tw.tween_property(label, "position:y", label.position.y - 30, 0.6)
	var _t2 := tw.parallel().tween_property(label, "modulate:a", 0.0, 0.6).set_delay(0.3)
	var _t3 := tw.tween_callback(label.queue_free)
	await get_tree().create_timer(0.35).timeout

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
