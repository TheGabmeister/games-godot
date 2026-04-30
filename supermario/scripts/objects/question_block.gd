extends "res://scripts/objects/block_base.gd"

const CoinScene := preload("res://scenes/objects/coin.tscn")
const MushroomScene := preload("res://scenes/objects/mushroom.tscn")
const FireFlowerScene := preload("res://scenes/objects/fire_flower.tscn")
const StarmanScene := preload("res://scenes/objects/starman.tscn")
const OneUpScene := preload("res://scenes/objects/one_up.tscn")

@export var contents: StringName = &"coin"
@export var coin_sound: AudioStream

var _used: bool = false

@onready var _sprite: AnimatedSprite2D = $Sprite


func _ready() -> void:
	super._ready()
	_sprite.speed_scale = bump_config.pulse_frequency if bump_config else 1.0
	_sprite.play(&"question_active")


func _process(delta: float) -> void:
	super._process(delta)
	_sprite.position.y = -26 + _bump_offset


func bump_from_below() -> void:
	if _used:
		return
	_used = true
	_sprite.play(&"question_used")
	start_bump()
	play_bump_sound()
	EventBus.block_bumped.emit(global_position)
	_spawn_contents()


func _spawn_contents() -> void:
	var spawn_pos: Vector2 = global_position + Vector2(0, -32)
	match contents:
		&"coin":
			_play_sound(coin_sound)
			GameManager.add_coin(spawn_pos)
			EventBus.item_spawned.emit(&"coin", spawn_pos)
		&"mushroom":
			var item_type: StringName = &"mushroom"
			if GameManager.current_power_state != GameManager.PowerState.SMALL:
				item_type = &"fire_flower"
			_spawn_item(item_type, spawn_pos)
		&"fire_flower":
			_spawn_item(&"fire_flower", spawn_pos)
		&"starman":
			_spawn_item(&"starman", spawn_pos)
		&"1up":
			_spawn_item(&"1up", spawn_pos)
		_:
			push_warning("Unknown question block contents: %s" % contents)


func _spawn_item(item_type: StringName, spawn_pos: Vector2) -> void:
	var scene: PackedScene
	match item_type:
		&"mushroom":
			scene = MushroomScene
		&"fire_flower":
			scene = FireFlowerScene
		&"starman":
			scene = StarmanScene
		&"1up":
			scene = OneUpScene
	if scene == null:
		return
	var item := scene.instantiate() as Node2D
	get_parent().add_child(item)
	item.global_position = spawn_pos
	EventBus.item_spawned.emit(item_type, spawn_pos)
