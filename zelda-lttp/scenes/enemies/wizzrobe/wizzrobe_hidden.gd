extends BaseEnemyState

var _timer: float = 0.0
var _wait_time: float = 0.0


func enter(_msg: Dictionary = {}) -> void:
	_timer = 0.0
	_wait_time = randf_range(1.5, 2.5)

	# Make invisible and invulnerable
	actor.visible = false
	actor.set_invulnerable(true)

	# Disable contact hitbox while hidden
	var contact: Area2D = actor.get_node_or_null("ContactHitbox")
	if contact:
		contact.monitorable = false


func update(delta: float) -> void:
	_timer += delta
	if _timer >= _wait_time:
		# Pick a random teleport position and move there
		var target_pos: Vector2 = actor.get_random_teleport_position()
		actor.global_position = target_pos

		# Face toward the player if possible
		var player: CharacterBody2D = actor.get_player()
		if player:
			var dir: Vector2 = (player.global_position - actor.global_position).normalized()
			actor.update_facing(dir)

		state_machine.transition_to(&"Appear")
