extends Node
class_name StageController

signal retry_started(retry_count: int)
signal retry_completed(retry_count: int)

@export var player_path: NodePath
@export var spawn_point_path: NodePath
@export var reset_group: StringName = &"stage_resettable"

var retry_count := 0

@onready var player: Node2D = get_node_or_null(player_path) as Node2D
@onready var spawn_point: Node2D = get_node_or_null(spawn_point_path) as Node2D


func _ready() -> void:
	if player != null and player.has_signal("death_sequence_finished"):
		player.death_sequence_finished.connect(_on_player_death_sequence_finished)


func retry_stage_from_start() -> void:
	retry_count += 1
	retry_started.emit(retry_count)

	for node in get_tree().get_nodes_in_group(reset_group):
		if node.has_method("reset_for_stage_retry"):
			node.reset_for_stage_retry()

	if player != null and spawn_point != null and player.has_method("reset_to_spawn"):
		player.reset_to_spawn(spawn_point.global_position)

	retry_completed.emit(retry_count)


func _on_player_death_sequence_finished() -> void:
	retry_stage_from_start()
