extends Area2D
class_name Hurtbox

signal hit_accepted(payload: Dictionary)

@export var health_component_path: NodePath

@onready var health_component: Node = get_node_or_null(health_component_path)


func apply_hit_payload(payload: Dictionary) -> bool:
	if health_component == null:
		return false

	var accepted: bool = health_component.call("apply_hit_payload", payload)
	if accepted:
		hit_accepted.emit(payload)

	return accepted
