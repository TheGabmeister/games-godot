extends StaticBody2D

const SpriteFramesBuilder := preload("res://scripts/visuals/sprite_frames_builder.gd")
const SHEET := preload("res://sprites/pipe_sheet.png")
const TILE_SIZE: float = 32.0
const ANIMATIONS := {
	&"cap": {"frames": [0], "fps": 1.0, "loop": false},
	&"body": {"frames": [1], "fps": 1.0, "loop": false},
}

@export var warp_target: NodePath
@export var pipe_height: int = 2  # in tiles
@export var entry_sound: AudioStream

var _player_on_top: bool = false
var _player_ref: CharacterBody2D

@onready var _warp_zone: Area2D = $WarpZone
@onready var _col_shape: CollisionShape2D = $CollisionShape2D
@onready var _warp_shape: CollisionShape2D = $WarpZone/WarpShape
@onready var _cap_sprite: AnimatedSprite2D = $CapSprite
@onready var _body_sprites: Array[AnimatedSprite2D] = [
	$BodySprite0, $BodySprite1, $BodySprite2, $BodySprite3,
]


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	z_index = 5
	z_as_relative = false

	var h: float = pipe_height * TILE_SIZE
	var body_shape := RectangleShape2D.new()
	body_shape.size = Vector2(TILE_SIZE * 2.0, h)
	_col_shape.shape = body_shape
	_col_shape.position = Vector2(0, -h / 2.0)

	var warp_shape := RectangleShape2D.new()
	warp_shape.size = Vector2(TILE_SIZE * 1.5, TILE_SIZE * 0.5)
	_warp_shape.shape = warp_shape
	_warp_shape.position = Vector2(0, -h - TILE_SIZE * 0.25)

	_warp_zone.body_entered.connect(_on_warp_zone_body_entered)
	_warp_zone.body_exited.connect(_on_warp_zone_body_exited)
	_build_sprites()


func _build_sprites() -> void:
	var h: float = pipe_height * TILE_SIZE
	var frames := SpriteFramesBuilder.build(SHEET, 2, ANIMATIONS)
	_cap_sprite.sprite_frames = frames
	_cap_sprite.animation = &"cap"
	_cap_sprite.position = Vector2(-32, -h - 8)
	_cap_sprite.scale = Vector2(2.0, 1.0)

	for i in _body_sprites.size():
		var body := _body_sprites[i]
		body.sprite_frames = frames
		body.animation = &"body"
		body.visible = i < pipe_height
		if not body.visible:
			continue
		body.position = Vector2(-24, -h + 16 + i * TILE_SIZE)
		body.scale = Vector2(1.5, 1.0)


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
	return global_position + Vector2(0, -pipe_height * TILE_SIZE)


func get_exit_position() -> Vector2:
	return global_position + Vector2(0, -pipe_height * TILE_SIZE - 1.0)


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
