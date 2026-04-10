extends BasePlayerState
## Player death animation — spin, flash, collapse, then signal game over.

const SPIN_DURATION := 1.0
const COLLAPSE_DURATION := 0.4

var _timer: float = 0.0
var _phase: int = 0  # 0=spin, 1=collapse


func enter(msg: Dictionary = {}) -> void:
	super.enter(msg)
	_timer = 0.0
	_phase = 0
	player.velocity = Vector2.ZERO

	AudioManager.play_sfx(&"player_death")

	# Spin phase: rotate the body
	var body: Node2D = player.player_body
	if body:
		var tween := player.create_tween()
		tween.tween_property(body, "rotation", TAU * 2, SPIN_DURATION)
		tween.tween_callback(func() -> void:
			body.rotation = 0.0
			_start_collapse()
		)

	# Flash during spin
	var flash: FlashComponent = player.get_node_or_null("FlashComponent") as FlashComponent
	if flash:
		flash.flash()


func _start_collapse() -> void:
	_phase = 1
	_timer = 0.0
	var body: Node2D = player.player_body
	if body:
		var tween := player.create_tween()
		tween.tween_property(body, "scale", Vector2(1.5, 0.1), COLLAPSE_DURATION)
		tween.tween_property(body, "modulate:a", 0.0, 0.2)
		tween.tween_callback(func() -> void:
			EventBus.game_over_requested.emit()
		)


func update(delta: float) -> void:
	_timer += delta


func exit() -> void:
	# Reset body visuals
	var body: Node2D = player.player_body
	if body:
		body.rotation = 0.0
		body.scale = Vector2.ONE
		body.modulate = Color.WHITE
