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


func restore_weapon_energy(weapon_id: StringName, amount: int) -> bool:
	if amount <= 0 or player == null or not player.has_method("get_player_combat"):
		return false

	var combat: Node = player.get_player_combat()
	if combat == null or not combat.has_method("restore_weapon_energy"):
		return false

	return int(combat.restore_weapon_energy(weapon_id, amount)) > 0
