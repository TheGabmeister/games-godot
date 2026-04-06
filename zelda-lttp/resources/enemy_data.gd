class_name EnemyData extends Resource

@export var id: StringName
@export var display_name: String
@export var max_health: int
@export var contact_damage: int
@export var knockback_resistance: float  # 0.0 = full knockback, 1.0 = immune
@export var drop_table: LootTable
@export var color: Color
@export var damage_immunities: Array[int]  # DamageType enum values
