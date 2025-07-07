extends Node

@export var _player: PackedScene
@export var _asteroids: Array[PackedScene]
@export var _spawn_point_parent: Node2D
@export var _revive_time := 3.0
var _score := 0
var _hi_score := 0

@onready var _spawn_points = _spawn_point_parent.get_children()

func _enter_tree():
	Bus.enemy_killed.connect(_add_score)
	Bus.player_killed.connect(_revive_player)

func _exit_tree():
	Bus.enemy_killed.disconnect(_add_score)
	Bus.player_killed.disconnect(_revive_player)

func _ready():
	await get_tree().create_timer(1.0).timeout
	_spawn_asteroids()
	

func _add_score(value: int):
	_score += value
	if _score > _hi_score:
		_hi_score = _score
		Bus.update_hi_score.emit(_hi_score)
	Bus.update_score.emit(_score)

func _revive_player():
	await get_tree().create_timer(_revive_time).timeout
	var player_inst: Node2D = _player.instantiate()
	player_inst.position = Vector2(GlobalVars.SCREEN_WIDTH/2, GlobalVars.SCREEN_HEIGHT/2)
	player_inst.rotation = 0
	get_tree().current_scene.add_child(player_inst)

func _spawn_asteroids():
	for asteroid in _asteroids:
		var spawn_point = _spawn_points[randi() % _spawn_points.size()]
		var instance = asteroid.instantiate()
		instance.position = spawn_point.position
		instance.rotation = randf() * TAU
		get_tree().current_scene.add_child(instance)
