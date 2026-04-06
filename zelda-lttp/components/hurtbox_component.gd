class_name HurtboxComponent extends Area2D

signal hurt(hitbox_data: Dictionary)

@export var team: StringName = &"player"
@export var invincibility_duration: float = 0.5

var is_invincible: bool = false
var _invincibility_timer: float = 0.0


func _ready() -> void:
	area_entered.connect(_on_area_entered)


func _process(delta: float) -> void:
	if is_invincible:
		_invincibility_timer -= delta
		if _invincibility_timer <= 0.0:
			is_invincible = false


func _on_area_entered(area: Area2D) -> void:
	if is_invincible:
		return

	if area is HitboxComponent:
		var hitbox: HitboxComponent = area
		# Don't take damage from same team
		if hitbox.source_team == team:
			return
		var data: Dictionary = hitbox.get_hitbox_data()
		_start_invincibility()
		hurt.emit(data)
	elif area.has_meta("damage"):
		# Fallback for simple hazard areas (pits, spikes)
		var data := {
			"damage": area.get_meta("damage") as int,
			"damage_type": area.get_meta("damage_type") if area.has_meta("damage_type") else DamageType.Type.CONTACT,
			"knockback_force": area.get_meta("knockback_force") if area.has_meta("knockback_force") else 120.0,
			"effect": DamageType.HitEffect.NONE,
			"source_team": &"environment",
			"source_position": area.global_position,
		}
		_start_invincibility()
		hurt.emit(data)


func _start_invincibility() -> void:
	is_invincible = true
	_invincibility_timer = invincibility_duration


func reset_invincibility() -> void:
	is_invincible = false
	_invincibility_timer = 0.0
