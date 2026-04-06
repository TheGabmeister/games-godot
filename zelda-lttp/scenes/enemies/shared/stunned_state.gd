extends BaseEnemyState

@export var stun_duration: float = 2.0

var _timer: float = 0.0
var _previous_state: StringName = &""


func enter(msg: Dictionary = {}) -> void:
	_timer = 0.0
	var prev: StringName = msg.get("previous_state", &"")
	if prev != &"Stunned" and prev != &"":
		_previous_state = prev

	# Blue tint
	var body: CanvasItem = actor.get_node_or_null("EnemyBody") as CanvasItem
	if body:
		body.modulate = Color(0.5, 0.5, 1.0)


func exit() -> void:
	var body: CanvasItem = actor.get_node_or_null("EnemyBody") as CanvasItem
	if body:
		body.modulate = Color.WHITE


func update(delta: float) -> void:
	_timer += delta
	if _timer >= stun_duration:
		if _previous_state != &"" and state_machine.states.has(_previous_state):
			state_machine.transition_to(_previous_state)
		else:
			# Fall back to first non-stunned state
			for sn: StringName in state_machine.states:
				if sn != &"Stunned":
					state_machine.transition_to(sn)
					return
