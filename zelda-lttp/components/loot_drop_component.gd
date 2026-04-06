class_name LootDropComponent extends Node


func drop(pos: Vector2) -> void:
	var parent := get_parent()
	var table: LootTable = null
	if parent and "enemy_data" in parent and parent.enemy_data:
		table = parent.enemy_data.drop_table
	if not table:
		return
	var item: ItemData = table.roll()
	if item:
		# TODO: Phase 2.7 — spawn actual pickup scene
		print("[LootDrop] Would drop: %s at %s" % [item.display_name, pos])
