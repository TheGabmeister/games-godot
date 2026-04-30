extends Node2D

const SpriteHelper := preload("res://scripts/visuals/sprite_region_helper.gd")
const StateIds := preload("res://scripts/player/player_state_ids.gd")
const PLAYER_SHEET := preload("res://sprites/player_sheet.png")
const COLUMNS := 6

var power_state: int = 0  # GameManager.PowerState
var is_crouching: bool = false
var star_power_active: bool = false

var _walk_cycle: float = 0.0
var _is_moving: bool = false
var _star_cycle: float = 0.0
var _sprite: Sprite2D


func _ready() -> void:
	_sprite = SpriteHelper.ensure_sprite(self, &"Sprite", PLAYER_SHEET)
	SpriteHelper.set_cell(_sprite, 0, COLUMNS, Vector2(-16, -30))


func _process(delta: float) -> void:
	var parent_body := owner as CharacterBody2D
	if parent_body:
		_is_moving = absf(parent_body.velocity.x) > 10.0
		if _is_moving:
			_walk_cycle += absf(parent_body.velocity.x) * delta * 0.05
		else:
			_walk_cycle = 0.0
	if star_power_active:
		_star_cycle += delta * 8.0
		_sprite.modulate = _star_color()
	else:
		_sprite.modulate = Color.WHITE

	SpriteHelper.set_cell(_sprite, _get_frame(), COLUMNS, Vector2(-16, -30))


func _get_frame() -> int:
	var state_name := _get_state_name()
	if power_state == GameManager.PowerState.SMALL:
		if state_name == StateIds.DEATH:
			return 4
		if state_name == StateIds.JUMP or state_name == StateIds.FALL:
			return 3
		if _is_moving:
			return 1 + (int(_walk_cycle * 8.0) % 2)
		return 0

	var base := 11 if power_state == GameManager.PowerState.FIRE else 5
	if is_crouching:
		return base + 4
	if state_name == StateIds.FLAGPOLE:
		return base + 5
	if state_name == StateIds.JUMP or state_name == StateIds.FALL:
		return base + 3
	if _is_moving:
		return base + 1 + (int(_walk_cycle * 8.0) % 2)
	return base


func _get_state_name() -> StringName:
	var state_machine := owner.get_node_or_null("StateMachine") if owner else null
	if state_machine == null:
		return &""
	var current_state: Node = state_machine.current_state
	return current_state.name if current_state else &""


func _star_color() -> Color:
	match int(_star_cycle) % 4:
		0:
			return Color(1.0, 1.0, 0.5)
		1:
			return Color(1.0, 0.55, 0.55)
		2:
			return Color(0.55, 1.0, 0.65)
		_:
			return Color(0.75, 0.9, 1.0)
