extends Node

var _items: Dictionary = {}

func _ready() -> void:
	add_to_group(Groups.INVENTORY)
	var tonic := preload("res://items/tonic.tres")
	add_item(tonic, 5)

func add_item(item: ItemData, count: int = 1) -> void:
	if _items.has(item):
		_items[item] += count
	else:
		_items[item] = count

func remove_item(item: ItemData, count: int = 1) -> void:
	if not _items.has(item):
		return
	_items[item] -= count
	if _items[item] <= 0:
		_items.erase(item)

func get_count(item: ItemData) -> int:
	return _items.get(item, 0)

func has_item(item: ItemData) -> bool:
	return _items.has(item) and _items[item] > 0

func get_all_items() -> Array:
	var result: Array = []
	for item in _items:
		result.append({ "item": item, "count": _items[item] })
	return result
