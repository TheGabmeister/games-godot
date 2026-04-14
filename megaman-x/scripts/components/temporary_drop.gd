extends Area2D
class_name TemporaryDrop

@export var bob_height := 4.0
@export var bob_speed := 2.8

var _base_position := Vector2.ZERO
var _bob_time := 0.0


func _ready() -> void:
	add_to_group(&"stage_resettable")
	add_to_group(&"stage_clear_cleanup")
	_base_position = global_position


func _process(delta: float) -> void:
	_bob_time += delta
	global_position = _base_position + Vector2(0.0, sin(_bob_time * bob_speed) * bob_height)


func reset_for_stage_retry() -> void:
	queue_free()
