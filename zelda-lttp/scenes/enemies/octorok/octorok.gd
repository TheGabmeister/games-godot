extends BaseEnemy

@export var fire_cadence: float = 2.0
@export var wander_speed: float = 25.0

const PROJECTILE_SCENE := preload("res://scenes/projectiles/projectile_base.tscn")


func spawn_projectile() -> void:
	var proj: Projectile = PROJECTILE_SCENE.instantiate()
	proj.direction = facing_direction
	proj.speed = 70.0
	proj.damage = 2
	proj.damage_type = DamageType.Type.CONTACT
	proj.source_team = &"enemy"
	proj.projectile_color = Color(0.4, 0.3, 0.2)
	proj.projectile_radius = 2.5
	proj.global_position = global_position + facing_direction * 8.0
	get_parent().add_child(proj)
