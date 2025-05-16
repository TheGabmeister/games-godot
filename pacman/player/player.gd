extends Node2D
class_name Player

@export var _speed := 300.0
@export var _rotation_speed := 5.0
@export var _cooldown := 0.2
@export var _shot: PackedScene
@export var _shot_sound: AudioStream
@export var _death_sound: AudioStream

@onready var _cooldown_base := _cooldown

func _process(delta):

	if Input.is_action_pressed("move_right"):
		rotation += _rotation_speed * delta
	if Input.is_action_pressed("move_left"):
		rotation -= _rotation_speed * delta
	if Input.is_action_pressed("move_up"):
		position += Vector2.RIGHT.rotated(rotation) * _speed * delta
	if Input.is_action_pressed("move_down"):
		position -= Vector2.RIGHT.rotated(rotation) * _speed * delta

	if Input.is_action_pressed("fire") && _cooldown <= 0:
		var shot_inst := _shot.instantiate()
		shot_inst.position = position
		shot_inst.rotation = rotation
		get_tree().current_scene.add_child(shot_inst)
		Bus.sfx_play_sound.emit(_shot_sound)
		_cooldown = _cooldown_base
	elif _cooldown > 0:
		_cooldown -= delta


func _on_area_2d_area_entered(_area: Area2D):
	Bus.player_killed.emit()
	Bus.sfx_play_sound.emit(_death_sound)
	queue_free()
