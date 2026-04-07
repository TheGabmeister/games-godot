extends BaseEnemy
## Like-Like: tube-shaped enemy that engulfs the player and can steal shield tier.

@export var detection_radius: float = 64.0
@export var lose_interest_radius: float = 96.0
@export var pursue_speed: float = 25.0
@export var engulf_range: float = 12.0

var player_detected: bool = false
var player_ref: CharacterBody2D = null
var _is_engulfing: bool = false


func _ready() -> void:
	super._ready()

	var detection: Area2D = get_node_or_null("DetectionZone")
	if detection:
		var shape_node: CollisionShape2D = detection.get_node_or_null("DetectionShape")
		if shape_node:
			var circle := CircleShape2D.new()
			circle.radius = detection_radius
			shape_node.shape = circle
		detection.body_entered.connect(_on_detection_entered)
		detection.body_exited.connect(_on_detection_exited)


func _on_detection_entered(body: Node) -> void:
	if body is CharacterBody2D and body.collision_layer & 2:  # Player layer
		player_detected = true
		player_ref = body as CharacterBody2D


func _on_detection_exited(body: Node) -> void:
	if body == player_ref:
		player_detected = false


func engulf_player() -> void:
	if _is_engulfing or not player_ref:
		return
	_is_engulfing = true
	AudioManager.play_sfx(&"engulf")
	# Force the player into TrappedState
	if player_ref.has_node("StateMachine"):
		var sm: StateMachine = player_ref.get_node("StateMachine") as StateMachine
		sm.transition_to(&"Trapped", {"captor": self})


func release_player() -> void:
	_is_engulfing = false
	# Return to Idle after releasing
	if state_machine.current_state.name == &"Engulf":
		state_machine.transition_to(&"Idle")


func _on_died() -> void:
	# Release player if engulfing when killed
	if _is_engulfing:
		release_player()
	super._on_died()
