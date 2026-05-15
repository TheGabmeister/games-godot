@tool
class_name Door
extends StaticBody2D

enum DoorType { BLUE, RED, GRAY }
enum Facing { LEFT, RIGHT, UP, DOWN }

@export var door_id: StringName = &""
@export var door_type: DoorType = DoorType.BLUE:
	set(v):
		door_type = v
		if is_node_ready():
			_update_sprite()
@export var facing: Facing = Facing.RIGHT:
	set(v):
		facing = v
		if is_node_ready():
			_setup_orientation()
@export_file("*.tscn") var target_scene_path: String = ""
@export var target_door_id: StringName = &""

@export_group("Gray Door")
@export var enemy_group: StringName = &""

@export_group("Audio")
@export var open_sfx: AudioStream
@export var close_sfx: AudioStream

var is_open: bool = false
var effective_type: DoorType
var _missile_hits: int = 0

const MISSILES_TO_OPEN_RED: int = 5
const MISSILE_DAMAGE_MIN: int = 100

var _blue_closed: Texture2D = preload("res://props/doors/door_blue_closed.png")
var _blue_open: Texture2D = preload("res://props/doors/door_blue_open.png")
var _red_closed: Texture2D = preload("res://props/doors/door_red_closed.png")
var _red_open: Texture2D = preload("res://props/doors/door_red_open.png")
var _gray_closed: Texture2D = preload("res://props/doors/door_gray_closed.png")
var _gray_open: Texture2D = preload("res://props/doors/door_gray_open.png")

@onready var _sprite: Sprite2D = $DoorSprite
@onready var _block_shape: CollisionShape2D = $BlockCollision
@onready var _hitbox: Area2D = $Hitbox
@onready var _trigger: Area2D = $Trigger


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0

	if Engine.is_editor_hint():
		effective_type = door_type
		_setup_orientation()
		_update_sprite()
		return

	effective_type = _resolve_type()
	_setup_trigger_position()
	_setup_orientation()
	if facing == Facing.UP or facing == Facing.DOWN:
		_rotate_shape(_block_shape)
		_rotate_shape(_hitbox.get_child(0) as CollisionShape2D)
		_rotate_shape(_trigger.get_child(0) as CollisionShape2D)
	_update_sprite()
	var _e1 := _hitbox.area_entered.connect(_on_hitbox_area_entered)
	var _e2 := _trigger.body_entered.connect(_on_trigger_body_entered)
	if effective_type == DoorType.GRAY and enemy_group != &"":
		_track_enemies.call_deferred()


func _resolve_type() -> DoorType:
	var key := _persistence_key()
	if GameManager.door_states.has(key):
		@warning_ignore("unsafe_cast")
		var stored: DoorType = GameManager.door_states[key] as DoorType
		return stored
	return door_type


func _persistence_key() -> String:
	return owner.scene_file_path + ":" + String(door_id)


func _setup_trigger_position() -> void:
	var trigger_shape: CollisionShape2D = _trigger.get_child(0)
	match facing:
		Facing.LEFT:
			trigger_shape.position = Vector2(-24, 0)
		Facing.RIGHT:
			trigger_shape.position = Vector2(24, 0)
		Facing.UP:
			trigger_shape.position = Vector2(0, -24)
		Facing.DOWN:
			trigger_shape.position = Vector2(0, 24)


func _setup_orientation() -> void:
	_sprite.flip_h = facing == Facing.LEFT
	if facing == Facing.UP or facing == Facing.DOWN:
		_sprite.rotation_degrees = 90.0
	else:
		_sprite.rotation_degrees = 0.0


func _rotate_shape(shape_node: CollisionShape2D) -> void:
	var rect := shape_node.shape as RectangleShape2D
	var rotated := rect.duplicate() as RectangleShape2D
	rotated.size = Vector2(rect.size.y, rect.size.x)
	shape_node.shape = rotated


func open_door() -> void:
	if is_open:
		return
	is_open = true
	_block_shape.set_deferred(&"disabled", true)
	_update_sprite()
	if open_sfx:
		SfxManager.play(open_sfx)


func close_door() -> void:
	if not is_open:
		return
	is_open = false
	_block_shape.set_deferred(&"disabled", false)
	_update_sprite()
	if close_sfx:
		SfxManager.play(close_sfx)


func _update_sprite() -> void:
	var display_type := effective_type if not Engine.is_editor_hint() else door_type
	match display_type:
		DoorType.BLUE:
			_sprite.texture = _blue_open if is_open else _blue_closed
		DoorType.RED:
			_sprite.texture = _red_open if is_open else _red_closed
		DoorType.GRAY:
			_sprite.texture = _gray_open if is_open else _gray_closed


func _on_hitbox_area_entered(area: Area2D) -> void:
	if is_open or GameManager.transitioning:
		return
	if not area is Projectile:
		return
	var proj := area as Projectile
	match effective_type:
		DoorType.BLUE:
			open_door()
		DoorType.RED:
			if proj.damage >= MISSILE_DAMAGE_MIN:
				_missile_hits += 1
				if _missile_hits >= MISSILES_TO_OPEN_RED:
					_persist_as_blue()
					open_door()
		DoorType.GRAY:
			pass


func _on_trigger_body_entered(body: Node2D) -> void:
	if not is_open or GameManager.transitioning:
		return
	if not body is Player:
		return
	if target_scene_path.is_empty():
		return
	GameManager.start_transition(target_scene_path, target_door_id, facing)


func _persist_as_blue() -> void:
	effective_type = DoorType.BLUE
	var key := _persistence_key()
	GameManager.door_states[key] = DoorType.BLUE


func _track_enemies() -> void:
	var enemies := get_tree().get_nodes_in_group(enemy_group)
	if enemies.is_empty():
		open_door()
		return
	for enemy: Node in enemies:
		var _e := enemy.tree_exited.connect(_on_tracked_enemy_exited)


func _on_tracked_enemy_exited() -> void:
	_check_enemies.call_deferred()


func _check_enemies() -> void:
	var remaining := get_tree().get_nodes_in_group(enemy_group)
	if remaining.is_empty():
		open_door()
