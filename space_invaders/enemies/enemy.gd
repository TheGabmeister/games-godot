class_name Enemy
extends Node2D

const SCORE: int = 100
var movement_speed: float = 300.0
const VERTICAL_MOVEMENT: float = 30.0
const BOUNDARY: float = 700.0
static var _direction: int = 1
static var _has_moved_vertical: bool = false

func _process(delta: float) -> void:
	if position.x > BOUNDARY:
		_move_vertical()
		_direction = -1
	if position.x < 0:
		_move_vertical()
		_direction = 1
	position.x += movement_speed * _direction * delta

# when moving down, prevent other instances from triggering the group movement
func _move_vertical() -> void:
	if _has_moved_vertical:
		return
	
	_has_moved_vertical = true

	var enemies: Array = get_parent().get_children().filter(func(n: Node) -> bool: return n is Enemy)
	for enemy: Enemy in enemies:
		enemy.position.y += VERTICAL_MOVEMENT

	call_deferred("_reset_has_moved_vertical")

func _reset_has_moved_vertical() -> void:
	_has_moved_vertical = false

func on_hit(_instigator: Node) -> void:
	GameEvents.enemy_killed.emit(SCORE)
	queue_free()
