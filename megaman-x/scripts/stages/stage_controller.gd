extends Node
class_name StageController

signal retry_started(retry_count: int)
signal retry_completed(retry_count: int)
signal checkpoint_activated(checkpoint_id: StringName, respawn_position: Vector2)

@export var player_path: NodePath
@export var spawn_point_path: NodePath
@export var reset_group: StringName = &"stage_resettable"

var retry_count := 0
var active_checkpoint_id: StringName = &""
var _current_respawn_position := Vector2.ZERO

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


func retry_stage() -> void:
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
	retry_stage()
