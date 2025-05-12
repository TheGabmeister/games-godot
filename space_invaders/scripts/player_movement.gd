extends Node2D

# Speed of the player in pixels per second
var speed := 200
var boundary := 350
var cooldown := 1
var cooldown_remaining := 0.0

func _process(delta):
	var direction := Vector2.ZERO

	if Input.is_action_pressed("move_right"):
		direction.x += 1
	if Input.is_action_pressed("move_left"):
		direction.x -= 1

	# Jump cooldown logic
	

	if cooldown_remaining > 0.0:
		cooldown_remaining -= delta

	if Input.is_action_just_pressed("jump") and cooldown_remaining <= 0.0:
		print("Hello World")
		cooldown_remaining = cooldown

	if position.x > boundary:
		position.x = boundary
	if position.x < -boundary:
		position.x = -boundary

	if direction != Vector2.ZERO:
		direction = direction.normalized()
		position += direction * speed * delta
