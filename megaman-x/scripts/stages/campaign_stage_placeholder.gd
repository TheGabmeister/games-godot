extends Node2D

const WEAPON_CATALOG_SCRIPT = preload("res://scripts/player/weapon_catalog.gd")
const FIRST_BOSS_STAGE_ID := &"chill_penguin"

var _stage_definition: StageDefinition = null

@onready var player: Node = $Player
@onready var follow_camera: Camera2D = $Camera2D
@onready var stage_controller: StageController = $StageController
@onready var goal_trigger: Node = $GoalTrigger
@onready var boss_trigger: Area2D = $BossArenaTrigger
@onready var boss_barrier_left: Node = $BossBarrierLeft
@onready var boss_barrier_right: Node = $BossBarrierRight
@onready var boss_encounter: Node = $BossEncounterController
@onready var boss_actor: Node = $ChillPenguinBoss
@onready var boss_hud: Control = $BossLayer/BossHUD
@onready var stage_label: Label = $CanvasLayer/Panel/VBoxContainer/StageLabel
@onready var body_label: Label = $CanvasLayer/Panel/VBoxContainer/BodyLabel


func _ready() -> void:
	if player != null and player.has_method("set_dash_unlocked"):
		player.set_dash_unlocked(bool(Progression.dash_unlocked))
	if follow_camera != null and player != null and player.has_method("get_camera_anchor"):
		follow_camera.set_target(player.get_camera_anchor())
	if boss_encounter != null:
		boss_encounter.connect("encounter_started", _on_boss_encounter_started)
		boss_encounter.connect("encounter_ended", _on_boss_encounter_ended)
		boss_encounter.connect("boss_health_changed", _on_boss_health_changed)
	if boss_actor != null:
		boss_actor.connect("phase_changed", _on_boss_phase_changed)
	if boss_hud != null and boss_hud.has_method("bind_encounter"):
		boss_hud.bind_encounter(boss_encounter)
	_apply_stage_slice_config()
	_refresh_ui()


func configure_stage_definition(stage_definition: StageDefinition) -> void:
	_stage_definition = stage_definition
	if stage_controller != null:
		stage_controller.stage_id = stage_definition.stage_id
	if is_inside_tree():
		_apply_stage_slice_config()
		_refresh_ui()


func get_primary_player() -> Node:
	return player


func _is_first_boss_slice() -> bool:
	return _stage_definition != null and _stage_definition.stage_id == FIRST_BOSS_STAGE_ID


func _apply_stage_slice_config() -> void:
	var first_boss_enabled := _is_first_boss_slice()
	if goal_trigger != null and goal_trigger.has_method("set_trigger_enabled"):
		goal_trigger.set_trigger_enabled(not first_boss_enabled)
	elif goal_trigger != null:
		goal_trigger.visible = not first_boss_enabled

	if boss_trigger != null:
		boss_trigger.monitoring = first_boss_enabled
		boss_trigger.visible = first_boss_enabled
	if boss_barrier_left != null:
		boss_barrier_left.visible = first_boss_enabled and bool(boss_barrier_left.call("is_locked"))
	if boss_barrier_right != null:
		boss_barrier_right.visible = first_boss_enabled and bool(boss_barrier_right.call("is_locked"))
	if boss_actor != null:
		if boss_actor.has_method("set_boss_enabled"):
			boss_actor.set_boss_enabled(first_boss_enabled)
		else:
			boss_actor.visible = first_boss_enabled
	if boss_hud != null and not first_boss_enabled:
		boss_hud.visible = false


func _refresh_ui() -> void:
	var stage_id := stage_controller.stage_id
	var display_name := String(stage_id)
	var group_name := "Campaign"
	var reward_name := ""
	if _stage_definition != null:
		stage_id = _stage_definition.stage_id
		display_name = _stage_definition.display_name
		group_name = String(_stage_definition.stage_group).capitalize()
		if not _stage_definition.weapon_reward_id.is_empty():
			reward_name = WEAPON_CATALOG_SCRIPT.get_weapon_display_name(_stage_definition.weapon_reward_id)

	stage_label.text = display_name
	if _is_first_boss_slice():
		var boss_phase := boss_actor.call("get_phase_name") if boss_actor != null and boss_actor.has_method("get_phase_name") else &"OFFLINE"
		var boss_health := boss_actor.call("get_health_component") if boss_actor != null and boss_actor.has_method("get_health_component") else null
		body_label.text = "%s vertical slice.\nStage ID: %s\nDash unlocked: %s\nReward: %s\nBoss phase: %s | HP: %d/%d\nEnter the boss gate, survive the attack loop, and defeat Chill Penguin to trigger stage clear." % [
			group_name,
			stage_id,
			"yes" if Progression.dash_unlocked else "no",
			reward_name if not reward_name.is_empty() else "stage clear only",
			boss_phase,
			int(boss_health.get("current_health")) if boss_health != null else 0,
			int(boss_health.get("max_health")) if boss_health != null else 0,
		]
		return

	body_label.text = "%s placeholder slice.\nStage ID: %s\nDash unlocked: %s\nReward: %s\nTouch the clear gate to complete this stage." % [
		group_name,
		stage_id,
		"yes" if Progression.dash_unlocked else "no",
		reward_name if not reward_name.is_empty() else "stage clear only",
	]


func _on_boss_encounter_started(_boss_id: StringName, _display_name: String) -> void:
	if boss_actor != null and boss_actor.has_method("on_encounter_started"):
		boss_actor.on_encounter_started()
	_refresh_ui()


func _on_boss_encounter_ended(_boss_id: StringName, reason: StringName) -> void:
	if reason == &"defeated" and stage_controller != null:
		stage_controller.begin_stage_clear(&"boss_defeat")
	_refresh_ui()


func _on_boss_health_changed(_current_health: int, _max_health: int) -> void:
	_refresh_ui()


func _on_boss_phase_changed(_previous_phase: StringName, _new_phase: StringName) -> void:
	_refresh_ui()
