extends Node

const ATB_SCALE := 0.02
const PLAYER_MAX_HP := 70
const PLAYER_POWER := 5
const PLAYER_SPEED := 12
const PLAYER_STAMINA := 5
const PLAYER_STRIKE_PERCENT := 10.0
const PLAYER_WEAPON_AP := 3

@export var player_path: NodePath
@export var battle_ui_path: NodePath
@export var battle_music: AudioStream

@onready var player: CharacterBody2D = get_node(player_path)
@onready var battle_ui: CanvasLayer = get_node(battle_ui_path)

var _enemy: Area2D
var _enemy_data: Resource
var _player_hp := PLAYER_MAX_HP
var _enemy_hp := 0
var _player_atb := 0.0
var _enemy_atb := 0.0
var _player_command_ready := false
var _animating := false
var _battle_finished := false
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	_rng.randomize()
	battle_ui.attack_selected.connect(_on_attack_selected)

func _process(delta: float) -> void:
	if GameState.current != GameState.State.BATTLE:
		return
	if _enemy == null or _enemy_data == null:
		return
	if _animating or _battle_finished:
		return

	if not _player_command_ready:
		_player_atb = minf(1.0, _player_atb + PLAYER_SPEED * delta * ATB_SCALE)
		battle_ui.update_atb(_player_atb)
		if _player_atb >= 1.0:
			_player_command_ready = true
			battle_ui.set_command_ready(true)

	_enemy_atb = minf(1.0, _enemy_atb + _enemy_stat("speed") * delta * ATB_SCALE)
	if _enemy_atb >= 1.0:
		_enemy_atb = 0.0
		_enemy_attack()

func start_battle(enemy: Area2D) -> void:
	if enemy == null or enemy.data == null:
		return

	_enemy = enemy
	_enemy_data = enemy.data
	_enemy_hp = _enemy_stat("max_hp")
	_player_hp = PLAYER_MAX_HP
	_player_atb = 0.0
	_enemy_atb = 0.0
	_player_command_ready = false
	_animating = false
	_battle_finished = false

	_enemy.set_battle_collision_enabled(false)
	GameState.change(GameState.State.BATTLE)
	battle_ui.start_battle(_player_hp, PLAYER_MAX_HP, _enemy_name(), _enemy_hp, _enemy_stat("max_hp"))
	MusicManager.play_music(battle_music)

func _on_attack_selected() -> void:
	if GameState.current != GameState.State.BATTLE:
		return
	if not _player_command_ready or _animating or _battle_finished:
		return

	_player_command_ready = false
	_player_atb = 0.0
	battle_ui.update_atb(_player_atb)
	_player_attack()

func _player_attack() -> void:
	var damage_result := _calculate_damage(PLAYER_POWER, PLAYER_WEAPON_AP, _enemy_stat("stamina"), PLAYER_STRIKE_PERCENT)
	_play_attack_sequence(player, _enemy, damage_result["damage"], damage_result["critical"], true)

func _enemy_attack() -> void:
	if _enemy == null:
		return
	var damage_result := _calculate_damage(_enemy_stat("power"), 0, PLAYER_STAMINA, 0.0)
	_play_attack_sequence(_enemy, player, damage_result["damage"], damage_result["critical"], false)

func _calculate_damage(power: int, weapon_ap: int, stamina: int, strike_percent: float) -> Dictionary:
	var attack: int = power + weapon_ap
	var raw_damage: int = maxi(1, attack - stamina)
	var damage: int = maxi(1, int(round(raw_damage * _rng.randf_range(0.9, 1.1))))
	var critical: bool = _rng.randf() * 100.0 < strike_percent
	if critical:
		damage *= 2
	return { "damage": damage, "critical": critical }

func _play_attack_sequence(attacker: Node2D, target: Node2D, damage: int, critical: bool, player_is_attacker: bool) -> void:
	_animating = true
	battle_ui.set_command_ready(false)

	if attacker == player:
		_play_player_attack_animation()
	elif attacker.has_method("play_attack"):
		attacker.play_attack()

	var start_position := attacker.global_position
	var direction := (target.global_position - attacker.global_position).normalized()
	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT
	var lunge_position := start_position + direction * 16.0

	var lunge := create_tween()
	lunge.tween_property(attacker, "global_position", lunge_position, 0.15)
	await lunge.finished

	if player_is_attacker:
		_enemy_hp = max(0, _enemy_hp - damage)
		battle_ui.update_enemy_hp(_enemy_name(), _enemy_hp, _enemy_stat("max_hp"))
	else:
		_player_hp = max(0, _player_hp - damage)
		battle_ui.update_player_hp(_player_hp, PLAYER_MAX_HP)

	if target == player:
		_play_player_hit_animation(direction)
	elif target.has_method("play_hit"):
		target.play_hit()
	var flash_effect := target.get_node_or_null("FlashEffect")
	if flash_effect:
		flash_effect.flash()
	battle_ui.spawn_damage_number(target.global_position, damage, critical)
	await get_tree().create_timer(0.3).timeout

	var retreat := create_tween()
	retreat.tween_property(attacker, "global_position", start_position, 0.15)
	await retreat.finished

	if attacker == player:
		_play_player_idle_animation()
	elif attacker.has_method("play_idle") and not _battle_finished:
		attacker.play_idle()
	if target.has_method("play_idle") and target == _enemy and _enemy_hp > 0:
		target.play_idle()

	_animating = false
	_check_battle_end()
	if not _battle_finished and _player_command_ready:
		battle_ui.set_command_ready(true)

func _check_battle_end() -> void:
	if _battle_finished:
		return

	if _enemy_hp <= 0:
		_victory()
	elif _player_hp <= 0:
		_game_over()

func _victory() -> void:
	_battle_finished = true
	battle_ui.set_command_ready(false)
	MusicManager.stop_music()
	await _play_enemy_death()
	battle_ui.show_results(_enemy_stat("exp_reward"), _enemy_stat("gold_reward"), _enemy_stat("tp_reward"))
	await get_tree().create_timer(2.0).timeout
	battle_ui.hide_results()
	battle_ui.end_battle()
	if is_instance_valid(_enemy):
		_enemy.queue_free()
	_enemy = null
	_enemy_data = null
	GameState.change(GameState.State.FIELD)

func _game_over() -> void:
	_battle_finished = true
	battle_ui.show_game_over()
	MusicManager.stop_music()
	await get_tree().create_timer(2.0).timeout
	get_tree().reload_current_scene()

func _play_enemy_death() -> void:
	if not is_instance_valid(_enemy):
		return
	if _enemy.has_method("play_die"):
		_enemy.play_die()
	var tween := create_tween()
	tween.tween_property(_enemy, "modulate:a", 0.0, 0.4)
	await tween.finished

func _play_player_attack_animation() -> void:
	var sprite := player.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if sprite == null:
		return
	var animation_name := "attack_down"
	if player.has_method("get_facing_direction_name"):
		animation_name = "attack_" + player.get_facing_direction_name()
	if sprite.sprite_frames and sprite.sprite_frames.has_animation(animation_name):
		sprite.play(animation_name)

func _play_player_idle_animation() -> void:
	var sprite := player.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if sprite == null:
		return
	var animation_name := "idle_down"
	if player.has_method("get_facing_direction_name"):
		animation_name = "idle_" + player.get_facing_direction_name()
	if sprite.sprite_frames and sprite.sprite_frames.has_animation(animation_name):
		sprite.play(animation_name)

func _play_player_hit_animation(hit_direction: Vector2) -> void:
	_play_player_idle_animation()
	var start_position := player.global_position
	var recoil_direction := hit_direction
	if recoil_direction == Vector2.ZERO:
		recoil_direction = Vector2.LEFT
	var tween := create_tween()
	tween.tween_property(player, "global_position", start_position + recoil_direction * 8.0, 0.06)
	tween.tween_property(player, "global_position", start_position - recoil_direction * 4.0, 0.06)
	tween.tween_property(player, "global_position", start_position, 0.08)

func _enemy_name() -> String:
	return str(_enemy_data.get("enemy_name"))

func _enemy_stat(property_name: String) -> int:
	return int(_enemy_data.get(property_name))
