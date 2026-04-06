extends BaseEnemyState

const FLUTTER_SPEED := 40.0
const DIRECTION_CHANGE_TIME := 1.5
const SINE_AMPLITUDE := 25.0
const SINE_FREQUENCY := 5.0

var _base_direction: Vector2 = Vector2.RIGHT
var _timer: float = 0.0
var _elapsed: float = 0.0


func enter(msg: Dictionary = {}) -> void:
	super.enter(msg)
	_pick_direction()
	_timer = 0.0
	_elapsed = 0.0


func physics_update(delta: float) -> void:
	if not actor:
		return

	if actor.knockback_component.is_active():
		return

	_elapsed += delta
	_timer += delta

	if _timer >= DIRECTION_CHANGE_TIME:
		_pick_direction()
		_timer = 0.0

	# Sine-wave perpendicular to base direction
	var perp := Vector2(-_base_direction.y, _base_direction.x)
	var sine_offset: float = sin(_elapsed * SINE_FREQUENCY) * SINE_AMPLITUDE * delta
	var move_dir: Vector2 = _base_direction * FLUTTER_SPEED + perp * sine_offset * FLUTTER_SPEED
	actor.velocity = move_dir
	actor.move_and_slide()

	# Bounce off walls by picking a new direction
	if actor.get_slide_collision_count() > 0:
		_pick_direction()
		_timer = 0.0


func _pick_direction() -> void:
	var angle: float = randf() * TAU
	_base_direction = Vector2.from_angle(angle)
