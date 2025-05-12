extends Node2D

# Speed of the player in pixels per second
var speed := 200
var boundary := 350

func _process(delta):
	var direction := Vector2.ZERO
	if Input.is_action_pressed("ui_right"):
		direction.x += 1
	if Input.is_action_pressed("ui_left"):
		direction.x -= 1

	if position.x > boundary:
		position.x = boundary
	if position.x < -boundary:
		position.x = -boundary

	if direction != Vector2.ZERO:
		direction = direction.normalized()
		position += direction * speed * delta
