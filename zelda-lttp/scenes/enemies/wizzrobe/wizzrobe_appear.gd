extends BaseEnemyState

const FADE_DURATION: float = 0.2

var _tween: Tween = null


func enter(_msg: Dictionary = {}) -> void:
	actor.visible = true
	actor.modulate.a = 0.0
	actor.set_invulnerable(false)

	# Enable contact hitbox
	var contact: Area2D = actor.get_node_or_null("ContactHitbox")
	if contact:
		contact.monitorable = true

	# Fade in
	_tween = actor.create_tween()
	_tween.tween_property(actor, "modulate:a", 1.0, FADE_DURATION)
	_tween.finished.connect(_on_fade_done)


func exit() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = null


func _on_fade_done() -> void:
	state_machine.transition_to(&"Telegraph")
