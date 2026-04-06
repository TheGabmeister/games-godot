class_name LootTable extends Resource

@export var item_ids: PackedStringArray = PackedStringArray()
@export var weights: PackedFloat32Array = PackedFloat32Array()
@export var nothing_weight: float = 0.5


func roll() -> ItemData:
	if item_ids.is_empty():
		return null
	var total_weight := nothing_weight
	for w in weights:
		total_weight += w
	var r := randf() * total_weight

	if r < nothing_weight:
		return null

	var cumulative := nothing_weight
	for i in item_ids.size():
		var w: float = weights[i] if i < weights.size() else 1.0
		cumulative += w
		if r < cumulative:
			return ItemRegistry.get_item(StringName(item_ids[i]))
	return null
