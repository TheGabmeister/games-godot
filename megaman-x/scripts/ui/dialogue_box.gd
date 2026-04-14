extends Control
class_name DialogueBox

@onready var title_label: Label = $Anchor/Panel/Content/TitleLabel
@onready var body_label: Label = $Anchor/Panel/Content/BodyLabel
@onready var footer_label: Label = $Anchor/Panel/Content/FooterLabel


func configure_line(speaker_name: String, body_text: String, line_index: int, line_count: int, allow_skip: bool) -> void:
	title_label.text = speaker_name
	body_label.text = body_text
	footer_label.text = "Line %d / %d    Confirm: advance    Cancel: %s" % [
		line_index + 1,
		line_count,
		"skip" if allow_skip else "locked",
	]


func get_snapshot() -> Dictionary:
	return {
		"title_text": title_label.text,
		"body_text": body_label.text,
		"footer_text": footer_label.text,
	}
