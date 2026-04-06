extends Node2D

const EXTEND_SPEED := 200.0
const MAX_LENGTH := 96.0
const RETRACT_SPEED := 200.0

var direction: Vector2 = Vector2.RIGHT
var origin_player: CharacterBody2D = null

var _tip_position: Vector2 = Vector2.ZERO
var _extending: bool = true
var _retracting: bool = false
var _chain_length: float = 0.0


func _ready() -> void:
	_tip_position = Vector2.ZERO


func _physics_process(delta: float) -> void:
	if _extending:
		_chain_length += EXTEND_SPEED * delta
		_tip_position = direction * _chain_length

		# Check for wall collision via raycast
		var space_state: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
		var query := PhysicsRayQueryParameters2D.create(
			global_position,
			global_position + _tip_position,
			1  # World layer
		)
		var result: Dictionary = space_state.intersect_ray(query)
		if result:
			_extending = false
			_retracting = true
			_tip_position = result.position - global_position
			AudioManager.play_sfx(&"hookshot_clink")

		if _chain_length >= MAX_LENGTH:
			_extending = false
			_retracting = true

	elif _retracting:
		_chain_length -= RETRACT_SPEED * delta
		_tip_position = direction * maxf(_chain_length, 0.0)

		if _chain_length <= 0.0:
			_finish()

	queue_redraw()


func _finish() -> void:
	if is_instance_valid(origin_player):
		var sm: StateMachine = origin_player.state_machine
		if sm.current_state.name == &"ItemUse":
			sm.transition_to(&"Idle")
	queue_free()


func _draw() -> void:
	# Draw chain line
	var chain_color := Color(0.5, 0.5, 0.6, 0.8)
	draw_line(Vector2.ZERO, _tip_position, chain_color, 1.5)
	# Draw hook tip
	draw_circle(_tip_position, 3.0, Color(0.6, 0.6, 0.7))
