extends "res://scripts/player/player_states/player_state.gd"

var _pipe: Node2D
var _target_pipe: Node2D
var _phase: int = 0  # 0=slide_in, 1=fade, 2=slide_out, 3=done


func enter() -> void:
	_phase = 0
	player.velocity = Vector2.ZERO
	player.set_physics_process(false)

	# Disable collision during pipe transition
	player.collision_shape.set_deferred("disabled", true)
	player.stomp_detector.set_deferred("monitoring", false)
	player.hurtbox.set_deferred("monitoring", false)
	player.hurtbox.set_deferred("monitorable", false)

	# Drop z_index below pipe (z=5) so Mario slides behind it
	player.z_index = 0
	player.z_as_relative = false

	if _pipe.has_method("play_entry_sound"):
		_pipe.play_entry_sound()

	# Center on pipe and slide down
	var entry_x: float = _pipe.global_position.x
	player.global_position.x = entry_x

	var slide_target := player.global_position + Vector2(0, 64)
	var tween := player.create_tween()
	tween.tween_property(player, "global_position", slide_target, 0.5)
	tween.tween_callback(_start_fade)


func exit() -> void:
	player.z_index = 10
	player.z_as_relative = false
	player.set_physics_process(true)
	player.collision_shape.set_deferred("disabled", false)
	player.stomp_detector.set_deferred("monitoring", true)
	player.hurtbox.set_deferred("monitoring", true)
	player.hurtbox.set_deferred("monitorable", true)


func setup(pipe: Node2D, target: Node2D) -> void:
	_pipe = pipe
	_target_pipe = target


func _start_fade() -> void:
	_phase = 1
	_reposition()


func _reposition() -> void:
	_phase = 2
	# Move to target pipe exit
	var exit_pos: Vector2
	if _target_pipe.has_method("get_exit_position"):
		exit_pos = _target_pipe.get_exit_position()
	else:
		exit_pos = _target_pipe.global_position + Vector2(0, -64)
	player.global_position = exit_pos + Vector2(0, 64)

	player.camera.reset_smoothing()
	player.camera.reset_no_backtrack()

	var tween := player.create_tween()
	tween.tween_property(player, "global_position", exit_pos, 0.5)
	tween.tween_callback(_finish)


func _finish() -> void:
	_phase = 3
	state_machine.transition_to(StateIds.IDLE)
