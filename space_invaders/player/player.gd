extends Node2D
class_name Player

# Speed of the player in pixels per second
const SPEED: float = 200.0
const BOUNDARY: float = 350.0
const COOLDOWN: float = 1.0
var cooldown_remaining: float = 0.0
var bullet: PackedScene = preload("res://player/player_laser.tscn")

func _process(delta: float) -> void:
	var direction: Vector2 = Vector2.ZERO

	if Input.is_action_pressed("move_right"):
		direction.x += 1
	if Input.is_action_pressed("move_left"):
		direction.x -= 1

	# jump cooldown logic
	if cooldown_remaining > 0.0:
		cooldown_remaining -= delta
	if Input.is_action_just_pressed("jump") and cooldown_remaining <= 0.0:
		var bullet_inst: Node2D = bullet.instantiate()
		bullet_inst.position = position
		get_tree().current_scene.add_child(bullet_inst)
		cooldown_remaining = COOLDOWN

	# make sure player doesn't go off screen
	if position.x > BOUNDARY:
		position.x = BOUNDARY
	if position.x < -BOUNDARY:
		position.x = -BOUNDARY

	if direction != Vector2.ZERO:
		direction = direction.normalized()
		position += direction * SPEED * delta
