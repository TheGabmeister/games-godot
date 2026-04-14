extends Control

const TEST_STAGE_ID := &"test_stage"

@onready var new_game_button: Button = $CenterContainer/VBoxContainer/NewGameButton
@onready var continue_button: Button = $CenterContainer/VBoxContainer/ContinueButton
@onready var stage_select_button: Button = $CenterContainer/VBoxContainer/StageSelectButton
@onready var debug_button: Button = $CenterContainer/VBoxContainer/DebugTestStageButton
@onready var registered_stages_label: Label = $CenterContainer/VBoxContainer/RegisteredStagesLabel
@onready var save_status_label: Label = $CenterContainer/VBoxContainer/SaveStatusLabel


func _ready() -> void:
	new_game_button.pressed.connect(_on_new_game_button_pressed)
	continue_button.pressed.connect(_on_continue_button_pressed)
	stage_select_button.pressed.connect(_on_stage_select_button_pressed)
	debug_button.pressed.connect(_on_debug_button_pressed)
	debug_button.disabled = GameFlow.get_registered_stage(TEST_STAGE_ID) == null

	var stage_entries := GameFlow.get_stage_select_entries()
	var maverick_count := 0
	var fortress_count := 0
	for entry in stage_entries:
		match entry.get("stage_group", &""):
			&"maverick":
				maverick_count += 1
			&"fortress":
				fortress_count += 1

	registered_stages_label.text = "Roster loaded: %d Maverick stages | %d Fortress stages" % [maverick_count, fortress_count]
	_refresh_save_ui()


func _on_new_game_button_pressed() -> void:
	GameFlow.start_new_game()


func _on_continue_button_pressed() -> void:
	GameFlow.continue_from_save()


func _on_stage_select_button_pressed() -> void:
	GameFlow.request_stage_select()


func _on_debug_button_pressed() -> void:
	GameFlow.request_stage(TEST_STAGE_ID)


func _refresh_save_ui() -> void:
	var has_save := SaveManager.has_save()
	continue_button.disabled = not has_save
	stage_select_button.disabled = not GameFlow.can_access_stage_select()
	if not has_save:
		save_status_label.text = "Save data: none | New Game enters Intro Highway."
		return

	var continue_destination := "Stage Select" if Progression.intro_cleared else "Intro Highway"
	save_status_label.text = "Continue -> %s | dash=%s | bosses=%d | pickups=%d" % [
		continue_destination,
		"unlocked" if Progression.dash_unlocked else "locked",
		Progression.defeated_bosses.size(),
		Progression.collected_pickups.size(),
	]
