extends Node
class_name DropSpawner

var _active_drops: Array[Node] = []


func spawn_drop(drop_scene: PackedScene, spawn_position: Vector2) -> Node2D:
	if drop_scene == null:
		return null

	var drop := drop_scene.instantiate() as Node2D
	if drop == null:
		return null

	var parent_node := get_parent()
	if parent_node != null and parent_node.get_parent() != null:
		parent_node = parent_node.get_parent()

	_active_drops.append(drop)
	drop.tree_exited.connect(_on_drop_tree_exited.bind(drop), CONNECT_ONE_SHOT)
	call_deferred("_attach_drop_deferred", parent_node, drop, spawn_position)
	return drop


func get_active_drop_count() -> int:
	_prune_drops()
	return _active_drops.size()


func reset_for_stage_retry() -> void:
	_prune_drops()
	for drop in _active_drops:
		if is_instance_valid(drop):
			drop.queue_free()

	_active_drops.clear()


func _prune_drops() -> void:
	var valid_drops: Array[Node] = []
	for drop in _active_drops:
		if is_instance_valid(drop):
			valid_drops.append(drop)

	_active_drops = valid_drops


func _on_drop_tree_exited(drop: Node) -> void:
	_active_drops.erase(drop)


func _attach_drop_deferred(parent_node: Node, drop: Node2D, spawn_position: Vector2) -> void:
	if not is_instance_valid(drop) or not is_instance_valid(parent_node):
		_active_drops.erase(drop)
		return

	parent_node.add_child(drop)
	drop.global_position = spawn_position
