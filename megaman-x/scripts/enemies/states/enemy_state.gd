extends Node
class_name EnemyState


func get_state_name() -> StringName:
	return &"state"


func enter(_brain: Node) -> void:
	pass


func exit(_brain: Node) -> void:
	pass


func physics_update(_brain: Node, _delta: float) -> void:
	pass
