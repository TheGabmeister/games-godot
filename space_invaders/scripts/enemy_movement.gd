extends Node2D

var movement_speed := 300.0
const BOUNDARY := 350
static var direction := 1

func _ready() -> void:
	pass 

func _process(delta: float) -> void:
	if (position.x > BOUNDARY):
		direction = -1
	if (position.x < -BOUNDARY):
		direction = 1
	position.x += movement_speed * direction * delta
