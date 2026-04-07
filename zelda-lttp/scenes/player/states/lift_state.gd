extends BasePlayerState
## Player lifts a destructible object above their head.

var _target: Node2D = null
var _lift_tween: Tween = null
const LIFT_DURATION := 0.3


func enter(msg: Dictionary = {}) -> void:
	super.enter(msg)
	_target = msg.get("target", null) as Node2D
	if not _target or not is_instance_valid(_target):
		state_machine.transition_to(&"Idle")
		return

	# Weight check
	var weight: int = _target.weight if "weight" in _target else 0
	if weight > PlayerState.get_upgrade(&"gloves"):
		AudioManager.play_sfx(&"error")
		EventBus.screen_shake_requested.emit(0.5, 0.15)
		state_machine.transition_to(&"Idle")
		return

	player.velocity = Vector2.ZERO
	AudioManager.play_sfx(&"lift")

	# Capture data from the target before hiding it
	var target_drop_table: LootTable = _target.drop_table if "drop_table" in _target else null
	var target_visual_type: StringName = _get_visual_type(_target)
	var target_visual_color: Color = _target._get_particle_color() if _target.has_method("_get_particle_color") else Color(0.5, 0.4, 0.3)
	var target_persist_id: StringName = _target.persist_id if "persist_id" in _target else &""
	var target_room_id: StringName = _target._get_room_id() if _target.has_method("_get_room_id") else &""

	# Hide and disable the destructible — don't free or persist yet
	_target.visible = false
	_target.set_deferred("collision_layer", 0)
	# Disable child areas so the interact probe stops seeing it
	for child in _target.get_children():
		if child is Area2D:
			child.set_deferred("collision_layer", 0)
			child.set_deferred("monitorable", false)
		if child is CollisionShape2D:
			child.set_deferred("disabled", true)

	# After brief lift animation, transition to carry
	_lift_tween = player.create_tween()
	_lift_tween.tween_interval(LIFT_DURATION)
	_lift_tween.tween_callback(func() -> void:
		# Now free the scene node (still not persisted — that happens on shatter)
		if is_instance_valid(_target):
			_target.queue_free()
		state_machine.transition_to(&"Carry", {
			"drop_table": target_drop_table,
			"visual_type": target_visual_type,
			"visual_color": target_visual_color,
			"persist_id": target_persist_id,
			"room_id": target_room_id,
		})
	)


func _get_visual_type(target: Node2D) -> StringName:
	if target is Bush:
		return &"bush"
	elif target is Skull:
		return &"skull"
	elif target is SignPost:
		return &"sign"
	return &"pot"


func exit() -> void:
	if _lift_tween and _lift_tween.is_valid():
		_lift_tween.kill()
