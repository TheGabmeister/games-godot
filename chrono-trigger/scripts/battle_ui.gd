extends CanvasLayer

signal attack_selected

@export var battle_manager_path: NodePath

@onready var root: Control = $Root
@onready var atb_bar: ProgressBar = $Root/BattlePanel/MarginContainer/VBoxContainer/TopRow/ATBBar
@onready var enemy_hp_bar: ProgressBar = $Root/BattlePanel/MarginContainer/VBoxContainer/TopRow/EnemyHPBar
@onready var enemy_label: Label = $Root/BattlePanel/MarginContainer/VBoxContainer/TopRow/EnemyLabel
@onready var player_hp_label: Label = $Root/BattlePanel/MarginContainer/VBoxContainer/PlayerHPLabel
@onready var command_menu: PanelContainer = $Root/CommandMenu
@onready var results_label: Label = $Root/ResultsLabel
@onready var game_over_label: Label = $Root/GameOverLabel

var _command_ready := false

func _ready() -> void:
	root.visible = false
	command_menu.visible = false
	results_label.visible = false
	game_over_label.visible = false

	var bm := get_node(battle_manager_path)
	bm.battle_started.connect(_on_battle_started)
	bm.battle_ended.connect(_on_battle_ended)
	bm.atb_updated.connect(_set_atb)
	bm.command_ready_changed.connect(_set_command_ready)
	bm.player_hp_changed.connect(_set_player_hp)
	bm.enemy_hp_changed.connect(_set_enemy_hp)
	bm.damage_dealt.connect(_on_damage_dealt)
	bm.victory_achieved.connect(_on_victory_achieved)
	bm.player_defeated.connect(_on_player_defeated)
	attack_selected.connect(bm._on_attack_selected)

func _process(_delta: float) -> void:
	if not _command_ready:
		return
	if GameState.current != GameState.State.BATTLE:
		return
	if Input.is_action_just_pressed("interact"):
		_command_ready = false
		command_menu.visible = false
		attack_selected.emit()

func _on_battle_started(player_hp: int, player_max_hp: int, enemy_name: String, enemy_hp: int, enemy_max_hp: int) -> void:
	root.visible = true
	results_label.visible = false
	game_over_label.visible = false
	_set_command_ready(false)
	_set_atb(0.0)
	_set_player_hp(player_hp, player_max_hp)
	_set_enemy_hp(enemy_name, enemy_hp, enemy_max_hp)

func _on_battle_ended() -> void:
	results_label.visible = false
	root.visible = false
	_set_command_ready(false)

func _on_damage_dealt(world_position: Vector2, amount: int, is_critical: bool) -> void:
	var label := Label.new()
	label.text = str(amount)
	label.add_theme_font_size_override("font_size", 28 if is_critical else 22)
	label.add_theme_color_override("font_color", Color(1.0, 0.86, 0.25) if is_critical else Color.WHITE)
	root.add_child(label)
	var screen_position := get_viewport().get_canvas_transform() * world_position
	label.position = screen_position - Vector2(12, 44)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position", label.position - Vector2(0, 38), 0.6)
	tween.tween_property(label, "modulate:a", 0.0, 0.6)
	tween.finished.connect(label.queue_free)

func _on_victory_achieved(exp_reward: int, gold_reward: int, tp_reward: int) -> void:
	_set_command_ready(false)
	results_label.text = "EXP +%d   G +%d   TP +%d" % [exp_reward, gold_reward, tp_reward]
	results_label.visible = true

func _on_player_defeated() -> void:
	_set_command_ready(false)
	game_over_label.visible = true

func _set_atb(value: float) -> void:
	atb_bar.value = clampf(value, 0.0, 1.0) * 100.0

func _set_player_hp(current_hp: int, max_hp: int) -> void:
	player_hp_label.text = "Crono HP: %d / %d" % [max(current_hp, 0), max_hp]

func _set_enemy_hp(enemy_name: String, current_hp: int, max_hp: int) -> void:
	enemy_label.text = enemy_name
	enemy_hp_bar.value = (float(max(current_hp, 0)) / float(max_hp)) * 100.0

func _set_command_ready(is_ready: bool) -> void:
	_command_ready = is_ready
	command_menu.visible = is_ready
