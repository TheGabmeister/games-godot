extends Control

const BOSS_DISPLAY_NAMES := {
	&"velguarder": "Velguarder",
	&"sigma_first_form": "Sigma First Form",
	&"sigma_wolf_form": "Sigma Wolf Form",
}

@onready var title_label: Label = $Center/Panel/Content/TitleLabel
@onready var body_label: Label = $Center/Panel/Content/BodyLabel
@onready var detail_label: Label = $Center/Panel/Content/DetailLabel


func configure(payload: Dictionary) -> void:
	var display_name := String(payload.get("display_name", "Final Stage"))
	var stage_id := payload.get("stage_id", &"") as StringName
	var ordered_boss_ids: Array[StringName] = []
	for boss_id in payload.get("ordered_boss_ids", []):
		ordered_boss_ids.append(boss_id as StringName)
	title_label.text = "ENDING"
	body_label.text = "%s complete." % display_name

	var detail_lines := [
		"Campaign complete: %s" % ("yes" if bool(payload.get("campaign_complete", false)) else "no"),
		"Final stage ID: %s" % stage_id,
	]
	if not ordered_boss_ids.is_empty():
		detail_lines.append("Final encounter order: %s" % ", ".join(_boss_names_for_ids(ordered_boss_ids)))
	detail_lines.append("Press confirm or cancel to return to the title screen.")
	detail_label.text = "\n".join(detail_lines)


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed(&"menu_confirm") and not event.is_action_pressed(&"menu_cancel"):
		return

	var viewport := get_viewport()
	if viewport != null:
		viewport.set_input_as_handled()

	if GameFlow != null and GameFlow.has_method("exit_ending_to_title"):
		GameFlow.exit_ending_to_title()


func get_snapshot() -> Dictionary:
	return {
		"title_text": title_label.text,
		"body_text": body_label.text,
		"detail_text": detail_label.text,
	}


func _boss_names_for_ids(boss_ids: Array[StringName]) -> PackedStringArray:
	var names := PackedStringArray()
	for boss_id in boss_ids:
		if BOSS_DISPLAY_NAMES.has(boss_id):
			names.append(String(BOSS_DISPLAY_NAMES[boss_id]))
		else:
			names.append(String(boss_id).replace("_", " ").capitalize())

	return names
