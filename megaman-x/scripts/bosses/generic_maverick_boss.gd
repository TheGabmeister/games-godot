extends MaverickBoss
class_name GenericMaverickBoss

const PROFILE_TEXTURES := {
	&"spark_mandrill": preload("res://assets/placeholders/bosses/spark_mandrill_96x96.svg"),
	&"armored_armadillo": preload("res://assets/placeholders/bosses/armored_armadillo_96x96.svg"),
	&"launch_octopus": preload("res://assets/placeholders/bosses/launch_octopus_96x96.svg"),
	&"boomer_kuwanger": preload("res://assets/placeholders/bosses/boomer_kuwanger_96x96.svg"),
	&"sting_chameleon": preload("res://assets/placeholders/bosses/sting_chameleon_96x96.svg"),
}

const PROFILE_ATTACK_COLORS := {
	&"spark_mandrill": Color(1, 0.9, 0.34, 0.86),
	&"armored_armadillo": Color(0.92, 0.74, 0.44, 0.84),
	&"launch_octopus": Color(0.5, 0.96, 1, 0.86),
	&"boomer_kuwanger": Color(0.77, 1, 0.48, 0.86),
	&"sting_chameleon": Color(0.9, 0.64, 1, 0.86),
}

const PROFILE_DATA := {
	&"spark_mandrill": {
		"projectile_scene": "res://scenes/projectiles/EnemyWindShot.tscn",
		"phase_one_speed": 76.0,
		"phase_two_speed": 112.0,
		"phase_one_attack_interval": 1.1,
		"phase_two_attack_interval": 0.72,
		"phase_two_burst_count": 3,
		"phase_two_burst_spacing": 0.11,
		"patrol_distance": 146.0,
		"projectile_damage": 2,
		"projectile_speed": 360.0,
		"projectile_lifetime": 1.0,
		"projectile_knockback": Vector2(185, -44),
		"projectile_weapon_id": &"spark_mandrill_orb",
		"projectile_attack_id": &"electric_spark",
		"projectile_color": Color(1, 0.9, 0.34, 1),
		"contact_damage": 4,
		"contact_knockback": Vector2(220, -96),
		"contact_weapon_id": &"spark_mandrill_body",
		"phase_two_tint": Color(1, 0.95, 0.58, 1),
		"defeated_tint": Color(0.58, 0.54, 0.46, 1),
		"max_health": 12,
	},
	&"armored_armadillo": {
		"projectile_scene": "res://scenes/projectiles/EnemyFireShot.tscn",
		"phase_one_speed": 54.0,
		"phase_two_speed": 82.0,
		"phase_one_attack_interval": 1.2,
		"phase_two_attack_interval": 0.82,
		"phase_two_burst_count": 2,
		"phase_two_burst_spacing": 0.18,
		"patrol_distance": 132.0,
		"projectile_damage": 3,
		"projectile_speed": 310.0,
		"projectile_lifetime": 1.15,
		"projectile_knockback": Vector2(165, -28),
		"projectile_weapon_id": &"armored_armadillo_shell",
		"projectile_attack_id": &"rolling_shield",
		"projectile_color": Color(0.92, 0.74, 0.44, 1),
		"projectile_visual_scale": Vector2(1.15, 1.15),
		"contact_damage": 5,
		"contact_knockback": Vector2(235, -90),
		"contact_weapon_id": &"armored_armadillo_body",
		"phase_two_tint": Color(0.96, 0.85, 0.66, 1),
		"defeated_tint": Color(0.52, 0.46, 0.38, 1),
		"max_health": 14,
	},
	&"launch_octopus": {
		"projectile_scene": "res://scenes/projectiles/EnemyWindShot.tscn",
		"phase_one_speed": 62.0,
		"phase_two_speed": 90.0,
		"phase_one_attack_interval": 1.05,
		"phase_two_attack_interval": 0.74,
		"phase_two_burst_count": 3,
		"phase_two_burst_spacing": 0.14,
		"patrol_distance": 152.0,
		"projectile_damage": 2,
		"projectile_speed": 335.0,
		"projectile_lifetime": 1.25,
		"projectile_knockback": Vector2(175, -36),
		"projectile_weapon_id": &"launch_octopus_torpedo",
		"projectile_attack_id": &"homing_torpedo",
		"projectile_color": Color(0.5, 0.96, 1, 1),
		"contact_damage": 4,
		"contact_knockback": Vector2(210, -84),
		"contact_weapon_id": &"launch_octopus_body",
		"phase_two_tint": Color(0.66, 0.96, 1, 1),
		"defeated_tint": Color(0.42, 0.56, 0.62, 1),
		"max_health": 12,
	},
	&"boomer_kuwanger": {
		"projectile_scene": "res://scenes/projectiles/EnemyWindShot.tscn",
		"phase_one_speed": 84.0,
		"phase_two_speed": 124.0,
		"phase_one_attack_interval": 0.95,
		"phase_two_attack_interval": 0.62,
		"phase_two_burst_count": 3,
		"phase_two_burst_spacing": 0.1,
		"patrol_distance": 168.0,
		"projectile_damage": 2,
		"projectile_speed": 400.0,
		"projectile_lifetime": 0.95,
		"projectile_knockback": Vector2(195, -48),
		"projectile_weapon_id": &"boomer_kuwanger_blade",
		"projectile_attack_id": &"boomerang_cutter",
		"projectile_color": Color(0.77, 1, 0.48, 1),
		"contact_damage": 4,
		"contact_knockback": Vector2(240, -96),
		"contact_weapon_id": &"boomer_kuwanger_body",
		"phase_two_tint": Color(0.86, 1, 0.62, 1),
		"defeated_tint": Color(0.44, 0.54, 0.42, 1),
		"max_health": 11,
	},
	&"sting_chameleon": {
		"projectile_scene": "res://scenes/projectiles/EnemyIceShot.tscn",
		"phase_one_speed": 68.0,
		"phase_two_speed": 98.0,
		"phase_one_attack_interval": 1.0,
		"phase_two_attack_interval": 0.68,
		"phase_two_burst_count": 2,
		"phase_two_burst_spacing": 0.12,
		"patrol_distance": 148.0,
		"projectile_damage": 2,
		"projectile_speed": 350.0,
		"projectile_lifetime": 1.0,
		"projectile_knockback": Vector2(180, -42),
		"projectile_weapon_id": &"sting_chameleon_sting",
		"projectile_attack_id": &"chameleon_sting",
		"projectile_color": Color(0.9, 0.64, 1, 1),
		"contact_damage": 4,
		"contact_knockback": Vector2(220, -92),
		"contact_weapon_id": &"sting_chameleon_body",
		"phase_two_tint": Color(0.95, 0.78, 1, 1),
		"defeated_tint": Color(0.46, 0.4, 0.5, 1),
		"max_health": 12,
	},
}

@export var default_boss_id: StringName = &"spark_mandrill"

@onready var body_sprite: Sprite2D = $VisualRoot/BodySprite
@onready var attack_marker: Sprite2D = $VisualRoot/AttackMarker

var _configured_boss_id: StringName = &""


func _ready() -> void:
	configure_boss_profile(default_boss_id)
	super._ready()


func configure_boss_profile(boss_id: StringName) -> void:
	var resolved_boss_id := boss_id if PROFILE_DATA.has(boss_id) else default_boss_id
	if resolved_boss_id.is_empty():
		return

	_configured_boss_id = resolved_boss_id
	var profile := PROFILE_DATA[resolved_boss_id] as Dictionary
	projectile_scene = load(String(profile.get("projectile_scene", ""))) as PackedScene
	phase_one_speed = float(profile.get("phase_one_speed", phase_one_speed))
	phase_two_speed = float(profile.get("phase_two_speed", phase_two_speed))
	phase_one_attack_interval = float(profile.get("phase_one_attack_interval", phase_one_attack_interval))
	phase_two_attack_interval = float(profile.get("phase_two_attack_interval", phase_two_attack_interval))
	phase_two_burst_count = int(profile.get("phase_two_burst_count", phase_two_burst_count))
	phase_two_burst_spacing = float(profile.get("phase_two_burst_spacing", phase_two_burst_spacing))
	patrol_distance = float(profile.get("patrol_distance", patrol_distance))
	projectile_damage = int(profile.get("projectile_damage", projectile_damage))
	projectile_speed = float(profile.get("projectile_speed", projectile_speed))
	projectile_lifetime = float(profile.get("projectile_lifetime", projectile_lifetime))
	projectile_knockback = profile.get("projectile_knockback", projectile_knockback) as Vector2
	projectile_weapon_id = profile.get("projectile_weapon_id", projectile_weapon_id) as StringName
	projectile_attack_id = profile.get("projectile_attack_id", projectile_attack_id) as StringName
	projectile_color = profile.get("projectile_color", projectile_color) as Color
	projectile_visual_scale = profile.get("projectile_visual_scale", projectile_visual_scale) as Vector2
	contact_damage = int(profile.get("contact_damage", contact_damage))
	contact_knockback = profile.get("contact_knockback", contact_knockback) as Vector2
	contact_weapon_id = profile.get("contact_weapon_id", contact_weapon_id) as StringName
	phase_two_tint = profile.get("phase_two_tint", phase_two_tint) as Color
	defeated_tint = profile.get("defeated_tint", defeated_tint) as Color

	if body_sprite != null:
		body_sprite.texture = PROFILE_TEXTURES.get(resolved_boss_id, body_sprite.texture)
	if attack_marker != null:
		attack_marker.modulate = PROFILE_ATTACK_COLORS.get(resolved_boss_id, attack_marker.modulate)
	if health_component != null:
		health_component.max_health = int(profile.get("max_health", health_component.max_health))
		health_component.reset()
	_refresh_visuals()

