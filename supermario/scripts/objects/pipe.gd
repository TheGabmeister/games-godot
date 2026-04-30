extends StaticBody2D

@export var warp_target: NodePath
@export var pipe_height: int = 2  # in tiles (each tile = 16px)
@export var entry_sound: AudioStream

var _player_on_top: bool = false
var _player_ref: CharacterBody2D

@onready var _warp_zone: Area2D = $WarpZone
@onready var _col_shape: CollisionShape2D = $CollisionShape2D
@onready var _warp_shape: CollisionShape2D = $WarpZone/WarpShape


func _ready() -> void:
	collision_layer = 1  # Terrain
	collision_mask = 0
	z_index = 5
	z_as_relative = false

	# Each instance needs its own shape — scene sub-resources are shared across
	# instances, so modifying one pipe's shape would resize all of them.
	var h: float = pipe_height * 16.0
	var body_shape := RectangleShape2D.new()
	body_shape.size = Vector2(32, h)
	_col_shape.shape = body_shape
	_col_shape.position = Vector2(0, -h / 2.0)

	# Position warp zone on top of the pipe
	var warp_shape := RectangleShape2D.new()
	warp_shape.size = Vector2(24, 8)
	_warp_shape.shape = warp_shape
	_warp_shape.position = Vector2(0, -h - 4.0)

	_warp_zone.body_entered.connect(_on_warp_zone_body_entered)
	_warp_zone.body_exited.connect(_on_warp_zone_body_exited)


func _process(_delta: float) -> void:
	if not _player_on_top or not _player_ref:
		return
	if not _player_ref.is_on_floor():
		return
	if warp_target.is_empty():
		return
	if Input.is_action_just_pressed(&"crouch"):
		var target := get_node_or_null(warp_target)
		if target and _player_ref.has_method("enter_pipe"):
			_player_ref.enter_pipe(self, target)


func get_entry_position() -> Vector2:
	return global_position + Vector2(0, -pipe_height * 16.0)


func get_exit_position() -> Vector2:
	return global_position + Vector2(0, -pipe_height * 16.0 - 1.0)


func play_entry_sound() -> void:
	if entry_sound != null:
		EventBus.sfx_requested.emit(entry_sound)


func _on_warp_zone_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_on_top = true
		_player_ref = body as CharacterBody2D


func _on_warp_zone_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_on_top = false
		_player_ref = null


func _draw() -> void:
	var h: float = pipe_height * 16.0
	# Pipe head (wider lip)
	draw_rect(Rect2(-16, -h, 32, 8), Palette.PIPE_GREEN_LIGHT)
	draw_rect(Rect2(-16, -h, 4, 8), Palette.PIPE_GREEN)
	draw_rect(Rect2(12, -h, 4, 8), Palette.PIPE_GREEN)
	# Pipe body
	draw_rect(Rect2(-12, -h + 8, 24, h - 8), Palette.PIPE_GREEN_LIGHT)
	draw_rect(Rect2(-12, -h + 8, 4, h - 8), Palette.PIPE_GREEN)
	draw_rect(Rect2(8, -h + 8, 4, h - 8), Palette.PIPE_GREEN)
