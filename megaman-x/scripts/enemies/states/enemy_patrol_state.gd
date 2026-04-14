extends EnemyState


func get_state_name() -> StringName:
	return &"PATROL"


func physics_update(brain: Node, _delta: float) -> void:
	var enemy: Node = brain.call("get_enemy") as Node
	if enemy == null:
		return

	if bool(enemy.call("should_turn_at_patrol_edge")):
		enemy.call("reverse_patrol_direction")

	enemy.call("set_horizontal_intent", float(enemy.call("get_patrol_direction")))
