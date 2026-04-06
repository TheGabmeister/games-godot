class_name ShieldComponent extends Area2D

## Shield tiers determine which projectile classes are blocked.
## Tier 1: rocks, arrows
## Tier 2: + fireballs, beams
## Tier 3: + magic projectiles, reflects select shots

const TIER_1_CLASSES: Array[StringName] = [&"rock", &"arrow"]
const TIER_2_CLASSES: Array[StringName] = [&"rock", &"arrow", &"fireball", &"beam"]
const TIER_3_CLASSES: Array[StringName] = [&"rock", &"arrow", &"fireball", &"beam", &"magic"]

var player: CharacterBody2D = null


func _ready() -> void:
	area_entered.connect(_on_area_entered)
	player = get_parent() as CharacterBody2D


func get_shield_tier() -> int:
	return PlayerState.get_upgrade(&"shield")


func can_block_class(projectile_class: StringName) -> bool:
	var tier: int = get_shield_tier()
	if tier <= 0:
		return false
	match tier:
		1: return projectile_class in TIER_1_CLASSES
		2: return projectile_class in TIER_2_CLASSES
		_: return projectile_class in TIER_3_CLASSES


func is_facing_source(source_pos: Vector2) -> bool:
	if not player:
		return false
	var to_source: Vector2 = (source_pos - player.global_position).normalized()
	var facing: Vector2 = player.facing_direction.normalized()

	# Check if holding shield button for wider arc
	var holding_shield: bool = Input.is_action_pressed("action_shield")
	var threshold: float = 0.3 if holding_shield else 0.5
	return facing.dot(to_source) > threshold


func try_block(projectile: Area2D) -> bool:
	var tier: int = get_shield_tier()
	if tier <= 0:
		return false

	var proj_class: StringName = &"rock"
	if projectile.has_meta("projectile_class"):
		proj_class = projectile.get_meta("projectile_class")
	elif projectile is Projectile:
		match projectile.damage_type:
			DamageType.Type.ARROW: proj_class = &"arrow"
			DamageType.Type.FIRE: proj_class = &"fireball"
			DamageType.Type.ICE: proj_class = &"magic"
			DamageType.Type.MAGIC: proj_class = &"magic"
			_: proj_class = &"rock"

	if not can_block_class(proj_class):
		return false

	if not is_facing_source(projectile.global_position):
		return false

	# Tier 3 reflects magic projectiles
	if tier >= 3 and proj_class == &"magic":
		_reflect(projectile)
	else:
		AudioManager.play_sfx(&"shield_block")
		projectile.queue_free()

	return true


func _reflect(projectile: Area2D) -> void:
	AudioManager.play_sfx(&"shield_reflect")
	if projectile is Projectile:
		projectile.direction = -projectile.direction
		projectile.source_team = &"player"
		projectile.collision_layer = 8  # PlayerAttacks
		projectile.collision_mask = 5   # World + Enemies
		projectile.set_meta("source_team", &"player")
	else:
		projectile.queue_free()


func _on_area_entered(area: Area2D) -> void:
	# Only process enemy projectiles
	if area.has_meta("source_team") and area.get_meta("source_team") == &"enemy":
		if try_block(area):
			# Prevent hurtbox from also processing this hit
			var hurtbox: HurtboxComponent = player.get_node_or_null("HurtboxComponent") as HurtboxComponent
			if hurtbox:
				hurtbox.is_invincible = true
