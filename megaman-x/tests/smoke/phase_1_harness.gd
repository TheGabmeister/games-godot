extends SceneTree

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
		_:
			push_error("Unknown Phase 1 harness mode: %s" % arguments[0])

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
