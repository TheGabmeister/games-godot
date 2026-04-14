extends Resource
class_name WeaponData

@export var weapon_id: StringName = &"buster"
@export var display_name := "Buster"
@export var energy_cost := 0
@export var max_energy := 0
@export var projectile_scene: PackedScene
@export var base_damage := 1
@export var shot_cooldown := 0.18
@export var active_projectile_limit := 3
@export var projectile_speed := 420.0
@export var projectile_lifetime := 1.2
@export var supports_charge := true
@export var partial_charge_time := 0.35
@export var full_charge_time := 0.8
@export var partial_charge_damage := 2
@export var full_charge_damage := 4
@export var uncharged_scale := Vector2.ONE
@export var partial_charge_scale := Vector2(1.35, 1.35)
@export var full_charge_scale := Vector2(1.9, 1.9)
@export var uncharged_color := Color(0.619608, 0.921569, 1.0, 1.0)
@export var partial_charge_color := Color(0.533333, 0.984314, 0.764706, 1.0)
@export var full_charge_color := Color(1.0, 0.882353, 0.47451, 1.0)
@export var ui_accent_color := Color(0.619608, 0.921569, 1.0, 1.0)
