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

	var launch_button := title_screen.get_node_or_null("CenterContainer/VBoxContainer/LaunchTestStageButton")
	if launch_button == null:
		push_error("TitleScreen is missing its launch button.")
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

	await _tap_shoot()
	if not await _wait_for_projectile_count(combat, 1, 20):
		push_error("Firing did not spawn a projectile.")
		return 1

	var spawn_position := get_meta(&"projectile_spawn_position", Vector2.INF) as Vector2
	if spawn_position == Vector2.INF:
		push_error("Combat did not report a projectile spawn event.")
		return 1

	if spawn_position.distance_to(shot_origin.global_position) > 0.1:
		push_error("Projectile spawn did not use ShotOrigin.")
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

	for event_id in [&"player_buster_shot", &"player_charge_start", &"player_charge_full", &"player_charge_release", &"player_hurt"]:
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


func _await_physics_frames(frame_count: int) -> void:
	for _frame in range(frame_count):
		await physics_frame


func _tap_shoot(hold_frames: int = 1) -> void:
	Input.action_press("shoot")
	await _await_physics_frames(hold_frames)
	Input.action_release("shoot")
	await _await_physics_frames(1)


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
	for action_name in ["move_left", "move_right", "jump", "dash", "shoot"]:
		Input.action_release(action_name)
