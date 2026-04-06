class_name HitboxComponent extends Area2D

@export var damage: int = 2
@export var damage_type: DamageType.Type = DamageType.Type.CONTACT
@export var knockback_force: float = 120.0
@export var effect: DamageType.HitEffect = DamageType.HitEffect.NONE
@export var source_team: StringName = &"enemy"

## Data dictionary passed to HurtboxComponent on contact.
func get_hitbox_data() -> Dictionary:
	return {
		"damage": damage,
		"damage_type": damage_type,
		"knockback_force": knockback_force,
		"effect": effect,
		"source_team": source_team,
		"source_position": global_position,
	}
