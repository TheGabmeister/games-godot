extends Node

var _items: Dictionary = {}  # StringName -> ItemData


func _ready() -> void:
	_scan_items("res://resources/items/")


func _scan_items(path: String) -> void:
	var dir := DirAccess.open(path)
	if not dir:
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		var full_path := path + file_name
		if dir.current_is_dir():
			_scan_items(full_path + "/")
		elif file_name.ends_with(".tres") or file_name.ends_with(".res"):
			var res := load(full_path)
			if res is ItemData:
				var item: ItemData = res
				if item.id == &"":
					push_warning("[ItemRegistry] Skipping item with empty id at: %s" % full_path)
				elif _items.has(item.id):
					push_error("[ItemRegistry] Duplicate item id '%s' at: %s (keeping first)" % [item.id, full_path])
				else:
					_items[item.id] = item
			else:
				push_warning("[ItemRegistry] File is not ItemData: %s" % full_path)
		file_name = dir.get_next()
	dir.list_dir_end()


func get_item(id: StringName) -> ItemData:
	return _items.get(id, null)


func has(id: StringName) -> bool:
	return _items.has(id)


func all_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for key in _items.keys():
		ids.append(key)
	return ids


func all_items() -> Array[ItemData]:
	var items: Array[ItemData] = []
	for item in _items.values():
		items.append(item)
	return items
