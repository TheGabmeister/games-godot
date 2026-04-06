extends BaseItemEffect

const LOCK_DURATION := 0.3


func can_use(_player: CharacterBody2D) -> bool:
	var cost: int = 8
	if PlayerState.has_upgrade(&"magic_halver"):
		cost = ceili(cost / 2.0)
	return PlayerState.current_magic >= cost


func activate(player: CharacterBody2D) -> float:
	var proj: Projectile = preload("res://scenes/projectiles/projectile_base.tscn").instantiate()
	proj.speed = 100.0
	proj.damage = 4
	proj.damage_type = DamageType.Type.FIRE
	proj.source_team = &"player"
	proj.projectile_color = Color(1.0, 0.4, 0.1)
	proj.projectile_radius = 4.0
	proj.direction = player.facing_direction.normalized()
	proj.global_position = player.global_position + player.facing_direction * 8.0
	player.get_parent().add_child(proj)
	return LOCK_DURATION
