extends CharacterBody2D

@export var speed: float = 200.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var facing := "down"

func _physics_process(_delta: float) -> void:
	var input := Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("move_up", "move_down")
	)

	if input.length() > 0:
		input = input.normalized()
		velocity = input * speed
		_update_facing(input)
		sprite.play("walk_" + facing)
	else:
		velocity = Vector2.ZERO
		sprite.play("idle_" + facing)

	move_and_slide()

func _update_facing(dir: Vector2) -> void:
	if absf(dir.x) > absf(dir.y):
		facing = "right" if dir.x > 0 else "left"
	else:
		facing = "down" if dir.y > 0 else "up"
