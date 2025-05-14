extends Node2D
class_name Player

const SPEED := 300.0
const ROTATION_SPEED := 5.0
const COOLDOWN := 1.0
var _cooldown_remaining := 1.0
#var bullet: PackedScene = preload("res://player/player_laser.tscn")

func _process(delta):

	if Input.is_action_pressed("move_right"):
		rotation += ROTATION_SPEED * delta
	if Input.is_action_pressed("move_left"):
		rotation -= ROTATION_SPEED * delta
	if Input.is_action_pressed("move_up"):
		position += Vector2.UP.rotated(rotation) * SPEED * delta
	if Input.is_action_pressed("move_down"):
		position -= Vector2.UP.rotated(rotation) * SPEED * delta

	if _cooldown_remaining > 0:
		_cooldown_remaining -= delta
	if Input.is_action_pressed("fire") && _cooldown_remaining < 0:
		print("Fired")
		_cooldown_remaining = COOLDOWN
