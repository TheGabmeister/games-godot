extends "res://scripts/player/player_states/player_state.gd"

const SLIDE_SPEED: float = 240.0
const WALK_SPEED: float = 120.0
const CASTLE_OFFSET: float = 160.0  # walk distance past flagpole to castle

var _flagpole: Node2D
var _phase: int = 0  # 0=slide_down, 1=pause, 2=walk_to_castle
var _timer: float = 0.0
var _target_x: float = 0.0


func enter() -> void:
	_phase = 0
	_timer = 0.0
	player.velocity = Vector2.ZERO
	player.set_physics_process(false)

	# Disable interactions
	player.stomp_detector.set_deferred("monitoring", false)
	player.hurtbox.set_deferred("monitoring", false)
	player.hurtbox.set_deferred("monitorable", false)

	# Snap to pole
	player.global_position.x = _flagpole.get_pole_x() + 12.0
	player.visuals.scale = Vector2(-2.0, 2.0)  # face left (toward pole)

	_target_x = _flagpole.global_position.x + CASTLE_OFFSET


func exit() -> void:
	player.set_physics_process(true)


func setup(flagpole: Node2D) -> void:
	_flagpole = flagpole


func process_frame(delta: float) -> void:
	match _phase:
		0:  # Slide down pole
			var pole_bottom: float = _flagpole.get_pole_bottom_y()
			player.global_position.y += SLIDE_SPEED * delta
			if player.global_position.y >= pole_bottom:
				player.global_position.y = pole_bottom
				_phase = 1
				_timer = 0.0
				# Face right toward castle
				player.visuals.scale = Vector2(2.0, 2.0)
				player.global_position.x = _flagpole.global_position.x + 16.0

		1:  # Brief pause
			_timer += delta
			if _timer >= 0.3:
				_phase = 2

		2:  # Walk to castle
			player.global_position.x += WALK_SPEED * delta
			if player.global_position.x >= _target_x:
				player.global_position.x = _target_x
				player.visible = false
				_phase = 3  # prevent re-entry
				EventBus.level_completed.emit()
