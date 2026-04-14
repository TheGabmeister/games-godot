extends Node2D

var _stage_definition: StageDefinition = null

@onready var player: Node = $Player
@onready var follow_camera: Camera2D = $Camera2D
@onready var stage_controller: StageController = $StageController
@onready var stage_label: Label = $CanvasLayer/Panel/VBoxContainer/StageLabel
@onready var body_label: Label = $CanvasLayer/Panel/VBoxContainer/BodyLabel


func _ready() -> void:
	if player != null and player.has_method("set_dash_unlocked"):
		player.set_dash_unlocked(bool(Progression.dash_unlocked))
	if follow_camera != null and player != null and player.has_method("get_camera_anchor"):
		follow_camera.set_target(player.get_camera_anchor())
	_refresh_ui()


func configure_stage_definition(stage_definition: StageDefinition) -> void:
	_stage_definition = stage_definition
	if stage_controller != null:
		stage_controller.stage_id = stage_definition.stage_id
	if is_inside_tree():
		_refresh_ui()


func get_primary_player() -> Node:
	return player


func _refresh_ui() -> void:
	var stage_id := stage_controller.stage_id
	var display_name := String(stage_id)
	var group_name := "Campaign"
	if _stage_definition != null:
		stage_id = _stage_definition.stage_id
		display_name = _stage_definition.display_name
		group_name = String(_stage_definition.stage_group).capitalize()

	stage_label.text = display_name
	body_label.text = "%s placeholder slice.\nStage ID: %s\nDash unlocked: %s\nTouch the clear gate to complete this stage." % [
		group_name,
		stage_id,
		"yes" if Progression.dash_unlocked else "no",
	]
