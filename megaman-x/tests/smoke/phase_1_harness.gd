extends SceneTree

const PLAYER_SCRIPT = preload("res://scripts/player/player.gd")
const PLAYER_COMBAT_SCRIPT = preload("res://scripts/player/player_combat.gd")
const HIT_PAYLOAD_SCRIPT = preload("res://scripts/components/hit_payload.gd")

const REQUIRED_AUTOLOADS := {
	"GameFlow": "/root/GameFlow",
	"Progression": "/root/Progression",
	"SaveManager": "/root/SaveManager",
	"AudioManager": "/root/AudioManager",
}


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var arguments := OS.get_cmdline_user_args()
	if arguments.is_empty():
		push_error("Phase 1 harness expected a mode argument.")
		quit(1)
		return

	var exit_code := 1
	match arguments[0]:
		"main_layers":
			exit_code = await _check_main_layers()
		"title_flow":
			exit_code = await _check_title_flow()
		"autoloads":
			exit_code = await _check_autoloads()
		"test_stage":
			exit_code = await _check_test_stage()
		"locomotion":
			exit_code = await _check_locomotion()
		"player_spawn":
			exit_code = await _check_player_spawn()
		"camera_follow":
			exit_code = await _check_camera_follow()
		"damage_pipeline":
			exit_code = await _check_damage_pipeline()
		"player_retry":
			exit_code = await _check_player_retry()
		"stage_reset":
			exit_code = await _check_stage_reset()
		"enemy_activation":
			exit_code = await _check_enemy_activation()
		"enemy_reset":
			exit_code = await _check_enemy_reset()
		"enemy_drop_reset":
			exit_code = await _check_enemy_drop_reset()
		"enemy_projectile_hit":
			exit_code = await _check_enemy_projectile_hit()
		"stage_clear_once":
			exit_code = await _check_stage_clear_once()
		"stage_clear_input_lock":
			exit_code = await _check_stage_clear_input_lock()
		"stage_clear_overlay":
			exit_code = await _check_stage_clear_overlay()
		"checkpoint_activation":
			exit_code = await _check_checkpoint_activation()
		"checkpoint_retry":
			exit_code = await _check_checkpoint_retry()
		"hazard_modes":
			exit_code = await _check_hazard_modes()
		"projectile_spawn":
			exit_code = await _check_projectile_spawn()
		"projectile_rules":
			exit_code = await _check_projectile_rules()
		"charge_flow":
			exit_code = await _check_charge_flow()
		"hud_updates":
			exit_code = await _check_hud_updates()
		"audio_events":
			exit_code = await _check_audio_events()
		"cutscene_flow":
			exit_code = await _check_cutscene_flow()
		"dialogue_flow":
			exit_code = await _check_dialogue_flow()
		"dash_unlock":
			exit_code = await _check_dash_unlock()
		"save_round_trip":
			exit_code = await _check_save_round_trip()
		"persistent_pickup_reload":
			exit_code = await _check_persistent_pickup_reload()
		"continue_flow":
			exit_code = await _check_continue_flow()
		"stage_select_roster":
			exit_code = await _check_stage_select_roster()
		"stage_select_loading":
			exit_code = await _check_stage_select_loading()
		"fortress_unlock_flow":
			exit_code = await _check_fortress_unlock_flow()
		"weapon_reward_unlock":
			exit_code = await _check_weapon_reward_unlock()
		"weakness_tables":
			exit_code = await _check_weakness_tables()
		"weapon_energy_costs":
			exit_code = await _check_weapon_energy_costs()
		"unlock_all_weapons_shortcut":
			exit_code = await _check_unlock_all_weapons_shortcut()
		"persistent_upgrade_types":
			exit_code = await _check_persistent_upgrade_types()
		"upgrade_save_reload":
			exit_code = await _check_upgrade_save_reload()
		"sub_tank_round_trip":
			exit_code = await _check_sub_tank_round_trip()
		"pickup_collision":
			exit_code = await _check_pickup_collision()
		_:
			push_error("Unknown harness mode: %s" % arguments[0])

	await _cleanup_loaded_nodes()
	quit(exit_code)


func _check_main_layers() -> int:
	var main_scene := load("res://scenes/Main.tscn") as PackedScene
	if main_scene == null:
		push_error("Unable to load Main.tscn.")
		return 1

	var instance := main_scene.instantiate()
	root.add_child(instance)
	await process_frame

	for child_name in ["WorldRoot", "UIRoot", "OverlayRoot"]:
		if instance.get_node_or_null(child_name) == null:
			push_error("Main.tscn is missing %s." % child_name)
			return 1

	return 0


func _check_title_flow() -> int:
	var main_scene := load("res://scenes/Main.tscn") as PackedScene
	if main_scene == null:
		push_error("Unable to load Main.tscn for title flow.")
		return 1

	var instance := main_scene.instantiate()
	root.add_child(instance)
	await process_frame
	await process_frame

	var ui_root := instance.get_node_or_null("UIRoot")
	if ui_root == null:
		push_error("Main.tscn is missing UIRoot during title flow.")
		return 1

	var title_screen := ui_root.get_node_or_null("TitleScreen")
	if title_screen == null:
		push_error("Title flow did not instance TitleScreen into UIRoot.")
		return 1

	var new_game_button := title_screen.get_node_or_null("CenterContainer/VBoxContainer/NewGameButton")
	var continue_button := title_screen.get_node_or_null("CenterContainer/VBoxContainer/ContinueButton")
	var stage_select_button := title_screen.get_node_or_null("CenterContainer/VBoxContainer/StageSelectButton")
	if new_game_button == null or continue_button == null or stage_select_button == null:
		push_error("TitleScreen is missing one or more primary campaign buttons.")
		return 1

	return 0


func _check_autoloads() -> int:
	await process_frame

	for autoload_name in REQUIRED_AUTOLOADS.keys():
		if root.get_node_or_null(REQUIRED_AUTOLOADS[autoload_name]) == null:
			push_error("Missing required autoload: %s." % autoload_name)
			return 1

	return 0


func _check_test_stage() -> int:
	var stage_scene := load("res://scenes/stages/test/TestStage.tscn") as PackedScene
	if stage_scene == null:
		push_error("Unable to load TestStage.tscn.")
		return 1

	var instance := stage_scene.instantiate()
	root.add_child(instance)
	await process_frame

	if instance.get_node_or_null("Camera2D") == null:
		push_error("TestStage is missing Camera2D.")
		return 1

	return 0


func _check_locomotion() -> int:
	var stage := await _instantiate_test_stage()
	if stage == null:
		return 1

	var player: Node = stage.get_node_or_null("Player")
	if player == null:
		push_error("TestStage is missing Player.")
		return 1

	if not await _wait_for_player_state(player, PLAYER_SCRIPT.LocomotionState.IDLE, 20):
		push_error("Expected player to settle into IDLE.")
		return 1

	Input.action_press("move_right")
	await _await_physics_frames(8)
	if player.get("locomotion_state") != PLAYER_SCRIPT.LocomotionState.RUN:
		push_error("Expected player to reach RUN while moving right.")
		_release_test_actions()
		return 1

	Input.action_press("jump")
	await _await_physics_frames(1)
	Input.action_release("jump")

	if not await _wait_for_player_state(player, PLAYER_SCRIPT.LocomotionState.JUMP, 8):
		push_error("Expected player to reach JUMP after jumping.")
		_release_test_actions()
		return 1

	if not await _wait_for_player_state(player, PLAYER_SCRIPT.LocomotionState.FALL, 40):
		push_error("Expected player to reach FALL during descent.")
		_release_test_actions()
		return 1

	_release_test_actions()
	return 0


func _check_player_spawn() -> int:
	var stage := await _instantiate_test_stage()
	if stage == null:
		return 1

	var player: Node = stage.get_node_or_null("Player")
	if player == null:
		push_error("TestStage is missing Player.")
		return 1

	var start_x: float = player.global_position.x
	Input.action_press("move_right")
	await _await_physics_frames(8)
	_release_test_actions()

	if player.global_position.x <= start_x:
		push_error("Player did not respond to move_right input in TestStage.")
		return 1

	if player.get_camera_anchor() == null:
		push_error("Player is missing CameraAnchor.")
		return 1

	return 0


func _check_camera_follow() -> int:
	var stage := await _instantiate_test_stage()
	if stage == null:
		return 1

	var camera: Camera2D = stage.get_node_or_null("Camera2D") as Camera2D
	var player: Node = stage.get_node_or_null("Player")
	if camera == null or player == null:
		push_error("TestStage is missing Camera2D or Player.")
		return 1

	var target: Node2D = camera.call("get_target") as Node2D
	if target == null:
		push_error("Follow camera does not have a target.")
		return 1

	Input.action_press("move_right")
	await _await_physics_frames(10)
	_release_test_actions()

	if absf(camera.global_position.x - target.global_position.x) > 1.0:
		push_error("Camera is not following the player anchor.")
		return 1

	return 0


func _check_damage_pipeline() -> int:
	var player_scene := load("res://scenes/player/Player.tscn") as PackedScene
	if player_scene == null:
		push_error("Unable to load Player.tscn.")
		return 1

	var player := player_scene.instantiate()
	root.add_child(player)
	await process_frame
	await _await_physics_frames(1)

	var hurtbox := player.get_node_or_null("Hurtbox")
	var health_component: Node = player.call("get_health_component")
	if hurtbox == null or health_component == null:
		push_error("Player is missing Hurtbox or HealthComponent.")
		return 1

	health_component.set("invulnerability_duration", 0.0)
	health_component.call("reset")

	var enemy_hit := HIT_PAYLOAD_SCRIPT.create(self, &"enemy", &"test_enemy_hit", 3, Vector2.ZERO)
	if not hurtbox.call("apply_hit_payload", enemy_hit):
		push_error("Enemy hit did not damage the player hurtbox.")
		return 1

	if int(health_component.get("current_health")) != int(health_component.get("max_health")) - 3:
		push_error("Player health did not drop by the expected damage amount.")
		return 1

	var same_team_hit := HIT_PAYLOAD_SCRIPT.create(self, &"player", &"test_friendly_hit", 3, Vector2.ZERO)
	if hurtbox.call("apply_hit_payload", same_team_hit):
		push_error("Same-team hit should have been ignored.")
		return 1

	if int(health_component.get("current_health")) != int(health_component.get("max_health")) - 3:
		push_error("Same-team hit changed player health.")
		return 1

	return 0


func _check_player_retry() -> int:
	var stage := await _instantiate_test_stage()
	if stage == null:
		return 1

	var player: Node = stage.get_node_or_null("Player")
	var stage_controller: Node = stage.get_node_or_null("StageController")
	var health_component: Node = player.call("get_health_component")
	if player == null or stage_controller == null or health_component == null:
		push_error("TestStage is missing Player, StageController, or HealthComponent.")
		return 1

	var initial_position: Vector2 = player.global_position
	set_meta(&"player_retry_death_seen", false)
	health_component.connect("died", func() -> void:
		set_meta(&"player_retry_death_seen", true)
	, CONNECT_ONE_SHOT)

	var lethal_hit := HIT_PAYLOAD_SCRIPT.create(self, &"enemy", &"fatal_test_hit", int(health_component.get("max_health")), Vector2.ZERO)
	player.call("apply_hit_payload", lethal_hit)
	await process_frame

	if not bool(get_meta(&"player_retry_death_seen", false)):
		push_error("Player death signal did not fire.")
		return 1

	if not await _wait_for_retry_count(stage_controller, 1, 90):
		push_error("StageController did not retry the stage after player death.")
		return 1

	if player.global_position.distance_to(initial_position) > 0.1:
		push_error("Player did not respawn at the stage start position.")
		return 1

	if player.get("locomotion_state") == PLAYER_SCRIPT.LocomotionState.DEAD:
		push_error("Player remained in DEAD state after retry.")
		return 1

	var second_lethal_hit := HIT_PAYLOAD_SCRIPT.create(self, &"enemy", &"fatal_retry_repeat_hit", int(health_component.get("max_health")), Vector2.ZERO)
	if not bool(player.call("apply_hit_payload", second_lethal_hit)):
		push_error("Player did not accept damage after retry.")
		return 1

	await process_frame
	if not await _wait_for_retry_count(stage_controller, 2, 90):
		push_error("StageController did not retry the stage after a second death.")
		return 1

	return 0


func _check_stage_reset() -> int:
	var stage := await _instantiate_test_stage()
	if stage == null:
		return 1

	var player: Node = stage.get_node_or_null("Player")
	var dummy := stage.get_node_or_null("TestDummy")
	var stage_controller: Node = stage.get_node_or_null("StageController")
	if player == null or dummy == null or stage_controller == null:
		push_error("TestStage is missing Player, TestDummy, or StageController.")
		return 1

	var dummy_hurtbox := dummy.get_node_or_null("Hurtbox")
	var dummy_health: Node = dummy.get_node_or_null("HealthComponent")
	if dummy_hurtbox == null or dummy_health == null:
		push_error("TestDummy is missing Hurtbox or HealthComponent.")
		return 1

	var dummy_hit := HIT_PAYLOAD_SCRIPT.create(self, &"player", &"dummy_test_hit", int(dummy_health.get("max_health")), Vector2.ZERO)
	dummy_hurtbox.call("apply_hit_payload", dummy_hit)
	await process_frame

	if not bool(dummy_health.get("is_dead")) or dummy.visible:
		push_error("Temporary dummy did not enter its defeated state before retry.")
		return 1

	var player_health: Node = player.call("get_health_component")
	var lethal_hit := HIT_PAYLOAD_SCRIPT.create(self, &"enemy", &"fatal_reset_hit", int(player_health.get("max_health")), Vector2.ZERO)
	player.call("apply_hit_payload", lethal_hit)

	if not await _wait_for_retry_count(stage_controller, 1, 90):
		push_error("StageController did not retry the stage for reset verification.")
		return 1

	if bool(dummy_health.get("is_dead")) or not dummy.visible:
		push_error("Temporary dummy was not reconstructed on retry.")
		return 1

	return 0


func _check_checkpoint_activation() -> int:
	var stage := await _instantiate_test_stage()
	if stage == null:
		return 1

	var stage_controller: Node = stage.get_node_or_null("StageController")
	var player: Node2D = stage.get_node_or_null("Player") as Node2D
	var checkpoint_alpha: Node2D = stage.get_node_or_null("CheckpointAlpha") as Node2D
	var checkpoint_bravo: Node2D = stage.get_node_or_null("CheckpointBravo") as Node2D
	if stage_controller == null or player == null or checkpoint_alpha == null or checkpoint_bravo == null:
		push_error("TestStage is missing StageController, Player, or checkpoint instances.")
		return 1

	if stage_controller.call("get_active_checkpoint_id") != StringName():
		push_error("StageController should start with no active checkpoint.")
		return 1

	player.global_position = checkpoint_alpha.global_position
	if not await _wait_for_active_checkpoint(stage_controller, &"checkpoint_alpha", 12):
		push_error("Checkpoint Alpha did not become active.")
		return 1

	player.global_position = checkpoint_bravo.global_position
	if not await _wait_for_active_checkpoint(stage_controller, &"checkpoint_bravo", 12):
		push_error("Checkpoint Bravo did not override the earlier checkpoint.")
		return 1

	return 0


func _check_checkpoint_retry() -> int:
	var stage := await _instantiate_test_stage()
	if stage == null:
		return 1

	var stage_controller: Node = stage.get_node_or_null("StageController")
	var player: Node = stage.get_node_or_null("Player")
	var checkpoint_bravo: Node = stage.get_node_or_null("CheckpointBravo")
	if stage_controller == null or player == null or checkpoint_bravo == null:
		push_error("TestStage is missing StageController, Player, or CheckpointBravo.")
		return 1

	player.global_position = checkpoint_bravo.global_position
	if not await _wait_for_active_checkpoint(stage_controller, &"checkpoint_bravo", 12):
		push_error("Checkpoint Bravo did not activate before retry verification.")
		return 1

	var respawn_anchor: Marker2D = checkpoint_bravo.get_node_or_null("RespawnAnchor") as Marker2D
	if respawn_anchor == null:
		push_error("CheckpointBravo is missing RespawnAnchor.")
		return 1

	var player_health: Node = player.call("get_health_component")
	var lethal_hit := HIT_PAYLOAD_SCRIPT.create(self, &"hazard", &"checkpoint_retry_test", int(player_health.get("max_health")), Vector2.ZERO)
	player.call("apply_hit_payload", lethal_hit)

	if not await _wait_for_retry_count(stage_controller, 1, 90):
		push_error("StageController did not retry after checkpoint death.")
		return 1

	if player.global_position.distance_to(respawn_anchor.global_position) > 0.1:
		push_error("Player did not respawn at the active checkpoint anchor.")
		return 1

	return 0


func _check_hazard_modes() -> int:
	var stage := await _instantiate_test_stage()
	if stage == null:
		return 1

	var player: Node2D = stage.get_node_or_null("Player") as Node2D
	var stage_controller: Node = stage.get_node_or_null("StageController")
	var damage_hazard: Node2D = stage.get_node_or_null("DamageHazard") as Node2D
	var instant_hazard: Node2D = stage.get_node_or_null("InstantDeathHazard") as Node2D
	if player == null or stage_controller == null or damage_hazard == null or instant_hazard == null:
		push_error("TestStage is missing Player, StageController, or Phase 6 hazards.")
		return 1

	var health_component: Node = player.call("get_health_component")
	health_component.set("invulnerability_duration", 0.0)
	health_component.call("reset")

	player.global_position = damage_hazard.global_position
	await _await_physics_frames(2)
	var expected_health := int(health_component.get("max_health")) - int(damage_hazard.get("damage"))
	if int(health_component.get("current_health")) != expected_health:
		push_error("Damage hazard did not apply the expected nonlethal damage.")
		return 1

	set_meta(&"hazard_instant_death_seen", false)
	health_component.connect("died", func() -> void:
		set_meta(&"hazard_instant_death_seen", true)
	, CONNECT_ONE_SHOT)
	player.global_position = instant_hazard.global_position
	await process_frame

	if not await _wait_for_retry_count(stage_controller, 1, 90):
		push_error("Instant-death hazard did not drive the player into retry.")
		return 1

	if not bool(get_meta(&"hazard_instant_death_seen", false)):
		push_error("Instant-death hazard did not kill the player.")
		return 1

	return 0


func _check_enemy_projectile_hit() -> int:
	var stage := await _instantiate_test_stage()
	if stage == null:
		return 1

	var player: Node2D = stage.get_node_or_null("Player") as Node2D
	var enemy: Node = stage.get_node_or_null("WalkerBasic")
	var combat: Node = player.get_node_or_null("PlayerCombat") if player != null else null
	if player == null or enemy == null or combat == null:
		push_error("TestStage is missing Player, PlayerCombat, or WalkerBasic.")
		return 1

	var enemy_health: Node = enemy.get_node_or_null("HealthComponent")
	if enemy_health == null:
		push_error("WalkerBasic is missing HealthComponent.")
		return 1

	player.global_position = enemy.global_position + Vector2(-88.0, 0.0)
	await _await_physics_frames(4)
	await _tap_shoot()
	await _await_physics_frames(20)

	if int(enemy_health.get("current_health")) >= int(enemy_health.get("max_health")):
		push_error("Player projectile did not damage WalkerBasic on contact.")
		return 1

	return 0


func _check_stage_clear_once() -> int:
	var stage := await _instantiate_test_stage()
	if stage == null:
		return 1

	var player: Node2D = stage.get_node_or_null("Player") as Node2D
	var stage_controller: Node = stage.get_node_or_null("StageController")
	var clear_trigger: Node2D = stage.get_node_or_null("GoalTrigger") as Node2D
	if player == null or stage_controller == null or clear_trigger == null:
		push_error("TestStage is missing Player, StageController, or GoalTrigger.")
		return 1

	set_meta(&"stage_clear_signal_count", 0)
	stage_controller.connect("stage_clear_started", func(_stage_id: StringName, _clear_count: int) -> void:
		set_meta(&"stage_clear_signal_count", int(get_meta(&"stage_clear_signal_count", 0)) + 1)
	)

	player.global_position = clear_trigger.global_position
	await _await_physics_frames(2)
	stage_controller.begin_stage_clear(&"duplicate_attempt")
	await process_frame

	if not bool(stage_controller.call("is_stage_clear_active")):
		push_error("StageController did not enter stage-clear state.")
		return 1

	if int(stage_controller.get("stage_clear_count")) != 1:
		push_error("Stage clear transitioned more than once.")
		return 1

	if int(get_meta(&"stage_clear_signal_count", 0)) != 1:
		push_error("Stage clear signal did not fire exactly once.")
		return 1

	return 0


func _check_stage_clear_input_lock() -> int:
	var stage := await _instantiate_test_stage()
	if stage == null:
		return 1

	var player: Node2D = stage.get_node_or_null("Player") as Node2D
	var stage_controller: Node = stage.get_node_or_null("StageController")
	var combat: Node = player.get_node_or_null("PlayerCombat") if player != null else null
	if player == null or stage_controller == null or combat == null:
		push_error("TestStage is missing Player, StageController, or PlayerCombat.")
		return 1

	player.global_position = Vector2(1456.0, 460.0)
	player.set("velocity", Vector2.ZERO)
	stage_controller.begin_stage_clear(&"input_lock_test")
	await _await_physics_frames(2)

	var start_x: float = player.global_position.x
	Input.action_press("move_left")
	Input.action_press("shoot")
	await _await_physics_frames(10)
	_release_test_actions()

	if absf(player.global_position.x - start_x) > 0.1:
		push_error("Player movement continued after stage clear locked gameplay.")
		return 1

	if bool(player.call("is_gameplay_enabled")):
		push_error("Player gameplay state remained enabled during stage clear.")
		return 1

	if bool(combat.get("combat_enabled")) or int(combat.call("get_active_projectile_count")) != 0:
		push_error("Combat remained active during stage clear.")
		return 1

	return 0


func _check_stage_clear_overlay() -> int:
	var loaded := await _load_test_stage_via_main()
	if loaded.is_empty():
		return 1

	var main: Node = loaded["main"]
	var stage: Node = loaded["stage"]
	var player: Node2D = loaded["player"] as Node2D
	var hud: Node = loaded["hud"]
	var stage_controller: Node = stage.get_node_or_null("StageController")
	var clear_trigger: Node2D = stage.get_node_or_null("GoalTrigger") as Node2D
	var combat: Node = player.get_node_or_null("PlayerCombat") if player != null else null
	if main == null or stage_controller == null or clear_trigger == null or combat == null:
		push_error("Main stage load is missing StageController, GoalTrigger, or PlayerCombat.")
		return 1

	await _tap_shoot()
	if not await _wait_for_projectile_count(combat, 1, 20):
		push_error("Stage-clear overlay test failed to spawn a projectile before clear.")
		return 1

	player.global_position = clear_trigger.global_position
	if not await _wait_for_gameflow_state(GameFlow.RuntimeState.STAGE_CLEAR, 20):
		push_error("GameFlow did not enter STAGE_CLEAR.")
		return 1

	await _await_physics_frames(2)
	var overlay: Node = main.call("get_active_overlay")
	if overlay == null:
		push_error("RuntimeShell did not install the StageClear overlay.")
		return 1

	var snapshot := overlay.call("get_snapshot") as Dictionary
	if snapshot.get("title_text", "") != "STAGE CLEAR":
		push_error("StageClear overlay did not expose the expected title.")
		return 1

	if main.call("get_active_hud") != null or is_instance_valid(hud):
		push_error("Gameplay HUD was left behind after stage clear.")
		return 1

	if int(combat.call("get_active_projectile_count")) != 0:
		push_error("Transient projectiles survived into stage-clear flow.")
		return 1

	return 0


func _check_enemy_activation() -> int:
	var stage := await _instantiate_test_stage()
	if stage == null:
		return 1

	var enemy: Node = stage.get_node_or_null("WalkerBasic")
	if enemy == null:
		push_error("TestStage is missing WalkerBasic.")
		return 1

	var start_x: float = enemy.global_position.x
	await _await_physics_frames(10)
	if bool(enemy.call("is_awake")):
		push_error("WalkerBasic should start asleep outside activation range.")
		return 1

	if absf(enemy.global_position.x - start_x) > 0.1:
		push_error("Sleeping WalkerBasic moved before activation.")
		return 1

	var player: Node2D = stage.get_node_or_null("Player") as Node2D
	player.global_position = enemy.global_position + Vector2(-72.0, 0.0)
	await _await_physics_frames(8)

	if not bool(enemy.call("is_awake")):
		push_error("WalkerBasic did not wake when the player entered activation range.")
		return 1

	await _await_physics_frames(16)
	if absf(enemy.global_position.x - start_x) < 1.0:
		push_error("Activated WalkerBasic did not begin patrol movement.")
		return 1

	return 0


func _check_enemy_reset() -> int:
	var stage := await _instantiate_test_stage()
	if stage == null:
		return 1

	var enemy: Node = stage.get_node_or_null("WalkerBasic")
	var stage_controller: Node = stage.get_node_or_null("StageController")
	var player: Node = stage.get_node_or_null("Player")
	if enemy == null or stage_controller == null or player == null:
		push_error("TestStage is missing WalkerBasic, Player, or StageController.")
		return 1

	await _defeat_walker_enemy(enemy)
	if not bool(enemy.call("is_defeated")) or enemy.visible:
		push_error("WalkerBasic did not stay defeated before retry.")
		return 1

	var player_health: Node = player.call("get_health_component")
	var lethal_hit := HIT_PAYLOAD_SCRIPT.create(self, &"enemy", &"enemy_reset_retry", int(player_health.get("max_health")), Vector2.ZERO)
	player.call("apply_hit_payload", lethal_hit)

	if not await _wait_for_retry_count(stage_controller, 1, 90):
		push_error("StageController did not retry after enemy reset test death.")
		return 1

	if bool(enemy.call("is_defeated")) or not enemy.visible:
		push_error("WalkerBasic was not restored on retry.")
		return 1

	return 0


func _check_enemy_drop_reset() -> int:
	var stage := await _instantiate_test_stage()
	if stage == null:
		return 1

	var enemy: Node = stage.get_node_or_null("WalkerBasic")
	var stage_controller: Node = stage.get_node_or_null("StageController")
	var player: Node = stage.get_node_or_null("Player")
	if enemy == null or stage_controller == null or player == null:
		push_error("TestStage is missing WalkerBasic, Player, or StageController.")
		return 1

	await _defeat_walker_enemy(enemy)
	if int(enemy.call("get_active_drop_count")) != 1:
		push_error("WalkerBasic did not spawn exactly one temporary drop on defeat.")
		return 1

	var player_health: Node = player.call("get_health_component")
	var lethal_hit := HIT_PAYLOAD_SCRIPT.create(self, &"enemy", &"enemy_drop_retry", int(player_health.get("max_health")), Vector2.ZERO)
	player.call("apply_hit_payload", lethal_hit)

	if not await _wait_for_retry_count(stage_controller, 1, 90):
		push_error("StageController did not retry after enemy drop reset test death.")
		return 1

	if int(enemy.call("get_active_drop_count")) != 0:
		push_error("Temporary enemy drop survived stage retry.")
		return 1

	return 0


func _check_projectile_spawn() -> int:
	var stage := await _instantiate_test_stage()
	if stage == null:
		return 1

	var player: Node = stage.get_node_or_null("Player")
	var combat: Node = player.get_node_or_null("PlayerCombat")
	var shot_origin: Marker2D = player.get_node_or_null("ShotOrigin") as Marker2D
	if player == null or combat == null or shot_origin == null:
		push_error("TestStage is missing PlayerCombat or ShotOrigin.")
		return 1

	set_meta(&"projectile_spawn_position", Vector2.INF)
	combat.connect("projectile_spawned", func(_projectile: Node, spawn_position: Vector2, _tier: StringName) -> void:
		set_meta(&"projectile_spawn_position", spawn_position)
	, CONNECT_ONE_SHOT)

	player.set("facing_direction", -1)
	if player.has_signal("facing_changed"):
		player.emit_signal("facing_changed", -1)
	await _tap_shoot()
	if not await _wait_for_projectile_count(combat, 1, 20):
		push_error("Firing did not spawn a projectile.")
		return 1

	var spawn_position := get_meta(&"projectile_spawn_position", Vector2.INF) as Vector2
	if spawn_position == Vector2.INF:
		push_error("Combat did not report a projectile spawn event.")
		return 1

	var expected_spawn_position := (player as Node2D).to_global(Vector2(-shot_origin.position.x, shot_origin.position.y))
	if spawn_position.distance_to(expected_spawn_position) > 0.1:
		push_error("Projectile spawn did not mirror ShotOrigin for left-facing fire.")
		return 1

	return 0


func _check_projectile_rules() -> int:
	var stage := await _instantiate_test_stage()
	if stage == null:
		return 1

	var player: Node = stage.get_node_or_null("Player")
	var combat: Node = player.get_node_or_null("PlayerCombat")
	var weapon: Resource = combat.call("get_current_weapon") as Resource
	if player == null or combat == null or weapon == null:
		push_error("TestStage is missing combat or weapon data.")
		return 1

	var projectile_limit := int(weapon.get("active_projectile_limit"))
	var cooldown_frames := _physics_frames_for_seconds(float(weapon.get("shot_cooldown"))) + 2

	await _tap_shoot()
	if not await _wait_for_projectile_count(combat, 1, 20):
		push_error("Initial shot did not spawn.")
		return 1

	await _tap_shoot()
	await _await_physics_frames(4)
	if combat.call("get_active_projectile_count") != 1:
		push_error("Combat cooldown allowed an early second projectile.")
		return 1

	for expected_count in range(2, projectile_limit + 1):
		await _await_physics_frames(cooldown_frames)
		await _tap_shoot()
		if not await _wait_for_projectile_count(combat, expected_count, 20):
			push_error("Combat did not reach projectile count %d." % expected_count)
			return 1

	await _await_physics_frames(cooldown_frames)
	await _tap_shoot()
	await _await_physics_frames(4)
	if combat.call("get_active_projectile_count") != projectile_limit:
		push_error("Projectile limit was not enforced.")
		return 1

	return 0


func _check_charge_flow() -> int:
	var stage := await _instantiate_test_stage()
	if stage == null:
		return 1

	var player: Node = stage.get_node_or_null("Player")
	var combat: Node = player.get_node_or_null("PlayerCombat")
	var weapon: Resource = combat.call("get_current_weapon") as Resource
	if player == null or combat == null or weapon == null:
		push_error("TestStage is missing combat or weapon data.")
		return 1

	var state_history: Array[String] = []
	combat.connect("combat_state_changed", func(_previous_state: int, new_state: int) -> void:
		state_history.append(_combat_state_name_from_value(new_state))
	)

	Input.action_press("shoot")
	await _await_physics_frames(_physics_frames_for_seconds(float(weapon.get("full_charge_time"))) + 4)
	if int(combat.get("combat_state")) != PLAYER_COMBAT_SCRIPT.CombatState.CHARGED:
		push_error("Combat did not reach CHARGED after holding shoot.")
		_release_test_actions()
		return 1

	if combat.call("get_charge_feedback_name") != "charge_full":
		push_error("Charge feedback did not reach charge_full.")
		_release_test_actions()
		return 1

	Input.action_release("shoot")
	await _await_physics_frames(18)

	if not _history_contains_order(state_history, ["CHARGING", "CHARGED", "FIRING", "COOLDOWN", "READY"]):
		push_error("Charge release did not follow the expected combat state flow.")
		return 1

	return 0


func _check_hud_updates() -> int:
	var loaded := await _load_test_stage_via_main()
	if loaded.is_empty():
		return 1

	var hud: Node = loaded["hud"]
	var player: Node = loaded["player"]
	if hud == null or player == null:
		push_error("Main stage load did not expose HUD and player.")
		return 1

	var health_component: Node = player.call("get_health_component")
	if health_component == null:
		push_error("HUD test player is missing HealthComponent.")
		return 1

	var initial_snapshot := hud.call("get_snapshot") as Dictionary
	if initial_snapshot.get("weapon_text", "") != "X-Buster":
		push_error("HUD did not receive the equipped weapon label.")
		return 1

	var expected_initial_health := "%d / %d" % [health_component.get("current_health"), health_component.get("max_health")]
	if initial_snapshot.get("health_text", "") != expected_initial_health:
		push_error("HUD did not receive the initial health values.")
		return 1

	Input.action_press("shoot")
	await _await_physics_frames(24)
	var charge_snapshot := hud.call("get_snapshot") as Dictionary
	Input.action_release("shoot")
	if charge_snapshot.get("charge_text", "") != "charge_small":
		push_error("HUD did not reflect charge feedback while charging.")
		return 1

	health_component.set("invulnerability_duration", 0.0)
	var enemy_hit := HIT_PAYLOAD_SCRIPT.create(self, &"enemy", &"hud_damage_test", 2, Vector2.ZERO)
	player.call("apply_hit_payload", enemy_hit)
	await _await_physics_frames(2)

	var damaged_snapshot := hud.call("get_snapshot") as Dictionary
	var expected_health := "%d / %d" % [health_component.get("current_health"), health_component.get("max_health")]
	if damaged_snapshot.get("health_text", "") != expected_health:
		push_error("HUD did not refresh after player damage.")
		return 1

	return 0


func _check_audio_events() -> int:
	await process_frame
	var audio_manager := root.get_node_or_null("/root/AudioManager")
	if audio_manager == null:
		push_error("AudioManager autoload is unavailable.")
		return 1

	for event_id in [&"player_buster_shot", &"player_charge_start", &"player_charge_full", &"player_charge_release", &"player_hurt", &"stage_clear_fanfare"]:
		if not audio_manager.has_sfx_event(event_id):
			push_error("AudioManager is missing semantic SFX event '%s'." % event_id)
			return 1

	for event_id in [&"title_theme", &"test_stage_theme"]:
		if not audio_manager.has_music_event(event_id):
			push_error("AudioManager is missing semantic music event '%s'." % event_id)
			return 1

	audio_manager.play_sfx(&"player_buster_shot")
	audio_manager.play_music(&"test_stage_theme")
	await process_frame

	if audio_manager.last_sfx_event != &"player_buster_shot":
		push_error("AudioManager did not record the semantic SFX playback request.")
		return 1

	if audio_manager.last_music_event != &"test_stage_theme":
		push_error("AudioManager did not record the semantic music playback request.")
		return 1

	return 0


func _check_cutscene_flow() -> int:
	var progression := _get_progression()
	if progression == null:
		push_error("Progression autoload is unavailable.")
		return 1
	progression.reset_for_new_game()
	var loaded := await _load_test_stage_via_main()
	if loaded.is_empty():
		return 1

	var main: Node = loaded.get("main")
	var stage: Node = loaded.get("stage")
	var player: Node = loaded.get("player")
	var stage_controller: Node = stage.get_node_or_null("StageController")
	var cutscene_director: Node = stage.get_node_or_null("CutsceneDirector")
	var dash_capsule: Node2D = stage.get_node_or_null("DashCapsule") as Node2D
	var camera: Camera2D = stage.get_node_or_null("Camera2D") as Camera2D
	if stage_controller == null or cutscene_director == null or dash_capsule == null or camera == null:
		push_error("Cutscene flow check is missing StageController, CutsceneDirector, DashCapsule, or Camera2D.")
		return 1

	var history: Array[String] = []
	stage_controller.connect("cutscene_started", func(cutscene_id: StringName) -> void:
		history.append("stage_started:%s" % cutscene_id)
	)
	cutscene_director.connect("cutscene_started", func(cutscene_id: StringName) -> void:
		history.append("director_started:%s" % cutscene_id)
	)
	cutscene_director.connect("cutscene_finished", func(cutscene_id: StringName, was_skipped: bool) -> void:
		history.append("director_finished:%s:%s" % [cutscene_id, was_skipped])
	)
	stage_controller.connect("cutscene_finished", func(cutscene_id: StringName, was_skipped: bool) -> void:
		history.append("stage_finished:%s:%s" % [cutscene_id, was_skipped])
	)

	player.global_position = dash_capsule.global_position
	await _await_physics_frames(4)
	if not await _wait_for_gameflow_state(GameFlow.RuntimeState.CUTSCENE, 20):
		push_error("GameFlow did not enter CUTSCENE when the dash capsule triggered.")
		return 1

	var overlay := await _wait_for_active_overlay(main, 20)
	if overlay == null:
		push_error("Cutscene flow did not mount the dialogue overlay.")
		return 1

	var snapshot := overlay.call("get_snapshot") as Dictionary
	if snapshot.get("title_text", "") != "DR. LIGHT":
		push_error("Dialogue overlay did not show the expected speaker during the cutscene.")
		return 1

	await _tap_menu_confirm()
	await _tap_menu_confirm()
	if not await _wait_for_gameflow_state(GameFlow.RuntimeState.IN_STAGE, 20):
		push_error("GameFlow did not return to IN_STAGE after dialogue completion.")
		return 1

	if stage_controller.call("get_active_cutscene_id") != StringName():
		push_error("StageController still reports an active cutscene after completion.")
		return 1

	if camera.get_target() != player.call("get_camera_anchor"):
		push_error("Camera target was not restored to the player after the cutscene.")
		return 1

	if not bool(player.call("is_gameplay_enabled")):
		push_error("Player gameplay was not restored after the cutscene.")
		return 1

	if not _history_contains_order(history, [
		"stage_started:dash_capsule_unlock",
		"director_started:dash_capsule_unlock",
		"director_finished:dash_capsule_unlock:False",
		"stage_finished:dash_capsule_unlock:False",
	]):
		push_error("Cutscene start/end signals did not fire in the expected order.")
		return 1

	return 0


func _check_dialogue_flow() -> int:
	var progression := _get_progression()
	if progression == null:
		push_error("Progression autoload is unavailable.")
		return 1
	progression.reset_for_new_game()
	var loaded := await _load_test_stage_via_main()
	if loaded.is_empty():
		return 1

	var main: Node = loaded.get("main")
	var stage: Node = loaded.get("stage")
	var player: Node2D = loaded.get("player") as Node2D
	var dash_capsule: Node2D = stage.get_node_or_null("DashCapsule") as Node2D
	if player == null or dash_capsule == null:
		push_error("Dialogue flow check is missing the player or dash capsule.")
		return 1

	player.global_position = dash_capsule.global_position
	await _await_physics_frames(4)

	var overlay := await _wait_for_active_overlay(main, 20)
	if overlay == null:
		push_error("Dialogue flow did not spawn the dialogue overlay.")
		return 1

	var first_snapshot := overlay.call("get_snapshot") as Dictionary
	if not String(first_snapshot.get("footer_text", "")).contains("Cancel: skip"):
		push_error("Dialogue footer did not advertise the authored skip rule.")
		return 1

	await _tap_menu_confirm()
	await _await_physics_frames(2)
	overlay = main.call("get_active_overlay")
	if overlay == null:
		push_error("Dialogue overlay disappeared before confirm advance could be observed.")
		return 1

	var second_snapshot := overlay.call("get_snapshot") as Dictionary
	if first_snapshot.get("body_text", "") == second_snapshot.get("body_text", ""):
		push_error("menu_confirm did not advance to the next dialogue line.")
		return 1

	await _tap_menu_cancel()
	if not await _wait_for_gameflow_state(GameFlow.RuntimeState.IN_STAGE, 20):
		push_error("Dialogue skip did not return gameplay to IN_STAGE.")
		return 1

	if main.call("get_active_overlay") != null:
		push_error("Dialogue overlay was not cleared after skip.")
		return 1

	return 0


func _check_dash_unlock() -> int:
	var progression := _get_progression()
	if progression == null:
		push_error("Progression autoload is unavailable.")
		return 1
	progression.reset_for_new_game()
	var loaded := await _load_test_stage_via_main()
	if loaded.is_empty():
		return 1

	var stage: Node = loaded.get("stage")
	var player: Node = loaded.get("player")
	var dash_capsule: Node2D = stage.get_node_or_null("DashCapsule") as Node2D
	if player == null or dash_capsule == null:
		push_error("Dash unlock check is missing the player or dash capsule.")
		return 1

	if bool(player.call("is_dash_unlocked")) or bool(progression.get("dash_unlocked")):
		push_error("Dash should start locked before the capsule cutscene.")
		return 1

	await _tap_dash()
	if player.get("locomotion_state") == PLAYER_SCRIPT.LocomotionState.DASH:
		push_error("Player entered DASH before the upgrade was unlocked.")
		return 1

	player.global_position = dash_capsule.global_position
	await _await_physics_frames(4)
	if not await _wait_for_gameflow_state(GameFlow.RuntimeState.CUTSCENE, 20):
		push_error("Dash unlock check never entered CUTSCENE.")
		return 1

	await _tap_menu_cancel()
	if not await _wait_for_gameflow_state(GameFlow.RuntimeState.IN_STAGE, 20):
		push_error("Dash unlock check did not restore IN_STAGE after skipping the capsule dialogue.")
		return 1

	if not bool(progression.get("dash_unlocked")):
		push_error("Progression did not record the dash unlock.")
		return 1

	if not progression.call("has_collected_pickup", &"test_stage_dash_capsule"):
		push_error("Progression did not record the dash capsule pickup.")
		return 1

	if not bool(player.call("is_dash_unlocked")):
		push_error("Player dash availability was not updated after the capsule cutscene.")
		return 1

	await _tap_dash()
	if not await _wait_for_player_state(player, PLAYER_SCRIPT.LocomotionState.DASH, 10):
		push_error("Unlocked dash did not enter the DASH locomotion state.")
		return 1

	return 0


func _check_save_round_trip() -> int:
	var progression := _get_progression()
	var save_manager := _get_save_manager()
	if progression == null or save_manager == null:
		push_error("Save round-trip check requires Progression and SaveManager autoloads.")
		return 1

	_use_harness_save_path(save_manager)
	save_manager.call("delete_save")
	progression.reset_for_new_game()
	progression.grant_dash_unlock(&"test_stage_dash_capsule")
	if not bool(save_manager.save_game(&"round_trip_test")):
		push_error("SaveManager failed to write the round-trip save payload.")
		return 1

	progression.reset_for_new_game()
	if bool(progression.get("dash_unlocked")):
		push_error("Progression reset did not clear dash before reload.")
		return 1

	if not bool(save_manager.load_game()):
		push_error("SaveManager failed to load the round-trip save payload.")
		return 1

	if not bool(progression.get("dash_unlocked")):
		push_error("Dash unlock did not survive save/load round-trip.")
		return 1

	if not progression.call("has_collected_pickup", &"test_stage_dash_capsule"):
		push_error("Collected persistent pickup did not survive save/load round-trip.")
		return 1

	save_manager.call("delete_save")
	_clear_harness_save_path(save_manager)
	progression.reset_for_new_game()
	return 0


func _check_persistent_pickup_reload() -> int:
	var progression := _get_progression()
	var save_manager := _get_save_manager()
	if progression == null or save_manager == null:
		push_error("Persistent pickup reload check requires Progression and SaveManager autoloads.")
		return 1

	_use_harness_save_path(save_manager)
	save_manager.call("delete_save")
	progression.reset_for_new_game()

	var loaded := await _load_test_stage_via_main()
	if loaded.is_empty():
		return 1

	var stage: Node = loaded.get("stage")
	var player: Node2D = loaded.get("player") as Node2D
	var dash_capsule: Node2D = stage.get_node_or_null("DashCapsule") as Node2D
	if player == null or dash_capsule == null:
		push_error("Persistent pickup reload check is missing the player or dash capsule.")
		return 1

	player.global_position = dash_capsule.global_position
	await _await_physics_frames(4)
	await _tap_menu_cancel()
	await _await_physics_frames(4)

	if not bool(save_manager.call("has_save")):
		push_error("Collecting the persistent dash capsule did not trigger a save.")
		return 1

	progression.reset_for_new_game()
	if bool(progression.get("dash_unlocked")):
		push_error("Progression reset did not clear dash before reload.")
		return 1

	if not bool(save_manager.load_game()):
		push_error("Persistent pickup reload check failed to load the saved progression.")
		return 1

	var reloaded_stage := await _instantiate_test_stage()
	if reloaded_stage == null:
		return 1

	var reloaded_player: Node = reloaded_stage.get_node_or_null("Player")
	var reloaded_capsule: Node = reloaded_stage.get_node_or_null("DashCapsule")
	if reloaded_player == null or reloaded_capsule == null:
		push_error("Reloaded test stage is missing the player or dash capsule.")
		return 1

	if not bool(reloaded_player.call("is_dash_unlocked")):
		push_error("Reloaded player did not inherit dash unlock from saved progression.")
		return 1

	if not bool(reloaded_capsule.call("is_collected")):
		push_error("Persistent dash capsule reappeared after save/load reload.")
		return 1

	save_manager.call("delete_save")
	_clear_harness_save_path(save_manager)
	progression.reset_for_new_game()
	return 0


func _check_continue_flow() -> int:
	var progression := _get_progression()
	var save_manager := _get_save_manager()
	if progression == null or save_manager == null:
		push_error("Continue flow check requires Progression and SaveManager autoloads.")
		return 1

	_use_harness_save_path(save_manager)
	save_manager.call("delete_save")

	progression.reset_for_new_game()
	if not bool(save_manager.save_game(&"continue_intro_flow_test")):
		push_error("Continue flow check could not write the intro-return save payload.")
		return 1

	var intro_main := await _instantiate_main_scene()
	if intro_main == null:
		return 1

	var title_screen: Node = intro_main.get_node_or_null("UIRoot/TitleScreen")
	var continue_button := title_screen.get_node_or_null("CenterContainer/VBoxContainer/ContinueButton") as Button if title_screen != null else null
	if title_screen == null or continue_button == null:
		push_error("Title flow is missing the continue button.")
		return 1

	progression.reset_for_new_game()
	continue_button.emit_signal("pressed")
	await _await_physics_frames(4)

	if not await _wait_for_gameflow_state(GameFlow.RuntimeState.IN_STAGE, 20):
		push_error("Continue flow did not return the player to Intro Highway when intro was uncleared.")
		return 1

	if intro_main.get_node_or_null("WorldRoot/intro_highway") == null:
		push_error("Continue flow did not load Intro Highway from the stage start.")
		return 1

	intro_main.queue_free()
	await process_frame
	await _await_physics_frames(2)

	progression.reset_for_new_game()
	progression.mark_intro_cleared()
	progression.grant_dash_unlock(&"test_stage_dash_capsule")
	if not bool(save_manager.save_game(&"continue_stage_select_flow_test")):
		push_error("Continue flow check could not write the stage-select save payload.")
		return 1

	var stage_select_main := await _instantiate_main_scene()
	if stage_select_main == null:
		return 1

	title_screen = stage_select_main.get_node_or_null("UIRoot/TitleScreen")
	continue_button = title_screen.get_node_or_null("CenterContainer/VBoxContainer/ContinueButton") as Button if title_screen != null else null
	if title_screen == null or continue_button == null:
		push_error("Title flow is missing the continue button for stage-select restore.")
		return 1

	progression.reset_for_new_game()
	continue_button.emit_signal("pressed")
	await _await_physics_frames(4)

	if not await _wait_for_gameflow_state(GameFlow.RuntimeState.STAGE_SELECT, 20):
		push_error("Continue flow did not route an intro-cleared save to Stage Select.")
		return 1

	if stage_select_main.get_node_or_null("UIRoot/StageSelectMenu") == null:
		push_error("Continue flow did not load the Stage Select UI.")
		return 1

	if stage_select_main.get_node_or_null("WorldRoot/intro_highway") != null:
		push_error("Continue flow incorrectly loaded Intro Highway for an intro-cleared save.")
		return 1

	save_manager.call("delete_save")
	_clear_harness_save_path(save_manager)
	progression.reset_for_new_game()
	return 0


func _check_stage_select_roster() -> int:
	var progression := _get_progression()
	var game_flow := root.get_node_or_null("/root/GameFlow")
	if progression == null or game_flow == null:
		push_error("Stage select roster check requires Progression and GameFlow.")
		return 1

	var main := await _instantiate_main_scene()
	if main == null:
		return 1

	progression.reset_for_new_game()
	game_flow.request_stage_select()
	await _await_physics_frames(2)

	var menu := main.get_node_or_null("UIRoot/StageSelectMenu")
	var chill_button := menu.get_node_or_null("MarginContainer/Panel/VBoxContainer/RosterGrid/chill_penguinButton") as Button if menu != null else null
	var fortress_button := menu.get_node_or_null("MarginContainer/Panel/VBoxContainer/RosterGrid/sigma_fortress_1Button") as Button if menu != null else null
	if menu == null or chill_button == null or fortress_button == null:
		push_error("Stage select roster check could not find the expected stage buttons.")
		return 1

	if not chill_button.disabled:
		push_error("Maverick stages should stay locked before Intro Highway is cleared.")
		return 1

	if not fortress_button.disabled:
		push_error("Sigma Fortress 1 should stay locked before the Maverick bosses are defeated.")
		return 1

	progression.mark_intro_cleared()
	game_flow.request_stage_select()
	await _await_physics_frames(2)

	menu = main.get_node_or_null("UIRoot/StageSelectMenu")
	chill_button = menu.get_node_or_null("MarginContainer/Panel/VBoxContainer/RosterGrid/chill_penguinButton") as Button if menu != null else null
	fortress_button = menu.get_node_or_null("MarginContainer/Panel/VBoxContainer/RosterGrid/sigma_fortress_1Button") as Button if menu != null else null
	if menu == null or chill_button == null or fortress_button == null:
		push_error("Stage select roster check lost the expected buttons after refresh.")
		return 1

	if chill_button.disabled:
		push_error("Maverick stages did not unlock after Intro Highway clear.")
		return 1

	if not fortress_button.disabled:
		push_error("Sigma Fortress 1 unlocked too early.")
		return 1

	return 0


func _check_stage_select_loading() -> int:
	var progression := _get_progression()
	var game_flow := root.get_node_or_null("/root/GameFlow")
	if progression == null or game_flow == null:
		push_error("Stage select loading check requires Progression and GameFlow.")
		return 1

	progression.reset_for_new_game()
	progression.mark_intro_cleared()

	var main := await _instantiate_main_scene()
	if main == null:
		return 1

	game_flow.request_stage_select()
	await _await_physics_frames(2)

	var menu := main.get_node_or_null("UIRoot/StageSelectMenu")
	var chill_button := menu.get_node_or_null("MarginContainer/Panel/VBoxContainer/RosterGrid/chill_penguinButton") as Button if menu != null else null
	if menu == null or chill_button == null:
		push_error("Stage select loading check could not resolve the Chill Penguin stage button.")
		return 1

	chill_button.emit_signal("pressed")
	await _await_physics_frames(4)

	if not await _wait_for_gameflow_state(GameFlow.RuntimeState.IN_STAGE, 20):
		push_error("Selecting an unlocked stage did not switch GameFlow into IN_STAGE.")
		return 1

	var active_stage := main.get_node_or_null("WorldRoot/chill_penguin")
	var hud := main.get_node_or_null("UIRoot/GameplayHUD")
	if active_stage == null or hud == null:
		push_error("Selecting Chill Penguin did not load the stage + HUD stack.")
		return 1

	if String(active_stage.scene_file_path) != "res://scenes/stages/campaign/CampaignStagePlaceholder.tscn":
		push_error("Selecting Chill Penguin loaded the wrong stage scene.")
		return 1

	return 0


func _check_fortress_unlock_flow() -> int:
	var progression := _get_progression()
	var game_flow := root.get_node_or_null("/root/GameFlow")
	if progression == null or game_flow == null:
		push_error("Fortress unlock flow check requires Progression and GameFlow.")
		return 1

	progression.reset_for_new_game()
	progression.mark_intro_cleared()

	if bool(game_flow.is_stage_unlocked(&"sigma_fortress_1")):
		push_error("Sigma Fortress 1 should not unlock before the Maverick bosses are defeated.")
		return 1

	for boss_id in [&"chill_penguin", &"storm_eagle", &"flame_mammoth", &"spark_mandrill", &"armored_armadillo", &"launch_octopus", &"boomer_kuwanger"]:
		progression.mark_boss_defeated(boss_id)

	if bool(game_flow.is_stage_unlocked(&"sigma_fortress_1")):
		push_error("Sigma Fortress 1 unlocked before the full Maverick roster was defeated.")
		return 1

	progression.mark_boss_defeated(&"sting_chameleon")
	if not bool(game_flow.is_stage_unlocked(&"sigma_fortress_1")):
		push_error("Sigma Fortress 1 did not unlock after all Maverick bosses were defeated.")
		return 1

	if bool(game_flow.is_stage_unlocked(&"sigma_fortress_2")):
		push_error("Sigma Fortress 2 unlocked before Sigma Fortress 1 was cleared.")
		return 1

	progression.mark_stage_cleared(&"sigma_fortress_1")
	if not bool(game_flow.is_stage_unlocked(&"sigma_fortress_2")):
		push_error("Sigma Fortress 2 did not unlock after Sigma Fortress 1 clear.")
		return 1

	if bool(game_flow.is_stage_unlocked(&"sigma_fortress_3")):
		push_error("Sigma Fortress 3 unlocked before Sigma Fortress 2 was cleared.")
		return 1

	progression.mark_stage_cleared(&"sigma_fortress_2")
	if not bool(game_flow.is_stage_unlocked(&"sigma_fortress_3")):
		push_error("Sigma Fortress 3 did not unlock after Sigma Fortress 2 clear.")
		return 1

	progression.mark_stage_cleared(&"sigma_fortress_3")
	if not bool(game_flow.is_stage_unlocked(&"sigma_fortress_4")):
		push_error("Sigma Fortress 4 did not unlock after Sigma Fortress 3 clear.")
		return 1

	return 0


func _check_weapon_reward_unlock() -> int:
	var progression := _get_progression()
	var game_flow := root.get_node_or_null("/root/GameFlow")
	if progression == null or game_flow == null:
		push_error("Weapon reward unlock check requires Progression and GameFlow.")
		return 1

	progression.reset_for_new_game()
	progression.mark_intro_cleared()

	var main := await _instantiate_main_scene()
	if main == null:
		return 1

	game_flow.request_stage(&"chill_penguin")
	await _await_physics_frames(3)

	var stage := main.get_node_or_null("WorldRoot/chill_penguin")
	var stage_controller := stage.get_node_or_null("StageController") if stage != null else null
	if stage == null or stage_controller == null:
		push_error("Weapon reward unlock check could not load the Chill Penguin placeholder stage.")
		return 1

	stage_controller.call("begin_stage_clear", &"reward_unlock_test")
	await _await_physics_frames(2)

	if not progression.has_weapon_unlocked(&"shotgun_ice"):
		push_error("Clearing Chill Penguin did not unlock the Shotgun Ice reward.")
		return 1

	game_flow.request_stage(&"test_stage")
	await _await_physics_frames(3)

	var player := main.get_node_or_null("WorldRoot/test_stage/Player")
	var inventory := player.get_node_or_null("PlayerCombat/WeaponInventory") if player != null else null
	if player == null or inventory == null:
		push_error("Weapon reward unlock check could not load the test stage inventory after the reward unlock.")
		return 1

	if not bool(inventory.call("has_weapon_unlocked", &"shotgun_ice")):
		push_error("Unlocked Shotgun Ice reward did not appear in the player inventory.")
		return 1

	if not bool(inventory.call("equip_weapon", &"shotgun_ice")):
		push_error("Unlocked Shotgun Ice reward could not be equipped from the player inventory.")
		return 1

	return 0


func _check_weakness_tables() -> int:
	var progression := _get_progression()
	if progression == null:
		push_error("Weakness table check requires Progression.")
		return 1

	progression.reset_for_new_game()
	progression.unlock_weapon(&"shotgun_ice")
	progression.unlock_weapon(&"fire_wave")
	progression.unlock_weapon(&"storm_tornado")

	var loaded := await _load_test_stage_via_main()
	var stage: Node = loaded.get("stage")
	var player: Node = loaded.get("player")
	var combat: Node = player.get_node_or_null("PlayerCombat") if player != null else null
	var normal_hurtbox := stage.get_node_or_null("TestDummy/Hurtbox") if stage != null else null
	var normal_health := stage.get_node_or_null("TestDummy/HealthComponent") if stage != null else null
	var weak_hurtbox := stage.get_node_or_null("WeaknessDummy/Hurtbox") if stage != null else null
	var weak_health := stage.get_node_or_null("WeaknessDummy/HealthComponent") if stage != null else null
	if stage == null or player == null or combat == null or normal_hurtbox == null or normal_health == null or weak_hurtbox == null or weak_health == null:
		push_error("Weakness table check could not resolve the required test-stage nodes.")
		return 1

	combat.call("reset_combat")
	combat.call("get_current_weapon")

	combat.get_node("WeaponInventory").call("equip_weapon", &"shotgun_ice")
	normal_health.call("reset")
	weak_health.call("reset")
	normal_hurtbox.call("apply_hit_payload", HIT_PAYLOAD_SCRIPT.create(self, &"player", &"shotgun_ice", 2, Vector2.ZERO))
	weak_hurtbox.call("apply_hit_payload", HIT_PAYLOAD_SCRIPT.create(self, &"player", &"shotgun_ice", 2, Vector2.ZERO))
	await _await_physics_frames(1)

	if int(normal_health.get("current_health")) != int(normal_health.get("max_health")) - 2:
		push_error("Normal targets did not take the expected baseline Shotgun Ice damage.")
		return 1

	if int(weak_health.get("current_health")) != int(weak_health.get("max_health")) - 4:
		push_error("Weakness target did not take amplified Shotgun Ice damage.")
		return 1

	weak_health.call("reset")
	combat.get_node("WeaponInventory").call("equip_weapon", &"fire_wave")
	weak_hurtbox.call("apply_hit_payload", HIT_PAYLOAD_SCRIPT.create(self, &"player", &"fire_wave", 2, Vector2.ZERO))
	await _await_physics_frames(1)
	if int(weak_health.get("current_health")) != int(weak_health.get("max_health")) - 1:
		push_error("Resistance table did not reduce Fire Wave damage as expected.")
		return 1

	weak_health.call("reset")
	combat.get_node("WeaponInventory").call("equip_weapon", &"storm_tornado")
	var immunity_hit := bool(weak_hurtbox.call("apply_hit_payload", HIT_PAYLOAD_SCRIPT.create(self, &"player", &"storm_tornado", 3, Vector2.ZERO)))
	await _await_physics_frames(1)
	if immunity_hit or int(weak_health.get("current_health")) != int(weak_health.get("max_health")):
		push_error("Immunity table did not reject Storm Tornado damage.")
		return 1

	return 0


func _check_weapon_energy_costs() -> int:
	var progression := _get_progression()
	if progression == null:
		push_error("Weapon energy cost check requires Progression.")
		return 1

	progression.reset_for_new_game()
	progression.unlock_weapon(&"shotgun_ice")

	var loaded := await _load_test_stage_via_main()
	var stage: Node = loaded.get("stage")
	var hud: Node = loaded.get("hud")
	var player: Node = loaded.get("player")
	var combat: Node = player.get_node_or_null("PlayerCombat") if player != null else null
	var inventory := combat.get_node_or_null("WeaponInventory") if combat != null else null
	var dummy := stage.get_node_or_null("TestDummy") if stage != null else null
	if stage == null or hud == null or player == null or combat == null or inventory == null or dummy == null:
		push_error("Weapon energy cost check could not resolve the test-stage weapon nodes.")
		return 1

	if not bool(inventory.call("equip_weapon", &"shotgun_ice")):
		push_error("Weapon energy cost check could not equip Shotgun Ice.")
		return 1

	var initial_snapshot := hud.call("get_snapshot") as Dictionary
	if initial_snapshot.get("energy_text", "") != "32 / 32":
		push_error("HUD did not expose the expected starting weapon energy for Shotgun Ice.")
		return 1

	if not bool(combat.call("fire_equipped_weapon", &"uncharged")):
		push_error("Weapon energy cost check could not fire the equipped Shotgun Ice weapon.")
		return 1

	await _await_physics_frames(16)
	dummy.call("reset_for_stage_retry")

	var post_shot_snapshot := hud.call("get_snapshot") as Dictionary
	if post_shot_snapshot.get("energy_text", "") != "30 / 32":
		push_error("HUD did not update after Shotgun Ice consumed weapon energy.")
		return 1

	for _shot in range(15):
		if not bool(combat.call("fire_equipped_weapon", &"uncharged")):
			push_error("Shotgun Ice stopped firing before its weapon energy was fully depleted.")
			return 1
		await _await_physics_frames(16)
		dummy.call("reset_for_stage_retry")

	if int(combat.call("get_current_weapon_energy")) != 0:
		push_error("Shotgun Ice did not drain to zero energy after the expected number of shots.")
		return 1

	if bool(combat.call("fire_equipped_weapon", &"uncharged")):
		push_error("Shotgun Ice still fired after its energy was fully depleted.")
		return 1

	var depleted_snapshot := hud.call("get_snapshot") as Dictionary
	if depleted_snapshot.get("energy_text", "") != "0 / 32":
		push_error("HUD did not show the fully depleted weapon energy state.")
		return 1

	return 0


func _check_unlock_all_weapons_shortcut() -> int:
	var progression := _get_progression()
	if progression == null:
		push_error("Unlock-all-weapons shortcut check requires Progression.")
		return 1

	progression.reset_for_new_game()
	var stage := await _instantiate_test_stage()
	var inventory := stage.get_node_or_null("Player/PlayerCombat/WeaponInventory") if stage != null else null
	if stage == null or inventory == null:
		push_error("Unlock-all-weapons shortcut check could not resolve the test stage inventory.")
		return 1

	if int(inventory.call("get_unlocked_weapon_count")) != 1:
		push_error("Test stage should begin with only the buster unlocked.")
		return 1

	Input.parse_input_event(_key_event(KEY_U, true))
	await _await_physics_frames(1)
	Input.parse_input_event(_key_event(KEY_U, false))
	await _await_physics_frames(1)

	if int(inventory.call("get_unlocked_weapon_count")) <= 1:
		push_error("Pressing U in the test stage did not unlock the boss weapon roster.")
		return 1

	if not progression.has_weapon_unlocked(&"shotgun_ice") or not progression.has_weapon_unlocked(&"storm_tornado"):
		push_error("Unlock-all-weapons shortcut did not populate the expected progression unlocks.")
		return 1

	return 0


func _check_persistent_upgrade_types() -> int:
	var progression := _get_progression()
	if progression == null:
		push_error("Persistent upgrade type check requires Progression.")
		return 1

	progression.reset_for_new_game()
	var stage := await _instantiate_test_stage()
	var player := stage.get_node_or_null("Player")
	var pickup_receiver := player.get_node_or_null("PickupReceiver") if player != null else null
	var heart_pickup := stage.get_node_or_null("HeartTankPickup")
	var armor_pickup := stage.get_node_or_null("ArmorCapsulePickup")
	var sub_tank_pickup := stage.get_node_or_null("SubTankPickup")
	if player == null or pickup_receiver == null or heart_pickup == null or armor_pickup == null or sub_tank_pickup == null:
		push_error("Persistent upgrade type check could not resolve the test-stage pickup nodes.")
		return 1

	var initial_max_health := int(player.get_node("HealthComponent").get("max_health"))
	if not bool(heart_pickup.call("collect", pickup_receiver)):
		push_error("Heart tank pickup did not collect through PickupReceiver.")
		return 1

	if not progression.has_collected_pickup(&"test_stage_heart_tank") or not progression.has_heart_tank_collected(&"test_stage_heart_tank"):
		push_error("Heart tank pickup did not record its persistent progression facts.")
		return 1

	if int(player.get_node("HealthComponent").get("max_health")) != initial_max_health + 2:
		push_error("Heart tank pickup did not increase the player's maximum HP.")
		return 1

	if bool(heart_pickup.call("collect", pickup_receiver)):
		push_error("Heart tank pickup collected twice instead of remaining persistent.")
		return 1

	if not bool(armor_pickup.call("collect", pickup_receiver)):
		push_error("Armor capsule pickup did not collect through PickupReceiver.")
		return 1

	if not progression.has_collected_pickup(&"test_stage_body_capsule") or not progression.has_armor_part(&"body"):
		push_error("Armor capsule pickup did not record the body armor progression facts.")
		return 1

	if not bool(sub_tank_pickup.call("collect", pickup_receiver)):
		push_error("Sub tank pickup did not collect through PickupReceiver.")
		return 1

	if not progression.has_collected_pickup(&"test_stage_sub_tank") or not progression.has_sub_tank(&"sub_tank_alpha"):
		push_error("Sub tank pickup did not record ownership in progression.")
		return 1

	if int(progression.get_sub_tank_fill(&"sub_tank_alpha")) != 10:
		push_error("Sub tank pickup did not apply the expected initial fill amount.")
		return 1

	return 0


func _check_upgrade_save_reload() -> int:
	var progression := _get_progression()
	var save_manager := _get_save_manager()
	if progression == null or save_manager == null:
		push_error("Upgrade save/reload check requires Progression and SaveManager.")
		return 1

	_use_harness_save_path(save_manager)
	save_manager.call("delete_save")
	progression.reset_for_new_game()

	var stage := await _instantiate_test_stage()
	var player := stage.get_node_or_null("Player")
	var pickup_receiver := player.get_node_or_null("PickupReceiver") if player != null else null
	var heart_pickup := stage.get_node_or_null("HeartTankPickup")
	var armor_pickup := stage.get_node_or_null("ArmorCapsulePickup")
	if player == null or pickup_receiver == null or heart_pickup == null or armor_pickup == null:
		push_error("Upgrade save/reload check could not resolve the test-stage pickup nodes.")
		return 1

	heart_pickup.call("collect", pickup_receiver)
	armor_pickup.call("collect", pickup_receiver)
	if not bool(save_manager.call("has_save")):
		push_error("Collecting heart tank and armor capsule did not trigger a save.")
		return 1

	progression.reset_for_new_game()
	if not bool(save_manager.load_game()):
		push_error("Upgrade save/reload check failed to load the saved progression payload.")
		return 1

	var reloaded_stage := await _instantiate_test_stage()
	var reloaded_player := reloaded_stage.get_node_or_null("Player")
	var reloaded_heart := reloaded_stage.get_node_or_null("HeartTankPickup")
	var reloaded_armor := reloaded_stage.get_node_or_null("ArmorCapsulePickup")
	if reloaded_player == null or reloaded_heart == null or reloaded_armor == null:
		push_error("Reloaded test stage is missing the player, heart tank, or armor capsule.")
		return 1

	if int(reloaded_player.get_node("HealthComponent").get("max_health")) != 18:
		push_error("Heart tank bonus did not survive save/load into the player's maximum HP.")
		return 1

	if not bool(reloaded_heart.call("is_collected")) or not bool(reloaded_armor.call("is_collected")):
		push_error("Persistent upgrade pickups reappeared after save/load reload.")
		return 1

	var reloaded_health: Node = reloaded_player.get_node_or_null("HealthComponent")
	reloaded_player.call("apply_hit_payload", HIT_PAYLOAD_SCRIPT.create(self, &"enemy", &"body_armor_test", 4, Vector2.ZERO))
	await _await_physics_frames(1)
	if reloaded_health == null or int(reloaded_health.get("current_health")) != 15:
		push_error("Body armor mitigation did not survive save/load.")
		return 1

	save_manager.call("delete_save")
	_clear_harness_save_path(save_manager)
	return 0


func _check_sub_tank_round_trip() -> int:
	var progression := _get_progression()
	var save_manager := _get_save_manager()
	if progression == null or save_manager == null:
		push_error("Sub tank round-trip check requires Progression and SaveManager.")
		return 1

	_use_harness_save_path(save_manager)
	save_manager.call("delete_save")
	progression.reset_for_new_game()

	var stage := await _instantiate_test_stage()
	var player := stage.get_node_or_null("Player")
	var pickup_receiver := player.get_node_or_null("PickupReceiver") if player != null else null
	var sub_tank_pickup := stage.get_node_or_null("SubTankPickup")
	var player_health := player.get_node_or_null("HealthComponent") if player != null else null
	if player == null or pickup_receiver == null or sub_tank_pickup == null or player_health == null:
		push_error("Sub tank round-trip check could not resolve the test-stage sub tank nodes.")
		return 1

	sub_tank_pickup.call("collect", pickup_receiver)
	player_health.call("apply_hit_payload", HIT_PAYLOAD_SCRIPT.create(self, &"enemy", &"sub_tank_damage_test", 6, Vector2.ZERO))
	await _await_physics_frames(1)
	if not bool(pickup_receiver.call("use_sub_tank")):
		push_error("Sub tank round-trip check could not use the owned filled sub tank.")
		return 1

	if int(progression.get_sub_tank_fill(&"sub_tank_alpha")) != 4:
		push_error("Sub tank usage did not update the remaining fill correctly before save.")
		return 1

	if not bool(save_manager.save_game(&"sub_tank_round_trip_test")):
		push_error("Sub tank round-trip check failed to write the save payload.")
		return 1

	progression.reset_for_new_game()
	if not bool(save_manager.load_game()):
		push_error("Sub tank round-trip check failed to load the saved progression payload.")
		return 1

	if not progression.has_sub_tank(&"sub_tank_alpha") or int(progression.get_sub_tank_fill(&"sub_tank_alpha")) != 4:
		push_error("Sub tank ownership or fill state did not survive save/load.")
		return 1

	save_manager.call("delete_save")
	_clear_harness_save_path(save_manager)
	return 0


func _check_pickup_collision() -> int:
	var stage := await _instantiate_test_stage()
	if stage == null:
		return 1

	var player: Node2D = stage.get_node_or_null("Player") as Node2D
	if player == null:
		push_error("Pickup collision check could not find the player.")
		return 1

	var player_health: Node = player.call("get_health_component")
	if player_health == null:
		push_error("Pickup collision check could not resolve the player's health component.")
		return 1

	player_health.call("apply_hit_payload", HIT_PAYLOAD_SCRIPT.create(self, &"enemy", &"pickup_test_damage", 4, Vector2.ZERO))
	await _await_physics_frames(2)

	var health_before := int(player_health.get("current_health"))
	if health_before >= int(player_health.get("max_health")):
		push_error("Pickup collision check expected the player to be damaged before collecting a drop.")
		return 1

	var drop_scene := load("res://scenes/pickups/TemporaryDropSmall.tscn") as PackedScene
	if drop_scene == null:
		push_error("Pickup collision check could not load TemporaryDropSmall.tscn.")
		return 1

	var drop := drop_scene.instantiate() as Area2D
	if drop == null:
		push_error("Pickup collision check could not instantiate TemporaryDropSmall.")
		return 1

	stage.add_child(drop)
	drop.global_position = player.global_position
	await _await_physics_frames(3)

	if is_instance_valid(drop):
		push_error("Temporary drop was not collected by PlayerSensor overlap.")
		return 1

	if int(player_health.get("current_health")) <= health_before:
		push_error("Collecting TemporaryDropSmall did not restore player health.")
		return 1

	return 0


func _instantiate_test_stage() -> Node2D:
	var stage_scene := load("res://scenes/stages/test/TestStage.tscn") as PackedScene
	if stage_scene == null:
		push_error("Unable to load TestStage.tscn.")
		return null

	var instance := stage_scene.instantiate() as Node2D
	root.add_child(instance)
	await process_frame
	await _await_physics_frames(2)
	return instance


func _cleanup_loaded_nodes() -> void:
	for child in root.get_children():
		if child == null:
			continue

		var child_path := child.get_path()
		if str(child_path).begins_with("/root/GameFlow") \
			or str(child_path).begins_with("/root/Progression") \
			or str(child_path).begins_with("/root/SaveManager") \
			or str(child_path).begins_with("/root/AudioManager"):
			continue

		child.queue_free()

	await process_frame
	await physics_frame
	await process_frame


func _instantiate_main_scene() -> Node:
	var main_scene := load("res://scenes/Main.tscn") as PackedScene
	if main_scene == null:
		push_error("Unable to load Main.tscn.")
		return null

	var instance := main_scene.instantiate()
	root.add_child(instance)
	await process_frame
	await process_frame
	return instance


func _load_test_stage_via_main() -> Dictionary:
	var main := await _instantiate_main_scene()
	if main == null:
		return {}

	var game_flow := root.get_node_or_null("/root/GameFlow")
	if game_flow == null:
		push_error("GameFlow autoload is unavailable.")
		return {}

	game_flow.request_stage(&"test_stage")
	await process_frame
	await _await_physics_frames(3)

	var stage := main.get_node_or_null("WorldRoot/test_stage")
	var hud := main.get_node_or_null("UIRoot/GameplayHUD")
	var player := stage.get_node_or_null("Player") if stage != null else null
	if stage == null or hud == null or player == null:
		push_error("Main scene did not load the test stage HUD stack.")
		return {}

	return {
		"main": main,
		"stage": stage,
		"hud": hud,
		"player": player,
	}


func _defeat_walker_enemy(enemy: Node) -> void:
	var enemy_health: Node = enemy.get_node_or_null("HealthComponent")
	var enemy_hurtbox := enemy.get_node_or_null("Hurtbox")
	if enemy_health == null or enemy_hurtbox == null:
		return

	var lethal_hit := HIT_PAYLOAD_SCRIPT.create(self, &"player", &"enemy_test_buster", int(enemy_health.get("max_health")), Vector2.ZERO)
	enemy_hurtbox.call("apply_hit_payload", lethal_hit)
	await process_frame
	await _await_physics_frames(2)


func _wait_for_retry_count(stage_controller: Node, expected_retry_count: int, max_frames: int) -> bool:
	for _frame in range(max_frames):
		if int(stage_controller.get("retry_count")) >= expected_retry_count:
			return true

		await _await_physics_frames(1)

	return false


func _wait_for_active_checkpoint(stage_controller: Node, expected_checkpoint_id: StringName, max_frames: int) -> bool:
	for _frame in range(max_frames):
		if stage_controller.call("get_active_checkpoint_id") == expected_checkpoint_id:
			return true

		await _await_physics_frames(1)

	return false


func _wait_for_gameflow_state(expected_state: int, max_frames: int) -> bool:
	for _frame in range(max_frames):
		var game_flow := root.get_node_or_null("/root/GameFlow")
		if game_flow != null and int(game_flow.get("current_state")) == expected_state:
			return true

		await _await_physics_frames(1)

	return false


func _wait_for_player_state(player: Node, expected_state: int, max_frames: int) -> bool:
	for _frame in range(max_frames):
		if player.get("locomotion_state") == expected_state:
			return true

		await _await_physics_frames(1)

	return false


func _wait_for_projectile_count(combat: Node, expected_count: int, max_frames: int) -> bool:
	for _frame in range(max_frames):
		if int(combat.call("get_active_projectile_count")) >= expected_count:
			return true

		await _await_physics_frames(1)

	return false


func _wait_for_active_overlay(main: Node, max_frames: int) -> Control:
	for _frame in range(max_frames):
		var overlay := main.call("get_active_overlay") as Control
		if overlay != null:
			return overlay

		await _await_physics_frames(1)

	return null


func _key_event(keycode: Key, pressed: bool) -> InputEventKey:
	var event := InputEventKey.new()
	event.physical_keycode = keycode
	event.pressed = pressed
	return event


func _get_progression() -> Node:
	return root.get_node_or_null("/root/Progression")


func _get_save_manager() -> Node:
	return root.get_node_or_null("/root/SaveManager")


func _use_harness_save_path(save_manager: Node) -> void:
	if save_manager != null:
		save_manager.set("override_save_path", "user://phase_1_harness_save.json")


func _clear_harness_save_path(save_manager: Node) -> void:
	if save_manager != null:
		save_manager.set("override_save_path", "")


func _await_physics_frames(frame_count: int) -> void:
	for _frame in range(frame_count):
		await physics_frame


func _tap_action(action_name: StringName, hold_frames: int = 1) -> void:
	Input.action_press(action_name)
	await _await_physics_frames(hold_frames)
	Input.action_release(action_name)
	await _await_physics_frames(1)


func _tap_shoot(hold_frames: int = 1) -> void:
	await _tap_action(&"shoot", hold_frames)


func _tap_dash(hold_frames: int = 1) -> void:
	await _tap_action(&"dash", hold_frames)


func _tap_menu_confirm(hold_frames: int = 1) -> void:
	await _tap_action(&"menu_confirm", hold_frames)


func _tap_menu_cancel(hold_frames: int = 1) -> void:
	await _tap_action(&"menu_cancel", hold_frames)


func _physics_frames_for_seconds(duration: float) -> int:
	return maxi(1, ceili(duration * float(Engine.physics_ticks_per_second)))


func _history_contains_order(history: Array[String], expected_order: Array[String]) -> bool:
	var current_index := 0
	for entry in history:
		if current_index >= expected_order.size():
			return true
		if entry == expected_order[current_index]:
			current_index += 1

	return current_index >= expected_order.size()


func _combat_state_name_from_value(state: int) -> String:
	match state:
		PLAYER_COMBAT_SCRIPT.CombatState.READY:
			return "READY"
		PLAYER_COMBAT_SCRIPT.CombatState.FIRING:
			return "FIRING"
		PLAYER_COMBAT_SCRIPT.CombatState.CHARGING:
			return "CHARGING"
		PLAYER_COMBAT_SCRIPT.CombatState.CHARGED:
			return "CHARGED"
		PLAYER_COMBAT_SCRIPT.CombatState.COOLDOWN:
			return "COOLDOWN"
		PLAYER_COMBAT_SCRIPT.CombatState.DISABLED:
			return "DISABLED"
		_:
			return "UNKNOWN"


func _release_test_actions() -> void:
	for action_name in ["move_left", "move_right", "jump", "dash", "shoot", "menu_confirm", "menu_cancel"]:
		Input.action_release(action_name)
