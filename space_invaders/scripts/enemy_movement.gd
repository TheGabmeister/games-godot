extends Node2D

var movement_speed := 300.0
const VERTICAL_MOVEMENT := 30
const BOUNDARY := 350
static var direction := 1
static var has_moved_vertical := false

func _ready() -> void:
	pass 

func _process(delta: float) -> void:
	if (position.x > BOUNDARY):
		_move_vertical()
		direction = -1
	if position.x < -BOUNDARY:
		_move_vertical()
		direction = 1
	position.x += movement_speed * direction * delta

# when moving down, prevent other instances from triggering the group movement
func _move_vertical():
	if has_moved_vertical:
		return
	
	has_moved_vertical = true
	for enemy in get_parent().get_children():
		if enemy.is_in_group("enemies"):
			enemy.position.y += VERTICAL_MOVEMENT
	call_deferred("_reset_has_moved_vertical")

func _reset_has_moved_vertical():
	has_moved_vertical = false
