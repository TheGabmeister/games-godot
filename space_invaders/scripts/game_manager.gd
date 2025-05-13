extends Node

var _score: int = 0

func _enter_tree() -> void:
	GameEvents.enemy_killed.connect(_update_score)

func _exit_tree() -> void:
	GameEvents.enemy_killed.disconnect(_update_score)

func _update_score(value: int) -> void:
	_score += value
