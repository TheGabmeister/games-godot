class_name LootDropComponent extends Node

const PICKUP_SCENE := preload("res://scenes/pickups/pickup.tscn")

## Set directly for non-enemy objects (pots, bushes, destructibles).
## Falls back to parent.enemy_data.drop_table if null.
@export var drop_table: LootTable


func drop(pos: Vector2) -> void:
	var table: LootTable = drop_table
	if not table:
		var parent := get_parent()
		if parent and "enemy_data" in parent and parent.enemy_data:
			table = parent.enemy_data.drop_table
	if not table:
		return
	var items: Array[ItemData] = table.roll()
	for item in items:
		_spawn_pickup(pos, item)


func _spawn_pickup(pos: Vector2, item: ItemData) -> void:
	var pickup: Pickup = PICKUP_SCENE.instantiate()
	pickup.item = item
	pickup.global_position = pos
	var spawn_parent := get_parent().get_parent()
	if spawn_parent:
		spawn_parent.add_child(pickup)
