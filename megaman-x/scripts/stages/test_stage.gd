extends Node2D

const STAGE_NOTE := "Phase 5 enemy slice.\nMove with A/D. Shoot with J. Approach the walker to wake it, defeat it, then retry to verify reset."

@onready var player: Node = $Player
@onready var player_combat: Node = $Player/PlayerCombat
@onready var walker_enemy: Node = $WalkerBasic
@onready var follow_camera: Camera2D = $Camera2D
@onready var stage_controller: Node = $StageController
@onready var body_label: Label = $CanvasLayer/Overlay/Body


func _ready() -> void:
	follow_camera.call("set_target", player.call("get_camera_anchor"))
	player.connect("locomotion_state_changed", _on_player_locomotion_state_changed)
	player.connect("facing_changed", _on_player_facing_changed)
	player.call("get_health_component").connect("health_changed", _on_player_health_changed)
	player_combat.connect("combat_state_changed", _on_player_combat_state_changed)
	player_combat.connect("charge_feedback_changed", _on_player_charge_feedback_changed)
	player_combat.connect("projectile_spawned", _on_player_projectile_spawned)
	walker_enemy.connect("activation_changed", _on_walker_enemy_changed)
	walker_enemy.connect("enemy_defeated", _on_walker_enemy_changed)
	walker_enemy.connect("drop_spawned", _on_walker_enemy_changed)
	walker_enemy.get_node("HealthComponent").connect("health_changed", _on_walker_enemy_health_changed)
	stage_controller.connect("retry_completed", _on_retry_completed)
	_refresh_overlay()


func get_primary_player() -> Node:
	return player


func _on_player_locomotion_state_changed(_previous_state: int, _new_state: int) -> void:
	_refresh_overlay()


func _on_player_facing_changed(_facing_direction: int) -> void:
	_refresh_overlay()


func _on_player_health_changed(_current_health: int, _max_health: int) -> void:
	_refresh_overlay()


func _on_retry_completed(_retry_count: int) -> void:
	_refresh_overlay()


func _on_player_combat_state_changed(_previous_state: int, _new_state: int) -> void:
	_refresh_overlay()


func _on_player_charge_feedback_changed(_previous_feedback: int, _new_feedback: int) -> void:
	_refresh_overlay()


func _on_player_projectile_spawned(_projectile: Node, _spawn_position: Vector2, _tier: StringName) -> void:
	_refresh_overlay()


func _on_walker_enemy_changed(_value = null) -> void:
	_refresh_overlay()


func _on_walker_enemy_health_changed(_current_health: int, _max_health: int) -> void:
	_refresh_overlay()


func _refresh_overlay() -> void:
	var health_component: Node = player.call("get_health_component")
	body_label.text = "%s\nMove: %s | Facing: %s | Combat: %s | Charge: %s\nHP: %d/%d | Shots: %d | Retries: %d\nEnemy: %s" % [
		STAGE_NOTE,
		player.call("get_locomotion_state_name"),
		player.call("get_facing_name"),
		player_combat.call("get_combat_state_name"),
		player_combat.call("get_charge_feedback_name"),
		health_component.get("current_health"),
		health_component.get("max_health"),
		player_combat.call("get_active_projectile_count"),
		stage_controller.get("retry_count"),
		walker_enemy.call("get_debug_summary"),
	]
