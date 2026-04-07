extends BasePlayerState
## Player is trapped inside a Like-Like. Mash action_sword to escape.
## If engulf timer expires, shield tier is reduced.

const ENGULF_DURATION := 3.0
const DAMAGE_TICK_INTERVAL := 0.8
const MASH_THRESHOLD := 6  # Button presses needed to escape

var _timer: float = 0.0
var _damage_timer: float = 0.0
var _mash_count: int = 0
var _captor: Node2D = null  # The Like-Like that captured us


func enter(msg: Dictionary = {}) -> void:
	super.enter(msg)
	_timer = 0.0
	_damage_timer = 0.0
	_mash_count = 0
	_captor = msg.get("captor", null)
	player.velocity = Vector2.ZERO


func update(delta: float) -> void:
	super.update(delta)
	_timer += delta

	# Tick damage periodically
	_damage_timer += delta
	if _damage_timer >= DAMAGE_TICK_INTERVAL:
		_damage_timer -= DAMAGE_TICK_INTERVAL
		PlayerState.apply_damage(1)
		var flash: FlashComponent = player.get_node_or_null("FlashComponent") as FlashComponent
		if flash:
			flash.flash()
		# Lethal tick — release and die
		if PlayerState.current_health <= 0:
			if _captor and is_instance_valid(_captor) and _captor.has_method("release_player"):
				_captor.release_player()
			state_machine.transition_to(&"Death")
			return

	# Time's up — drop shield tier and release
	if _timer >= ENGULF_DURATION:
		PlayerState.reduce_upgrade(&"shield", 1)
		AudioManager.play_sfx(&"shield_break")
		_escape()


func handle_input(event: InputEvent) -> void:
	if event.is_action_pressed("action_sword"):
		_mash_count += 1
		# Shake to show progress
		EventBus.screen_shake_requested.emit(0.3, 0.05)
		if _mash_count >= MASH_THRESHOLD:
			AudioManager.play_sfx(&"escape")
			_escape()


func _escape() -> void:
	# Notify the captor to release us
	if _captor and is_instance_valid(_captor) and _captor.has_method("release_player"):
		_captor.release_player()
	# Knockback away from captor
	var kb_dir := Vector2.DOWN
	if _captor and is_instance_valid(_captor):
		kb_dir = (player.global_position - _captor.global_position).normalized()
	state_machine.transition_to(&"Knockback", {"direction": kb_dir, "force": 100.0})


func exit() -> void:
	_captor = null
