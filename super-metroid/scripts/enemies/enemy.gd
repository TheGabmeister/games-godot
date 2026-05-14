class_name Enemy
extends CharacterBody2D

@export var hp: int = 30
@export var contact_damage: int = 10
@export var gravity: float = 900.0

@export_group("Audio")
@export var hit_sfx: AudioStream = preload("res://enemies/audio/enemy_hit.ogg")
@export var death_sfx: AudioStream = preload("res://enemies/audio/enemy_death.ogg")

@export_group("Drops")
@export var drop_table: Array[DropEntry] = []

var _dead: bool = false


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
	SfxManager.play(hit_sfx)
	if hp <= 0:
		die()


func die() -> void:
	if _dead:
		return
	_dead = true
	SfxManager.play(death_sfx)
	_spawn_drop()
	queue_free()


func _spawn_drop() -> void:
	var roll := randf() * 100.0
	var cumulative := 0.0
	for entry: DropEntry in drop_table:
		cumulative += float(entry.weight)
		if roll <= cumulative:
			if entry.type == DropEntry.DropType.NOTHING or not entry.scene:
				return
			var drop: Node2D = entry.scene.instantiate()
			drop.global_position = global_position
			get_parent().call_deferred(&"add_child", drop)
			return


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		(body as Player).take_damage(contact_damage, global_position)
