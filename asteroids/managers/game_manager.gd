extends Node

var _score: int = 0
var _hi_score: int = 0

func _enter_tree() -> void:
	Bus.enemy_killed.connect(_add_score)

func _exit_tree() -> void:
	Bus.enemy_killed.disconnect(_add_score)

func _add_score(value: int) -> void:
	_score += value
	if _score > _hi_score:
		_hi_score = _score
		Bus.update_hi_score.emit(_hi_score)
	Bus.update_score.emit(_score)
