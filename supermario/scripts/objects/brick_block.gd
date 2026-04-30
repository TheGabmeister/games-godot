extends "res://scripts/objects/block_base.gd"

const FramesBuilder := preload("res://scripts/visuals/sprite_frames_builder.gd")
const SHEET := preload("res://sprites/blocks_sheet.png")

@export var coin_count: int = 0
@export var break_sound: AudioStream
@export var coin_sound: AudioStream

var _used: bool = false

@onready var _sprite: AnimatedSprite2D = $Sprite


func _ready() -> void:
	super._ready()
	_sprite.sprite_frames = FramesBuilder.build(SHEET, 6, {
		&"active": {"frames": [4], "fps": 1.0, "loop": false},
		&"used": {"frames": [5], "fps": 1.0, "loop": false},
	})
	_sprite.play(&"active")


func _process(delta: float) -> void:
	super._process(delta)
	_sprite.position.y = -26 + _bump_offset


func bump_from_below() -> void:
	if _used:
		return
	var is_big: bool = GameManager.current_power_state != GameManager.PowerState.SMALL

	if coin_count > 0:
		start_bump()
		coin_count -= 1
		_play_sound(coin_sound)
		GameManager.add_coin(global_position + Vector2(0, -32))
		play_bump_sound()
		EventBus.block_bumped.emit(global_position)
		if coin_count == 0:
			_used = true
			_sprite.play(&"used")
		return

	if is_big:
		_play_sound(break_sound)
		EventBus.block_broken.emit(global_position)
		GameManager.add_score(50, global_position)
		queue_free()
	else:
		start_bump()
		play_bump_sound()
		EventBus.block_bumped.emit(global_position)
