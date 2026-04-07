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
		state_machine.transition_to(&"Idle")
		return

	player.velocity = Vector2.ZERO
	AudioManager.play_sfx(&"lift")

	# Tween object from its world position to above player head
	var start_pos: Vector2 = _target.global_position
	var end_offset := Vector2(0, -16)

	# Remove target from its current parent and store as data
	# We don't reparent to player — we just track it and free it when done
	var target_drop_table: LootTable = _target.drop_table if "drop_table" in _target else null
	var target_visual_type: StringName = _get_visual_type(_target)
	var target_visual_color: Color = _target._get_particle_color() if _target.has_method("_get_particle_color") else Color(0.5, 0.4, 0.3)

	# Remove the destructible from the scene
	if _target.has_method("_persist_removal"):
		_target._persist_removal()
	_target.queue_free()

	# After brief lift animation, transition to carry
	_lift_tween = player.create_tween()
	_lift_tween.tween_interval(LIFT_DURATION)
	_lift_tween.tween_callback(func() -> void:
		state_machine.transition_to(&"Carry", {
			"drop_table": target_drop_table,
			"visual_type": target_visual_type,
			"visual_color": target_visual_color,
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
