class_name LootDropComponent extends Node

const PICKUP_SCENE := preload("res://scenes/pickups/pickup.tscn")


func drop(pos: Vector2) -> void:
	var parent := get_parent()
	var table: LootTable = null
	if parent and "enemy_data" in parent and parent.enemy_data:
		table = parent.enemy_data.drop_table
	if not table:
		return
	var item: ItemData = table.roll()
	if item:
		_spawn_pickup(pos, item)


func _spawn_pickup(pos: Vector2, item: ItemData) -> void:
	var pickup: Pickup = PICKUP_SCENE.instantiate()
	pickup.item = item
	pickup.global_position = pos
	# Add to the same parent as the enemy (Entities node)
	var spawn_parent := get_parent().get_parent()
	if spawn_parent:
		spawn_parent.add_child(pickup)
