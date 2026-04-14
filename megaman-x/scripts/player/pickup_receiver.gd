extends Node
class_name PickupReceiver

@onready var player: Node = get_parent()


func apply_pickup(pickup: Node) -> bool:
	if pickup == null:
		return false

	if pickup.has_method("collect"):
		return bool(pickup.call("collect", self))

	pickup.queue_free()
	return true


func restore_health(amount: int) -> bool:
	if player == null or not player.has_method("get_health_component"):
		return false

	var health_component: Node = player.get_health_component()
	if health_component == null or not health_component.has_method("heal"):
		return false

	return int(health_component.heal(amount)) > 0


func collect_heart_tank(pickup_id: StringName, _health_bonus := 0) -> bool:
	var progression := _get_progression()
	if progression == null or not progression.has_method("collect_heart_tank"):
		return false

	var changed := bool(progression.collect_heart_tank(pickup_id))
	if changed:
		if player != null and player.has_method("apply_progression_upgrades"):
			player.apply_progression_upgrades(false)
		_save_persistent_pickup()

	return changed


func collect_armor_part(part_id: StringName, pickup_id: StringName) -> bool:
	var progression := _get_progression()
	if progression == null or not progression.has_method("unlock_armor_part"):
		return false

	var changed := bool(progression.unlock_armor_part(part_id, pickup_id))
	if changed:
		if player != null and player.has_method("apply_progression_upgrades"):
			player.apply_progression_upgrades(false)
		_save_persistent_pickup()

	return changed


func collect_sub_tank(sub_tank_id: StringName, pickup_id: StringName, initial_fill := 0) -> bool:
	var progression := _get_progression()
	if progression == null or not progression.has_method("acquire_sub_tank"):
		return false

	var changed := bool(progression.acquire_sub_tank(sub_tank_id, pickup_id, initial_fill))
	if changed:
		_save_persistent_pickup()

	return changed


func restore_weapon_energy(weapon_id: StringName, amount: int) -> bool:
	if amount <= 0 or player == null or not player.has_method("get_player_combat"):
		return false

	var combat: Node = player.get_player_combat()
	if combat == null or not combat.has_method("restore_weapon_energy"):
		return false

	return int(combat.restore_weapon_energy(weapon_id, amount)) > 0


func use_sub_tank() -> bool:
	if player == null or not player.has_method("get_health_component"):
		return false

	var health_component: Node = player.get_health_component()
	if health_component == null:
		return false

	var current_health := int(health_component.get("current_health"))
	var max_health := int(health_component.get("max_health"))
	var missing_health := max_health - current_health
	if missing_health <= 0:
		return false

	var progression := _get_progression()
	if progression == null or not progression.has_method("use_sub_tank_heal"):
		return false

	var result := progression.use_sub_tank_heal(missing_health) as Dictionary
	var heal_amount := int(result.get("heal_amount", 0))
	if heal_amount <= 0:
		return false

	return int(health_component.heal(heal_amount)) > 0


func _get_progression() -> Node:
	return get_node_or_null("/root/Progression")


func _save_persistent_pickup() -> void:
	var save_manager := get_node_or_null("/root/SaveManager")
	if save_manager != null and save_manager.has_method("save_game"):
		save_manager.save_game(&"persistent_pickup")
