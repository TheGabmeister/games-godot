extends Node2D

## Places repeating sprite-based cloud, hill, and bush decorations with parallax.

const SpriteFramesBuilder := preload("res://scripts/visuals/sprite_frames_builder.gd")
const SHEET := preload("res://sprites/background_decor_sheet.png")
const ANIMATIONS := {
	&"cloud": {"frames": [0], "fps": 1.0, "loop": false},
	&"hill": {"frames": [1], "fps": 1.0, "loop": false},
	&"bush": {"frames": [2], "fps": 1.0, "loop": false},
}

@export var parallax_clouds: float = 0.3
@export var parallax_hills: float = 0.5

var _camera: Camera2D
@onready var _hill_sprites: Array[AnimatedSprite2D] = [
	$Hill0, $Hill1, $Hill2, $Hill3, $Hill4, $Hill5,
]
@onready var _cloud_sprites: Array[AnimatedSprite2D] = [
	$Cloud0, $Cloud1, $Cloud2, $Cloud3, $Cloud4, $Cloud5,
	$Cloud6, $Cloud7, $Cloud8, $Cloud9, $Cloud10, $Cloud11,
]
@onready var _bush_sprites: Array[AnimatedSprite2D] = [
	$Bush0, $Bush1, $Bush2, $Bush3, $Bush4, $Bush5,
]


func _ready() -> void:
	var frames := SpriteFramesBuilder.build(SHEET, 3, ANIMATIONS)
	for sprite in _hill_sprites:
		sprite.sprite_frames = frames
		sprite.animation = &"hill"
	for sprite in _cloud_sprites:
		sprite.sprite_frames = frames
		sprite.animation = &"cloud"
	for sprite in _bush_sprites:
		sprite.sprite_frames = frames
		sprite.animation = &"bush"


func _process(_delta: float) -> void:
	if not _camera:
		var player := get_tree().get_first_node_in_group("player")
		if player:
			_camera = player.get_node("Camera2D") as Camera2D
	if not _camera:
		return

	var cam_x := _camera.get_screen_center_position().x
	_update_hills(cam_x)
	_update_clouds(cam_x)
	_update_bushes(cam_x)


func _update_hills(cam_x: float) -> void:
	var offset_x := cam_x * (1.0 - parallax_hills)
	var pattern_width: float = 768.0
	var start_x := floorf((cam_x - 256.0 - offset_x) / pattern_width) * pattern_width
	var idx := 0
	for i in 3:
		var base_x := start_x + i * pattern_width - offset_x
		_place_sprite(_hill_sprites[idx], 1, Vector2(base_x - 70.0, 132.0), Vector2(4.4, 2.2))
		idx += 1
		_place_sprite(_hill_sprites[idx], 1, Vector2(base_x + 210.0, 154.0), Vector2(2.7, 1.4))
		idx += 1


func _update_clouds(cam_x: float) -> void:
	var offset_x := cam_x * (1.0 - parallax_clouds)
	var pattern_width: float = 512.0
	var start_x := floorf((cam_x - 256.0 - offset_x) / pattern_width) * pattern_width
	var idx := 0
	for i in 4:
		var base_x := start_x + i * pattern_width - offset_x
		_place_sprite(_cloud_sprites[idx], 0, Vector2(base_x + 28.0, 16.0), Vector2(2.0, 1.2))
		idx += 1
		_place_sprite(_cloud_sprites[idx], 0, Vector2(base_x + 178.0, 37.0), Vector2(1.4, 0.9))
		idx += 1
		_place_sprite(_cloud_sprites[idx], 0, Vector2(base_x + 340.0, 6.0), Vector2(2.4, 1.4))
		idx += 1


func _update_bushes(cam_x: float) -> void:
	var offset_x := cam_x * (1.0 - parallax_hills)
	var pattern_width: float = 768.0
	var start_x := floorf((cam_x - 256.0 - offset_x) / pattern_width) * pattern_width
	var idx := 0
	for i in 3:
		var base_x := start_x + i * pattern_width - offset_x
		_place_sprite(_bush_sprites[idx], 2, Vector2(base_x + 98.0, 160.0), Vector2(2.0, 1.0))
		idx += 1
		_place_sprite(_bush_sprites[idx], 2, Vector2(base_x + 381.0, 172.0), Vector2(1.2, 0.7))
		idx += 1


func _place_sprite(sprite: AnimatedSprite2D, _frame: int, pos: Vector2, sprite_scale: Vector2) -> void:
	sprite.position = pos
	sprite.scale = sprite_scale
