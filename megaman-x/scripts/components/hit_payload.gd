extends RefCounted
class_name HitPayload

static func create(
	source_node: Variant,
	attacker_team: StringName,
	attacker_weapon_id: StringName,
	damage_amount: int,
	knockback_force: Vector2
) -> Dictionary:
	return {
		"source": source_node,
		"team": attacker_team,
		"weapon_id": attacker_weapon_id,
		"damage": damage_amount,
		"knockback": knockback_force,
	}
