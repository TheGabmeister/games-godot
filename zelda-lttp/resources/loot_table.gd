class_name LootTable extends Resource

@export var item_ids: PackedStringArray = PackedStringArray()
@export var weights: PackedFloat32Array = PackedFloat32Array()
@export var quantity_min: PackedInt32Array = PackedInt32Array()
@export var quantity_max: PackedInt32Array = PackedInt32Array()
@export var nothing_weight: float = 0.5


## Returns zero or more pickup payloads based on weighted random selection.
func roll() -> Array[ItemData]:
	if item_ids.is_empty():
		return []

	var total_weight := nothing_weight
	for i in item_ids.size():
		var w: float = weights[i] if i < weights.size() else 1.0
		total_weight += w

	var r := randf() * total_weight

	if r < nothing_weight:
		return []

	var cumulative := nothing_weight
	for i in item_ids.size():
		var w: float = weights[i] if i < weights.size() else 1.0
		cumulative += w
		if r < cumulative:
			var item: ItemData = ItemRegistry.get_item(StringName(item_ids[i]))
			if not item:
				return []
			var q_min: int = quantity_min[i] if i < quantity_min.size() else 1
			var q_max: int = quantity_max[i] if i < quantity_max.size() else 1
			var qty: int = randi_range(q_min, q_max)
			var result: Array[ItemData] = []
			for _j in qty:
				result.append(item)
			return result
	return []
