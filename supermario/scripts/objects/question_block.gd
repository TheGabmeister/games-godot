extends "res://scripts/objects/block_base.gd"

const SpriteHelper := preload("res://scripts/visuals/sprite_region_helper.gd")
const SHEET := preload("res://sprites/blocks_sheet.png")
const COLUMNS := 6
const CoinScene := preload("res://scenes/objects/coin.tscn")
const MushroomScene := preload("res://scenes/objects/mushroom.tscn")
const FireFlowerScene := preload("res://scenes/objects/fire_flower.tscn")
const StarmanScene := preload("res://scenes/objects/starman.tscn")

@export var contents: StringName = &"coin"
@export var coin_sound: AudioStream

var _used: bool = false
var _pulse_time: float = 0.0
var _sprite: Sprite2D


func _ready() -> void:
	super._ready()
	_sprite = SpriteHelper.ensure_sprite(self, &"Sprite", SHEET)
	_update_sprite()


func _process(delta: float) -> void:
	super._process(delta)
	_pulse_time += delta
	_update_sprite()


func _update_sprite() -> void:
	var frame := 3 if _used else int(_pulse_time * bump_config.pulse_frequency * 3.0) % 3
	SpriteHelper.set_cell(_sprite, frame, COLUMNS, Vector2(-16, -26 + _bump_offset), Vector2(0.8, 0.8))


func bump_from_below() -> void:
	if _used:
		return
	_used = true
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
	if scene == null:
		return
	var item := scene.instantiate() as Node2D
	get_parent().add_child(item)
	item.global_position = spawn_pos
	EventBus.item_spawned.emit(item_type, spawn_pos)
