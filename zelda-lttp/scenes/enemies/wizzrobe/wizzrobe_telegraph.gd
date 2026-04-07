extends BaseEnemyState

const TELEGRAPH_DURATION: float = 0.4

var _timer: float = 0.0
var _flash_timer: float = 0.0


func enter(_msg: Dictionary = {}) -> void:
	_timer = 0.0
	_flash_timer = 0.0

	# Face the player
	var player: CharacterBody2D = actor.get_player()
	if player:
		var dir: Vector2 = (player.global_position - actor.global_position).normalized()
		actor.update_facing(dir)


func update(delta: float) -> void:
	_timer += delta

	# Flash the body to telegraph attack
	_flash_timer += delta
	var body: Node2D = actor.get_node_or_null("EnemyBody")
	if body:
		var flash_val: float = (sin(_flash_timer * 20.0) + 1.0) * 0.5
		body.modulate = Color(1.0 + flash_val * 0.5, 1.0 + flash_val * 0.3, 1.0 + flash_val * 0.5)

	if _timer >= TELEGRAPH_DURATION:
		state_machine.transition_to(&"Fire")


func exit() -> void:
	# Reset body modulate
	var body: Node2D = actor.get_node_or_null("EnemyBody")
	if body:
		body.modulate = Color.WHITE
