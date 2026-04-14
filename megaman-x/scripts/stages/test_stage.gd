extends Node2D

const STAGE_NOTE := "Phase 3 damage slice.\nMove with A/D or Left/Right. Jump with Space. Touch spikes to test retry."

@onready var player: Node = $Player
@onready var follow_camera: Camera2D = $Camera2D
@onready var stage_controller: Node = $StageController
@onready var body_label: Label = $CanvasLayer/Overlay/Body


func _ready() -> void:
	follow_camera.call("set_target", player.call("get_camera_anchor"))
	player.connect("locomotion_state_changed", _on_player_locomotion_state_changed)
	player.connect("facing_changed", _on_player_facing_changed)
	player.call("get_health_component").connect("health_changed", _on_player_health_changed)
	stage_controller.connect("retry_completed", _on_retry_completed)
	_refresh_overlay()


func _on_player_locomotion_state_changed(_previous_state: int, _new_state: int) -> void:
	_refresh_overlay()


func _on_player_facing_changed(_facing_direction: int) -> void:
	_refresh_overlay()


func _on_player_health_changed(_current_health: int, _max_health: int) -> void:
	_refresh_overlay()


func _on_retry_completed(_retry_count: int) -> void:
	_refresh_overlay()


func _refresh_overlay() -> void:
	var health_component: Node = player.call("get_health_component")
	body_label.text = "%s\nState: %s | Facing: %s | HP: %d/%d | Retries: %d" % [
		STAGE_NOTE,
		player.call("get_locomotion_state_name"),
		player.call("get_facing_name"),
		health_component.get("current_health"),
		health_component.get("max_health"),
		stage_controller.get("retry_count"),
	]
