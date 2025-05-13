extends Node2D

const SCORE: int = 100

var movement_speed: float = 300.0
const VERTICAL_MOVEMENT: float = 30.0
const BOUNDARY: float = 350.0
static var direction: int = 1
static var has_moved_vertical: bool = false

func _ready() -> void:
	pass 

func _process(delta: float) -> void:
	if position.x > BOUNDARY:
		_move_vertical()
		direction = -1
	if position.x < -BOUNDARY:
		_move_vertical()
		direction = 1
	position.x += movement_speed * direction * delta

# when moving down, prevent other instances from triggering the group movement
func _move_vertical() -> void:
	if has_moved_vertical:
		return
	
	has_moved_vertical = true

	for enemy: Node2D in get_parent().get_children():
		if enemy.is_in_group("enemies"):
			enemy.position.y += VERTICAL_MOVEMENT

	call_deferred("_reset_has_moved_vertical")

func _reset_has_moved_vertical() -> void:
	has_moved_vertical = false

func die() -> void:
	EventBus.emit("player_scored", SCORE)
