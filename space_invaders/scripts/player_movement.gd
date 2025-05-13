extends Node2D

# Speed of the player in pixels per second
const SPEED := 200
const BOUNDARY := 350
const COOLDOWN := 1
var cooldown_remaining := 0.0
var bullet = preload("res://scenes/player_laser.tscn")

func _process(delta):
	var direction := Vector2.ZERO

	if Input.is_action_pressed("move_right"):
		direction.x += 1
	if Input.is_action_pressed("move_left"):
		direction.x -= 1

	# jump cooldown logic
	if cooldown_remaining > 0.0:
		cooldown_remaining -= delta
	if Input.is_action_just_pressed("jump") and cooldown_remaining <= 0.0:
		var bullet_inst = bullet.instantiate()
		bullet_inst.position = position
		get_tree().root.add_child(bullet_inst)
		cooldown_remaining = COOLDOWN

	# make sure player doesn't go off screen
	if position.x > BOUNDARY:
		position.x = BOUNDARY
	if position.x < -BOUNDARY:
		position.x = -BOUNDARY

	if direction != Vector2.ZERO:
		direction = direction.normalized()
		position += direction * SPEED * delta
