extends BasePlayerState

var lock_timer: float = 0.0


func enter(msg: Dictionary = {}) -> void:
	super.enter(msg)
	player.velocity = Vector2.ZERO

	var effect: BaseItemEffect = PlayerState.get_equipped_effect()
	var skill: ItemData = PlayerState.get_equipped_skill()

	if effect == null or skill == null or not effect.can_use(player):
		state_machine.transition_to(&"Idle")
		return

	if not PlayerState.consume_skill_cost(skill):
		state_machine.transition_to(&"Idle")
		return

	lock_timer = effect.activate(player)
	AudioManager.play_sfx(skill.id)


func physics_update(delta: float) -> void:
	lock_timer -= delta
	if lock_timer <= 0.0:
		state_machine.transition_to(&"Idle")
