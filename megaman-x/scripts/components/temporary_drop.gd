extends Area2D
class_name TemporaryDrop

@export var bob_height := 4.0
@export var bob_speed := 2.8
@export var health_restore := 2

var _base_position := Vector2.ZERO
var _bob_time := 0.0


func _ready() -> void:
	add_to_group(&"stage_resettable")
	add_to_group(&"stage_clear_cleanup")
	add_to_group(&"player_pickup")
	_base_position = global_position


func _process(delta: float) -> void:
	_bob_time += delta
	global_position = _base_position + Vector2(0.0, sin(_bob_time * bob_speed) * bob_height)


func reset_for_stage_retry() -> void:
	queue_free()


func collect(pickup_receiver: Node) -> bool:
	if pickup_receiver == null:
		return false

	var accepted := false
	if pickup_receiver.has_method("restore_health"):
		accepted = bool(pickup_receiver.call("restore_health", health_restore))
	else:
		accepted = true

	if accepted:
		queue_free()

	return accepted
