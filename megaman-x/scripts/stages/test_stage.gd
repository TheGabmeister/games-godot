extends Node2D

const STAGE_NOTE := "Boss systems test stage.\nMove with A/D. Jump with Space. Shoot with J. Dash with K after the capsule unlock.\nPress U to unlock all boss weapons for this session. Press V or Tab to use a filled sub tank.\nSwitch weapons with Q/E or shoulder buttons once boss weapons are unlocked.\nUse the tall wall before the boss gate to test wall slide and wall jump.\nWalk into the far-right arena trigger to start the boss encounter."
const DASH_CAPSULE_DIALOGUE := preload("res://data/dialogue/test_stage_dash_capsule.tres")
const DASH_CAPSULE_PICKUP_ID := &"test_stage_dash_capsule"

@onready var player: Node = $Player
@onready var player_combat: Node = $Player/PlayerCombat
@onready var walker_enemy: Node = $WalkerBasic
@onready var checkpoint_alpha: Node = $CheckpointAlpha
@onready var checkpoint_bravo: Node = $CheckpointBravo
@onready var heart_tank_pickup: Node = $HeartTankPickup
@onready var armor_capsule_pickup: Node = $ArmorCapsulePickup
@onready var sub_tank_pickup: Node = $SubTankPickup
@onready var dash_capsule: Node = $DashCapsule
@onready var damage_hazard: Node = $DamageHazard
@onready var instant_hazard: Node = $InstantDeathHazard
@onready var test_dummy: Node = $TestDummy
@onready var weakness_dummy: Node = $WeaknessDummy
@onready var boss_dummy: Node = $BossDummy
@onready var boss_encounter: Node = $BossEncounterController
@onready var clear_trigger: Node = $GoalTrigger
@onready var follow_camera: Camera2D = $Camera2D
@onready var stage_controller: Node = $StageController
@onready var cutscene_director: Node = $CutsceneDirector
@onready var boss_hud: Control = $BossLayer/BossHUD
@onready var body_label: Label = $CanvasLayer/Overlay/Body


func _ready() -> void:
	if player.has_method("set_dash_unlocked"):
		player.set_dash_unlocked(bool(Progression.dash_unlocked))
	follow_camera.call("set_target", player.call("get_camera_anchor"))
	player.connect("locomotion_state_changed", _on_player_locomotion_state_changed)
	player.connect("facing_changed", _on_player_facing_changed)
	player.connect("dash_unlocked_changed", _on_dash_unlock_changed)
	player.call("get_health_component").connect("health_changed", _on_player_health_changed)
	player_combat.connect("combat_state_changed", _on_player_combat_state_changed)
	player_combat.connect("charge_feedback_changed", _on_player_charge_feedback_changed)
	player_combat.connect("projectile_spawned", _on_player_projectile_spawned)
	player_combat.connect("weapon_changed", _on_player_weapon_changed)
	player_combat.connect("weapon_energy_changed", _on_player_weapon_energy_changed)
	test_dummy.get_node("HealthComponent").connect("health_changed", _on_test_dummy_health_changed)
	weakness_dummy.get_node("HealthComponent").connect("health_changed", _on_weakness_dummy_health_changed)
	boss_dummy.get_node("HealthComponent").connect("health_changed", _on_boss_health_changed)
	walker_enemy.connect("activation_changed", _on_walker_enemy_changed)
	walker_enemy.connect("enemy_defeated", _on_walker_enemy_changed)
	walker_enemy.connect("drop_spawned", _on_walker_enemy_changed)
	walker_enemy.get_node("HealthComponent").connect("health_changed", _on_walker_enemy_health_changed)
	checkpoint_alpha.connect("activated", _on_checkpoint_changed)
	checkpoint_bravo.connect("activated", _on_checkpoint_changed)
	if Progression != null and Progression.has_signal("progression_changed"):
		Progression.progression_changed.connect(_on_progression_changed)
	dash_capsule.connect("triggered", _on_dash_capsule_triggered)
	dash_capsule.connect("collected", _on_dash_capsule_collected)
	stage_controller.connect("checkpoint_activated", _on_checkpoint_changed)
	stage_controller.connect("cutscene_started", _on_cutscene_state_changed)
	stage_controller.connect("cutscene_finished", _on_cutscene_state_changed)
	stage_controller.connect("stage_clear_started", _on_stage_clear_started)
	stage_controller.connect("retry_completed", _on_retry_completed)
	cutscene_director.connect("cutscene_started", _on_cutscene_state_changed)
	cutscene_director.connect("cutscene_finished", _on_cutscene_state_changed)
	if boss_encounter != null:
		boss_encounter.connect("encounter_started", _on_boss_encounter_state_changed)
		boss_encounter.connect("encounter_ended", _on_boss_encounter_state_changed)
		boss_encounter.connect("boss_health_changed", _on_boss_health_changed)
		boss_encounter.connect("arena_lock_changed", _on_boss_arena_lock_changed)
	if boss_hud != null and boss_hud.has_method("bind_encounter"):
		boss_hud.bind_encounter(boss_encounter)
	_refresh_overlay()


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed(&"debug_unlock_all_weapons"):
		return

	var viewport := get_viewport()
	if viewport != null:
		viewport.set_input_as_handled()

	_unlock_all_weapons_shortcut()


func get_primary_player() -> Node:
	return player


func _on_player_locomotion_state_changed(_previous_state: int, _new_state: int) -> void:
	_refresh_overlay()


func _on_player_facing_changed(_facing_direction: int) -> void:
	_refresh_overlay()


func _on_player_health_changed(_current_health: int, _max_health: int) -> void:
	_refresh_overlay()


func _on_dash_unlock_changed(_is_unlocked: bool) -> void:
	_refresh_overlay()


func _on_retry_completed(_retry_count: int) -> void:
	_refresh_overlay()


func _on_checkpoint_changed(_value = null, _respawn_position := Vector2.ZERO) -> void:
	_refresh_overlay()


func _on_stage_clear_started(_stage_id: StringName, _clear_count: int) -> void:
	_refresh_overlay()


func _on_cutscene_state_changed(_value = null, _value_two = null) -> void:
	_refresh_overlay()


func _on_player_combat_state_changed(_previous_state: int, _new_state: int) -> void:
	_refresh_overlay()


func _on_player_charge_feedback_changed(_previous_feedback: int, _new_feedback: int) -> void:
	_refresh_overlay()


func _on_player_projectile_spawned(_projectile: Node, _spawn_position: Vector2, _tier: StringName) -> void:
	_refresh_overlay()


func _on_player_weapon_changed(_weapon_id: StringName, _display_name: String) -> void:
	_refresh_overlay()


func _on_player_weapon_energy_changed(_weapon_id: StringName, _current_energy: int, _max_energy: int) -> void:
	_refresh_overlay()


func _on_walker_enemy_changed(_value = null) -> void:
	_refresh_overlay()


func _on_test_dummy_health_changed(_current_health: int, _max_health: int) -> void:
	_refresh_overlay()


func _on_weakness_dummy_health_changed(_current_health: int, _max_health: int) -> void:
	_refresh_overlay()


func _on_boss_health_changed(_current_health: int, _max_health: int) -> void:
	_refresh_overlay()


func _on_walker_enemy_health_changed(_current_health: int, _max_health: int) -> void:
	_refresh_overlay()


func _on_dash_capsule_collected(_pickup_id: StringName) -> void:
	_refresh_overlay()


func _on_progression_changed() -> void:
	_refresh_overlay()


func _on_boss_encounter_state_changed(_value = null, _value_two = null) -> void:
	_refresh_overlay()


func _on_boss_arena_lock_changed(_is_locked: bool) -> void:
	_refresh_overlay()


func _on_dash_capsule_triggered(_pickup_id: StringName) -> void:
	if stage_controller == null or cutscene_director == null:
		return

	if not stage_controller.begin_cutscene(&"dash_capsule_unlock"):
		return

	var result: Dictionary = await cutscene_director.play_cutscene(&"dash_capsule_unlock", [
		{
			"type": &"camera_pan_to_marker",
			"marker": dash_capsule.get_node("CameraFocus"),
			"wait_frames": 12,
		},
		{
			"type": &"emit_audio_event",
			"event_id": &"capsule_activate",
		},
		{
			"type": &"show_text",
			"sequence": DASH_CAPSULE_DIALOGUE,
		},
		{
			"type": &"unlock_dash",
			"pickup_id": DASH_CAPSULE_PICKUP_ID,
			"capsule": dash_capsule,
		},
		{
			"type": &"camera_follow_player",
			"wait_frames": 6,
		},
	], {
		"camera": follow_camera,
		"player": player,
	})

	stage_controller.finish_cutscene(&"dash_capsule_unlock", bool(result.get("skipped", false)))
	_refresh_overlay()


func _unlock_all_weapons_shortcut() -> void:
	if Progression == null or not Progression.has_method("unlock_all_weapons"):
		return

	Progression.unlock_all_weapons()
	_refresh_overlay()


func _refresh_overlay() -> void:
	var health_component: Node = player.call("get_health_component")
	var respawn_position: Vector2 = stage_controller.call("get_current_respawn_position")
	body_label.text = "%s\nMove: %s | Facing: %s | Combat: %s | Charge: %s\nHP: %d/%d | Weapon: %s | Energy: %s\nUnlocked weapons: %d | Heart bonus: +%d | Body armor: %s\nSub tank: %s | Shots: %d | Retries: %d\nCutscene: %s | Dash: unlocked=%s | pickup=%s\nCheckpoint: %s @ (%.0f, %.0f)\nBoss: active=%s locked=%s cleared=%s hud=%s hp=%s\nClear: active=%s | count=%d | goal=%s\nPickups: heart=%s body=%s sub=%s\nNormal dummy: %s\nWeak dummy: %s\nEnemy: %s" % [
		STAGE_NOTE,
		player.call("get_locomotion_state_name"),
		player.call("get_facing_name"),
		player_combat.call("get_combat_state_name"),
		player_combat.call("get_charge_feedback_name"),
		health_component.get("current_health"),
		health_component.get("max_health"),
		player_combat.call("get_current_weapon_name"),
		_format_weapon_energy(),
		player_combat.get_node("WeaponInventory").call("get_unlocked_weapon_count"),
		_get_heart_tank_bonus(),
		_has_body_armor(),
		_get_sub_tank_summary(),
		player_combat.call("get_active_projectile_count"),
		stage_controller.get("retry_count"),
		stage_controller.call("get_active_cutscene_id"),
		player.call("is_dash_unlocked"),
		dash_capsule.call("is_collected"),
		stage_controller.call("get_active_checkpoint_id"),
		respawn_position.x,
		respawn_position.y,
		_get_boss_encounter_active(),
		_get_boss_arena_locked(),
		_get_boss_encounter_completed(),
		_is_boss_hud_visible(),
		_get_boss_health_summary(),
		stage_controller.call("is_stage_clear_active"),
		stage_controller.get("stage_clear_count"),
		clear_trigger.get("trigger_id"),
		heart_tank_pickup.call("is_collected"),
		armor_capsule_pickup.call("is_collected"),
		sub_tank_pickup.call("is_collected"),
		test_dummy.get_node("HealthComponent").get("current_health"),
		weakness_dummy.get_node("HealthComponent").get("current_health"),
		walker_enemy.call("get_debug_summary"),
	]


func _format_weapon_energy() -> String:
	var max_energy := int(player_combat.call("get_current_weapon_max_energy"))
	if max_energy <= 0:
		return "INF"

	return "%d/%d" % [
		int(player_combat.call("get_current_weapon_energy")),
		max_energy,
	]


func _get_heart_tank_bonus() -> int:
	if Progression == null or not Progression.has_method("get_heart_tank_health_bonus"):
		return 0

	return int(Progression.get_heart_tank_health_bonus())


func _has_body_armor() -> bool:
	return bool(Progression != null and Progression.has_method("has_armor_part") and Progression.has_armor_part(&"body"))


func _get_sub_tank_summary() -> String:
	if Progression == null or not Progression.has_method("has_sub_tank"):
		return "none"

	if not Progression.has_sub_tank(&"sub_tank_alpha"):
		return "none"

	return "%d fill" % int(Progression.get_sub_tank_fill(&"sub_tank_alpha"))


func _get_boss_encounter_active() -> bool:
	return bool(boss_encounter != null and boss_encounter.has_method("is_encounter_active") and boss_encounter.is_encounter_active())


func _get_boss_arena_locked() -> bool:
	return bool(boss_encounter != null and boss_encounter.has_method("is_arena_locked") and boss_encounter.is_arena_locked())


func _get_boss_encounter_completed() -> bool:
	return bool(boss_encounter != null and boss_encounter.has_method("has_encounter_completed") and boss_encounter.has_encounter_completed())


func _get_boss_health_summary() -> String:
	if boss_encounter == null or not boss_encounter.has_method("get_boss_current_health"):
		return "0/0"

	return "%d/%d" % [
		int(boss_encounter.get_boss_current_health()),
		int(boss_encounter.get_boss_max_health()),
	]


func _is_boss_hud_visible() -> bool:
	return bool(boss_hud != null and boss_hud.visible)
