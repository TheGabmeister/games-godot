extends SceneTree

const PLAYER_SCRIPT = preload("res://scripts/player/player.gd")
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
		_:
			push_error("Unknown harness mode: %s" % arguments[0])

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


func _wait_for_retry_count(stage_controller: Node, expected_retry_count: int, max_frames: int) -> bool:
	for _frame in range(max_frames):
		if int(stage_controller.get("retry_count")) >= expected_retry_count:
			return true

		await _await_physics_frames(1)

	return false


func _wait_for_player_state(player: Node, expected_state: int, max_frames: int) -> bool:
	for _frame in range(max_frames):
		if player.get("locomotion_state") == expected_state:
			return true

		await _await_physics_frames(1)

	return false


func _await_physics_frames(frame_count: int) -> void:
	for _frame in range(frame_count):
		await physics_frame


func _release_test_actions() -> void:
	for action_name in ["move_left", "move_right", "jump", "dash"]:
		Input.action_release(action_name)
