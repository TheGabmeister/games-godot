extends Node2D
class_name Player

@export var _speed := 300.0
@export var _rotation_speed := 5.0
@export var _cooldown := 1.0
@export var _shot: PackedScene

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
		_cooldown = 1.0
	elif _cooldown > 0:
		_cooldown -= delta


func _on_hitbox_area_entered():
	# die
	pass
