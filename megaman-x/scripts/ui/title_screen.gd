extends Control

const TEST_STAGE_ID := &"test_stage"

@onready var launch_button: Button = $CenterContainer/VBoxContainer/LaunchTestStageButton
@onready var registered_stages_label: Label = $CenterContainer/VBoxContainer/RegisteredStagesLabel


func _ready() -> void:
	launch_button.pressed.connect(_on_launch_test_stage_button_pressed)
	launch_button.disabled = GameFlow.get_registered_stage(TEST_STAGE_ID) == null

	var stage_names: Array[String] = []
	for stage_id in GameFlow.get_registered_stage_ids():
		stage_names.append(String(stage_id))

	stage_names.sort()
	var registered_text := "none"
	if not stage_names.is_empty():
		registered_text = ", ".join(stage_names)

	registered_stages_label.text = "Registered stages: %s" % registered_text


func _on_launch_test_stage_button_pressed() -> void:
	GameFlow.request_stage(TEST_STAGE_ID)
