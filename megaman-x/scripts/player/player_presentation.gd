extends Node2D

const PLAYER_SCRIPT = preload("res://scripts/player/player.gd")
const PLAYER_COMBAT_SCRIPT = preload("res://scripts/player/player_combat.gd")

@export var idle_texture: Texture2D
@export var run_texture: Texture2D
@export var jump_texture: Texture2D
@export var fall_texture: Texture2D
@export var hurt_texture: Texture2D
@export var dead_texture: Texture2D

@onready var player: Node = get_parent()
@onready var player_combat: Node = get_node_or_null("../PlayerCombat")
@onready var sprite: Sprite2D = $Sprite2D
@onready var state_label: Label = $StateLabel
@onready var charge_glow: Polygon2D = $ChargeGlow


func _ready() -> void:
	if player == null:
		push_error("PlayerPresentation must be parented under PlayerController.")
		return

	player.connect("locomotion_state_changed", _on_player_locomotion_state_changed)
	player.connect("facing_changed", _on_player_facing_changed)
	if player_combat != null:
		player_combat.connect("combat_state_changed", _on_player_combat_state_changed)
		player_combat.connect("charge_feedback_changed", _on_player_charge_feedback_changed)
	_refresh_visuals()


func _on_player_locomotion_state_changed(_previous_state: int, _new_state: int) -> void:
	_refresh_visuals()


func _on_player_facing_changed(new_facing_direction: int) -> void:
	sprite.flip_h = new_facing_direction < 0


func _on_player_combat_state_changed(_previous_state: int, _new_state: int) -> void:
	_refresh_visuals()


func _on_player_charge_feedback_changed(_previous_feedback: int, _new_feedback: int) -> void:
	_refresh_visuals()


func _refresh_visuals() -> void:
	if player == null:
		return

	var locomotion_state: int = player.get("locomotion_state")
	var facing_direction: int = player.get("facing_direction")
	sprite.texture = _get_texture_for_state(locomotion_state)
	sprite.modulate = _get_modulate_for_state(locomotion_state)
	sprite.flip_h = facing_direction < 0
	state_label.text = _build_state_label()
	_refresh_charge_glow()


func _get_texture_for_state(state: int) -> Texture2D:
	match state:
		PLAYER_SCRIPT.LocomotionState.RUN:
			return run_texture
		PLAYER_SCRIPT.LocomotionState.JUMP:
			return jump_texture
		PLAYER_SCRIPT.LocomotionState.FALL:
			return fall_texture
		PLAYER_SCRIPT.LocomotionState.HURT:
			return hurt_texture if hurt_texture != null else jump_texture
		PLAYER_SCRIPT.LocomotionState.DEAD:
			return dead_texture if dead_texture != null else idle_texture
		_:
			return idle_texture


func _get_modulate_for_state(state: int) -> Color:
	match state:
		PLAYER_SCRIPT.LocomotionState.HURT:
			return Color(1.0, 0.55, 0.55, 1.0)
		PLAYER_SCRIPT.LocomotionState.DEAD:
			return Color(0.72, 0.72, 0.72, 1.0)
		_:
			return Color(1.0, 1.0, 1.0, 1.0)


func _build_state_label() -> String:
	var label := str(player.call("get_locomotion_state_name"))
	if player_combat == null:
		return label

	var charge_name := str(player_combat.call("get_charge_feedback_name"))
	if charge_name != "none":
		label += " | %s" % charge_name

	return label


func _refresh_charge_glow() -> void:
	if charge_glow == null or player_combat == null:
		return

	var charge_feedback: int = player_combat.get("charge_feedback")
	charge_glow.visible = charge_feedback != PLAYER_COMBAT_SCRIPT.ChargeFeedback.NONE
	match charge_feedback:
		PLAYER_COMBAT_SCRIPT.ChargeFeedback.SMALL:
			charge_glow.color = Color(0.364706, 0.862745, 0.933333, 0.32)
			charge_glow.scale = Vector2(1.0, 1.0)
		PLAYER_COMBAT_SCRIPT.ChargeFeedback.FULL:
			charge_glow.color = Color(1.0, 0.839216, 0.372549, 0.4)
			charge_glow.scale = Vector2(1.4, 1.4)
		_:
			charge_glow.visible = false
