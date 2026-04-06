extends BaseItemEffect

const LOCK_DURATION := 0.4
const HAMMER_RANGE := 12.0
const HAMMER_SIZE := Vector2(14, 14)


func can_use(_player: CharacterBody2D) -> bool:
	return true


func activate(player: CharacterBody2D) -> float:
	# Activate sword hitbox with CONTACT damage type for hammer
	var sword_hitbox: Area2D = player.get_node_or_null("SwordHitbox")
	if sword_hitbox and sword_hitbox.has_method("activate"):
		sword_hitbox.activate(player.facing_direction, 4)
		sword_hitbox.set_meta("damage_type", DamageType.Type.CONTACT)

	# Screen shake for impact
	EventBus.screen_shake_requested.emit(0.8, 0.15)
	AudioManager.play_sfx(&"hammer")

	# Deactivate after lock duration via tween
	var tween: Tween = player.create_tween()
	tween.tween_interval(LOCK_DURATION * 0.6)
	tween.tween_callback(func() -> void:
		if sword_hitbox and sword_hitbox.has_method("deactivate"):
			sword_hitbox.deactivate()
	)

	return LOCK_DURATION
