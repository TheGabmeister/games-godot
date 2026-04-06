class_name Player extends CharacterBody2D

@onready var state_machine: StateMachine = $StateMachine
@onready var player_body: Node2D = $PlayerBody
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var camera: Camera2D = $Camera2D

var facing_direction: Vector2 = Vector2.DOWN
var move_input: Vector2 = Vector2.ZERO
var speed: float = 90.0
var push_speed: float = 30.0
var dash_speed_multiplier: float = 2.5
var last_safe_position: Vector2 = Vector2.ZERO

# Sword attack
var sword_active: bool = false
var sword_damage: int = 2
var sword_arc_progress: float = 0.0

# Knockback
var knockback_velocity: Vector2 = Vector2.ZERO


func _ready() -> void:
	last_safe_position = global_position
	# Initialize player states with reference to this player
	for state in state_machine.states.values():
		if state is BasePlayerState:
			state.player = self

	# Connect hurtbox for damage
	var hurtbox := $HurtboxComponent as Area2D
	if hurtbox:
		hurtbox.area_entered.connect(_on_hurtbox_area_entered)

	# Connect screen shake
	EventBus.screen_shake_requested.connect(_on_screen_shake_requested)


func update_facing(direction: Vector2) -> void:
	if direction != Vector2.ZERO:
		# Snap to 4 directions for facing
		if absf(direction.x) > absf(direction.y):
			facing_direction = Vector2(signf(direction.x), 0)
		else:
			facing_direction = Vector2(0, signf(direction.y))
		player_body.queue_redraw()


func get_sword_tier() -> int:
	return PlayerState.get_upgrade(&"sword") if PlayerState.has_upgrade(&"sword") else 1


func get_sword_damage() -> int:
	var tier := get_sword_tier()
	match tier:
		1: return 2
		2: return 4
		3: return 8
		4: return 16
		_: return 2


func _on_hurtbox_area_entered(area: Area2D) -> void:
	# Check if it's a pit/hazard
	if area.collision_layer & 64:  # Layer 7 = Hazards (bit 6, 0-indexed)
		state_machine.transition_to(&"Fall")
		return

	# Check if it's an enemy attack
	if area.collision_layer & 16:  # Layer 5 = EnemyAttacks (bit 4)
		var direction := (global_position - area.global_position).normalized()
		var damage := 2
		if area.has_meta("damage"):
			damage = area.get_meta("damage")
		PlayerState.apply_damage(damage)
		state_machine.transition_to(&"Knockback", {"direction": direction})
		EventBus.screen_shake_requested.emit(1.0, 0.12)


# --- Screen Shake ---

var _shake_intensity: float = 0.0
var _shake_duration: float = 0.0
var _shake_timer: float = 0.0


func _on_screen_shake_requested(intensity: float, duration: float) -> void:
	if intensity > _shake_intensity:
		_shake_intensity = intensity
		_shake_duration = duration
		_shake_timer = 0.0


func _physics_process(_delta: float) -> void:
	if _shake_timer < _shake_duration:
		_shake_timer += _delta
		var remaining := 1.0 - (_shake_timer / _shake_duration)
		var offset := Vector2(
			randf_range(-1.0, 1.0) * _shake_intensity * remaining,
			randf_range(-1.0, 1.0) * _shake_intensity * remaining
		)
		camera.offset = offset
	elif camera.offset != Vector2.ZERO:
		camera.offset = Vector2.ZERO
		_shake_intensity = 0.0
