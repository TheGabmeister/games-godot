class_name LootTable extends Resource

@export var items: Array[ItemData] = []
@export var weights: Array[float] = []
@export var nothing_weight: float = 0.5


func roll() -> ItemData:
	if items.is_empty():
		return null
	var total_weight := nothing_weight
	for w in weights:
		total_weight += w
	var r := randf() * total_weight
	var cumulative := nothing_weight
	for i in items.size():
		var w: float = weights[i] if i < weights.size() else 1.0
		cumulative += w
		if r <= cumulative:
			return items[i]
	return null
