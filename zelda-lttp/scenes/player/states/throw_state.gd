extends BasePlayerState
## Player throws the carried object in facing direction.

const THROW_DURATION := 0.15

var _throw_timer: float = 0.0


func enter(msg: Dictionary = {}) -> void:
	super.enter(msg)
	player.velocity = Vector2.ZERO
	_throw_timer = 0.0

	# Spawn the thrown object projectile
	var thrown := ThrownObject.new()
	thrown.direction = player.facing_direction.normalized()
	thrown.drop_table = msg.get("drop_table", null)
	thrown.visual_type = msg.get("visual_type", &"pot")
	thrown.visual_color = msg.get("visual_color", Color(0.5, 0.4, 0.3))
	thrown.persist_id = msg.get("persist_id", &"")
	thrown.persist_room_id = msg.get("room_id", &"")
	thrown.global_position = player.global_position + Vector2(0, -8)
	player.get_parent().add_child(thrown)

	AudioManager.play_sfx(&"throw")


func physics_update(delta: float) -> void:
	_throw_timer += delta
	if _throw_timer >= THROW_DURATION:
		state_machine.transition_to(&"Idle")
