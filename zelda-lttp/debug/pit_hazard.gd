extends Area2D

# Simple pit hazard. Sets metadata so HurtboxComponent's fallback path detects it.

func _ready() -> void:
	set_meta("damage", 2)
	set_meta("damage_type", DamageType.Type.PIT)
	set_meta("knockback_force", 0.0)
