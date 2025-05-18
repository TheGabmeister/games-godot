extends Node

@export var _player: PackedScene
@export var _player_spawn_point: Node2D
@export var _ghost: PackedScene
@export var _ghost_spawn_points: Array[Node2D]
var _score := 0
var _hi_score := 0

func _enter_tree():
	Bus.enemy_killed.connect(_add_score)
	Bus.game_reset_level.connect(_reset_level)

func _exit_tree():
	Bus.enemy_killed.disconnect(_add_score)
	Bus.game_reset_level.disconnect(_reset_level)

func _ready():
	_start_level()

func _start_level():
	
	var player: Node2D = _player.instantiate()
	player.position = _player_spawn_point.position
	player.rotation = 0
	get_tree().current_scene.add_child(player)
	
	for i in _ghost_spawn_points:
		var ghost: Node2D = _ghost.instantiate()
		ghost.position = _ghost_spawn_points[i].position
		ghost.rotation = 0
		get_tree().current_scene.add_child(ghost)

func _add_score(value: int):
	_score += value
	if _score > _hi_score:
		_hi_score = _score
		Bus.update_hi_score.emit(_hi_score)
	Bus.update_score.emit(_score)

func _reset_level():
	pass
