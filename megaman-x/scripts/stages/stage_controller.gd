extends Node
class_name StageController

signal retry_started(retry_count: int)
signal retry_completed(retry_count: int)
signal checkpoint_activated(checkpoint_id: StringName, respawn_position: Vector2)
signal stage_clear_started(stage_id: StringName, clear_count: int)

@export var player_path: NodePath
@export var spawn_point_path: NodePath
@export var reset_group: StringName = &"stage_resettable"
@export var stage_id: StringName = &"test_stage"
@export var clear_cleanup_group: StringName = &"stage_clear_cleanup"

var retry_count := 0
var active_checkpoint_id: StringName = &""
var _current_respawn_position := Vector2.ZERO
var stage_clear_count := 0
var _is_stage_clear_active := false

@onready var player: Node2D = get_node_or_null(player_path) as Node2D
@onready var spawn_point: Node2D = get_node_or_null(spawn_point_path) as Node2D


func _ready() -> void:
	_current_respawn_position = spawn_point.global_position if spawn_point != null else Vector2.ZERO
	if player != null and player.has_signal("death_sequence_finished"):
		player.death_sequence_finished.connect(_on_player_death_sequence_finished)


func activate_checkpoint(checkpoint_id: StringName, respawn_position: Vector2) -> void:
	if checkpoint_id.is_empty():
		return

	active_checkpoint_id = checkpoint_id
	_current_respawn_position = respawn_position
	checkpoint_activated.emit(active_checkpoint_id, _current_respawn_position)


func clear_active_checkpoint() -> void:
	active_checkpoint_id = &""
	_current_respawn_position = spawn_point.global_position if spawn_point != null else Vector2.ZERO


func get_active_checkpoint_id() -> StringName:
	return active_checkpoint_id


func get_current_respawn_position() -> Vector2:
	return _current_respawn_position


func is_stage_clear_active() -> bool:
	return _is_stage_clear_active


func begin_stage_clear(source_id: StringName = &"goal") -> void:
	if _is_stage_clear_active:
		return

	_is_stage_clear_active = true
	stage_clear_count += 1
	_cleanup_for_stage_clear()
	if player != null and player.has_method("set_gameplay_enabled"):
		player.set_gameplay_enabled(false, &"stage_clear")

	stage_clear_started.emit(stage_id if not stage_id.is_empty() else &"stage", stage_clear_count)
	if Engine.has_singleton("GameFlow") or get_node_or_null("/root/GameFlow") != null:
		var game_flow := get_node_or_null("/root/GameFlow")
		if game_flow != null and game_flow.has_method("request_stage_clear"):
			game_flow.request_stage_clear(stage_id if not stage_id.is_empty() else &"stage", {
				"source_id": source_id,
				"clear_count": stage_clear_count,
			})


func retry_stage() -> void:
	if _is_stage_clear_active:
		return

	retry_count += 1
	retry_started.emit(retry_count)

	for node in get_tree().get_nodes_in_group(reset_group):
		if node.has_method("reset_for_stage_retry"):
			node.reset_for_stage_retry()

	if player != null and player.has_method("reset_to_spawn"):
		player.reset_to_spawn(_current_respawn_position)

	retry_completed.emit(retry_count)


func retry_stage_from_start() -> void:
	clear_active_checkpoint()
	retry_stage()


func _on_player_death_sequence_finished() -> void:
	if _is_stage_clear_active:
		return

	retry_stage()


func _cleanup_for_stage_clear() -> void:
	for node in get_tree().get_nodes_in_group(clear_cleanup_group):
		if node != null and is_instance_valid(node):
			node.queue_free()
