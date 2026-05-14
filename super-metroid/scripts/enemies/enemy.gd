class_name Enemy
extends CharacterBody2D

@export var hp: int = 30
@export var contact_damage: int = 10
@export var gravity: float = 900.0

var _dead: bool = false

var drop_table: Array[Dictionary] = [
	{"type": "nothing", "weight": 40},
	{"type": "small_energy", "weight": 15},
	{"type": "large_energy", "weight": 15},
	{"type": "missile", "weight": 15},
	{"type": "super_missile", "weight": 8},
	{"type": "power_bomb", "weight": 7},
]


func _ready() -> void:
	collision_layer = 4
	collision_mask = 1
	var area := Area2D.new()
	area.collision_layer = 4
	area.collision_mask = 2
	var shape := CollisionShape2D.new()
	shape.shape = _get_hitbox_shape()
	area.add_child(shape)
	add_child(area)
	var _err := area.body_entered.connect(_on_body_entered)


func _get_hitbox_shape() -> Shape2D:
	var rect := RectangleShape2D.new()
	rect.size = Vector2(24, 24)
	return rect


func take_damage(amount: int, _source_position: Vector2 = Vector2.ZERO) -> void:
	if _dead:
		return
	hp -= amount
	SfxManager.play(preload("res://enemies/audio/enemy_hit.ogg"))
	if hp <= 0:
		die()


func die() -> void:
	if _dead:
		return
	_dead = true
	SfxManager.play(preload("res://enemies/audio/enemy_death.ogg"))
	_spawn_drop()
	queue_free()


func _spawn_drop() -> void:
	var roll := randf() * 100.0
	var cumulative := 0.0
	for entry: Dictionary in drop_table:
		var weight: int = entry["weight"]
		cumulative += float(weight)
		if roll <= cumulative:
			var drop_type: String = entry["type"]
			if drop_type == "nothing":
				return
			_create_drop(drop_type)
			return


func _create_drop(drop_type: String) -> void:
	var drop_scene: PackedScene = _get_drop_scene(drop_type)
	if not drop_scene:
		return
	var drop: Node2D = drop_scene.instantiate()
	drop.global_position = global_position
	get_parent().call_deferred("add_child", drop)


func _get_drop_scene(drop_type: String) -> PackedScene:
	match drop_type:
		"small_energy":
			return preload("res://scenes/pickups/pickup_small_energy.tscn")
		"large_energy":
			return preload("res://scenes/pickups/pickup_large_energy.tscn")
		"missile":
			return preload("res://scenes/pickups/pickup_missile.tscn")
	return null


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		(body as Player).take_damage(contact_damage, global_position)
