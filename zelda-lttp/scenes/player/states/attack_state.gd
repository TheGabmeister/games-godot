extends BasePlayerState

var _attack_timer: float = 0.0
const ATTACK_DURATION := 0.28
var _hitbox_activated: bool = false


func enter(msg: Dictionary = {}) -> void:
	super.enter(msg)
	_attack_timer = 0.0
	_hitbox_activated = false
	player.sword_active = true
	player.sword_arc_progress = 0.0
	player.velocity = Vector2.ZERO
	AudioManager.play_sfx(&"sword_swing")

	# Enable sword hitbox
	var sword_hitbox := player.get_node_or_null("SwordHitbox")
	if sword_hitbox and sword_hitbox.has_method("activate"):
		sword_hitbox.activate(player.facing_direction, player.get_sword_damage())
		_hitbox_activated = true


func exit() -> void:
	player.sword_active = false
	player.sword_arc_progress = 0.0
	player.player_body.queue_redraw()

	var sword_hitbox := player.get_node_or_null("SwordHitbox")
	if sword_hitbox and sword_hitbox.has_method("deactivate"):
		sword_hitbox.deactivate()


func update(delta: float) -> void:
	super.update(delta)
	_attack_timer += delta
	player.sword_arc_progress = clampf(_attack_timer / ATTACK_DURATION, 0.0, 1.0)
	player.player_body.queue_redraw()

	if _attack_timer >= ATTACK_DURATION:
		# Check if player is holding movement
		var input := get_movement_input()
		if input != Vector2.ZERO:
			state_machine.transition_to(&"Walk")
		else:
			# Check buffer
			var buffered := consume_buffer()
			if buffered == &"action_sword":
				state_machine.transition_to(&"Attack")
			else:
				state_machine.transition_to(&"Idle")


func handle_input(event: InputEvent) -> void:
	if event.is_action_pressed("action_sword"):
		buffer_action(&"action_sword")
