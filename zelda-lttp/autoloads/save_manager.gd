extends Node

# Phase 1: stub autoload. Real implementation in Phase 6.


func save_game(slot: int) -> void:
	print("[SaveManager] save_game(slot=%d) — stub, not saving" % slot)


func load_game(slot: int) -> void:
	print("[SaveManager] load_game(slot=%d) — stub, not loading" % slot)


func has_save(slot: int) -> bool:
	print("[SaveManager] has_save(slot=%d) — stub, returning false" % slot)
	return false


func get_slot_metadata(slot: int) -> Dictionary:
	print("[SaveManager] get_slot_metadata(slot=%d) — stub" % slot)
	return {}


func delete_save(slot: int) -> void:
	print("[SaveManager] delete_save(slot=%d) — stub" % slot)
