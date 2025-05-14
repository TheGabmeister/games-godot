extends Node2D

class_name Player

# Speed of the player in pixels per second
const SPEED := 200.0
const BOUNDARY := 350.0

func _process(delta):
	var direction := Vector2.ZERO

	if Input.is_action_pressed("move_right"):
		direction.x += 1
	if Input.is_action_pressed("move_left"):
		direction.x -= 1

	# make sure player doesn't go off screen
	if position.x > BOUNDARY:
		position.x = BOUNDARY
	if position.x < -BOUNDARY:
		position.x = -BOUNDARY

	if direction != Vector2.ZERO:
		direction = direction.normalized()
		position += direction * SPEED * delta
