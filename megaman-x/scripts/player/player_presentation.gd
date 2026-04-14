extends Node2D

const PLAYER_SCRIPT = preload("res://scripts/player/player.gd")

@export var idle_texture: Texture2D
@export var run_texture: Texture2D
@export var jump_texture: Texture2D
@export var fall_texture: Texture2D

@onready var player: Node = get_parent()
@onready var sprite: Sprite2D = $Sprite2D
@onready var state_label: Label = $StateLabel


func _ready() -> void:
	if player == null:
		push_error("PlayerPresentation must be parented under PlayerController.")
		return

	player.connect("locomotion_state_changed", _on_player_locomotion_state_changed)
	player.connect("facing_changed", _on_player_facing_changed)
	_refresh_visuals()


func _on_player_locomotion_state_changed(_previous_state: int, _new_state: int) -> void:
	_refresh_visuals()


func _on_player_facing_changed(new_facing_direction: int) -> void:
	sprite.flip_h = new_facing_direction < 0


func _refresh_visuals() -> void:
	if player == null:
		return

	var locomotion_state := int(player.get("locomotion_state"))
	sprite.texture = _get_texture_for_state(locomotion_state)
	sprite.modulate = _get_modulate_for_state(locomotion_state)
	sprite.flip_h = int(player.get("facing_direction")) < 0
	state_label.text = String(player.call("get_locomotion_state_name"))


func _get_texture_for_state(state: int) -> Texture2D:
	match state:
		PLAYER_SCRIPT.LocomotionState.RUN:
			return run_texture
		PLAYER_SCRIPT.LocomotionState.JUMP:
			return jump_texture
		PLAYER_SCRIPT.LocomotionState.FALL:
			return fall_texture
		PLAYER_SCRIPT.LocomotionState.HURT:
			return jump_texture
		PLAYER_SCRIPT.LocomotionState.DEAD:
			return idle_texture
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
