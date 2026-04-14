extends EnemyState


func get_state_name() -> StringName:
	return &"DEAD"


func enter(brain: Node) -> void:
	var enemy: Node = brain.call("get_enemy") as Node
	if enemy != null:
		enemy.call("set_horizontal_intent", 0.0)
