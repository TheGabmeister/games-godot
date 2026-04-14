extends Control

const TEST_STAGE_ID := &"test_stage"

@onready var summary_label: Label = $MarginContainer/Panel/VBoxContainer/SummaryLabel
@onready var roster_grid: GridContainer = $MarginContainer/Panel/VBoxContainer/RosterGrid
@onready var footer_label: Label = $MarginContainer/Panel/VBoxContainer/FooterLabel
@onready var back_button: Button = $MarginContainer/Panel/VBoxContainer/FooterButtons/BackButton
@onready var debug_button: Button = $MarginContainer/Panel/VBoxContainer/FooterButtons/DebugButton


func _ready() -> void:
	back_button.pressed.connect(_on_back_button_pressed)
	debug_button.pressed.connect(_on_debug_button_pressed)
	debug_button.disabled = GameFlow.get_registered_stage(TEST_STAGE_ID) == null
	_rebuild_roster()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"menu_cancel"):
		var viewport := get_viewport()
		if viewport != null:
			viewport.set_input_as_handled()
		_on_back_button_pressed()


func _rebuild_roster() -> void:
	for child in roster_grid.get_children():
		roster_grid.remove_child(child)
		child.queue_free()

	var entries := GameFlow.get_stage_select_entries()
	var unlocked_mavericks := 0
	var unlocked_fortress := 0
	var first_unlocked_button: Button = null

	for entry in entries:
		var button := Button.new()
		var stage_id := entry.get("stage_id", &"") as StringName
		var is_unlocked := bool(entry.get("unlocked", false))
		var is_cleared := bool(entry.get("cleared", false))
		var stage_group := entry.get("stage_group", &"") as StringName
		button.name = "%sButton" % String(stage_id)
		button.custom_minimum_size = Vector2(220, 88)
		button.focus_mode = Control.FOCUS_ALL
		button.disabled = not is_unlocked
		button.text = "%s\n%s" % [
			entry.get("display_name", String(stage_id)),
			_status_text(is_unlocked, is_cleared),
		]
		button.pressed.connect(_on_stage_button_pressed.bind(stage_id))
		roster_grid.add_child(button)

		if is_unlocked and first_unlocked_button == null:
			first_unlocked_button = button

		if is_unlocked and stage_group == &"maverick":
			unlocked_mavericks += 1
		elif is_unlocked and stage_group == &"fortress":
			unlocked_fortress += 1

	summary_label.text = "Unlocked: %d/8 Maverick | %d/4 Fortress | Intro clear: %s" % [
		unlocked_mavericks,
		unlocked_fortress,
		"yes" if Progression.intro_cleared else "no",
	]
	footer_label.text = "Select any unlocked stage. Locked stages stay visible but disabled."

	if first_unlocked_button != null:
		first_unlocked_button.grab_focus()


func _status_text(is_unlocked: bool, is_cleared: bool) -> String:
	if not is_unlocked:
		return "LOCKED"
	if is_cleared:
		return "CLEAR"
	return "READY"


func _on_stage_button_pressed(stage_id: StringName) -> void:
	GameFlow.request_stage(stage_id)


func _on_back_button_pressed() -> void:
	GameFlow.request_title()


func _on_debug_button_pressed() -> void:
	GameFlow.request_stage(TEST_STAGE_ID)
