extends Resource
class_name EnemyData

@export var enemy_id: StringName = &"walker_basic"
@export var max_health := 2
@export var contact_damage := 2
@export var contact_weapon_id: StringName = &"enemy_contact"
@export var contact_knockback := Vector2(120.0, -110.0)
@export var activation_range := 128.0
@export var patrol_speed := 48.0
@export var patrol_distance := 56.0
@export var drop_scene: PackedScene
