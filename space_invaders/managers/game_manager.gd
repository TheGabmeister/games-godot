extends Node

var _score: int = 0

func _enter_tree() -> void:
	GameEvents.enemy_killed.connect(_add_score)

func _exit_tree() -> void:
	GameEvents.enemy_killed.disconnect(_add_score)

func _add_score(value: int) -> void:
	_score += value
	GameEvents.update_score.emit(_score)
