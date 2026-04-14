extends Control
class_name StageClearOverlay

@onready var title_label: Label = $Center/Panel/Content/TitleLabel
@onready var body_label: Label = $Center/Panel/Content/BodyLabel
@onready var detail_label: Label = $Center/Panel/Content/DetailLabel


func configure(payload: Dictionary) -> void:
	var display_name := String(payload.get("display_name", "Stage"))
	var clear_count := int(payload.get("clear_count", 1))
	var reward_weapon_name := String(payload.get("reward_weapon_name", ""))
	title_label.text = "STAGE CLEAR"
	body_label.text = "%s complete." % display_name
	var detail_lines := [
		"Clear flow locked gameplay and replaced the HUD overlay.",
		"StageController transitions: %d" % clear_count,
	]
	if not reward_weapon_name.is_empty():
		detail_lines.append("Weapon unlocked: %s" % reward_weapon_name)
	detail_lines.append("Press confirm or cancel to return to the frontend.")
	detail_label.text = "\n".join(detail_lines)


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed(&"menu_confirm") and not event.is_action_pressed(&"menu_cancel"):
		return

	var viewport := get_viewport()
	if viewport != null:
		viewport.set_input_as_handled()

	if GameFlow != null and GameFlow.has_method("exit_stage_clear_to_frontend"):
		GameFlow.exit_stage_clear_to_frontend()


func get_snapshot() -> Dictionary:
	return {
		"title_text": title_label.text,
		"body_text": body_label.text,
		"detail_text": detail_label.text,
	}
