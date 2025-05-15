extends Node

@export var _player: PackedScene
var _score := 0
var _hi_score := 0

func _enter_tree():
	Bus.enemy_killed.connect(_add_score)
	Bus.player_killed.connect(_revive_player)

func _exit_tree():
	Bus.enemy_killed.disconnect(_add_score)
	Bus.player_killed.disconnect(_revive_player)

func _add_score(value: int):
	_score += value
	if _score > _hi_score:
		_hi_score = _score
		Bus.update_hi_score.emit(_hi_score)
	Bus.update_score.emit(_score)

func _revive_player():
	await get_tree().create_timer(GlobalVars.PLAYER_SPAWN_TIMER).timeout
	var player_inst: Node2D = _player.instantiate()
	player_inst.position = Vector2(GlobalVars.SCREEN_WIDTH/2, GlobalVars.SCREEN_HEIGHT/2)
	player_inst.rotation = 0
	get_tree().current_scene.add_child(player_inst)
