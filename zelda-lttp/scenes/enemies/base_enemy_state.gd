class_name BaseEnemyState extends State

var actor: BaseEnemy


func enter(_msg: Dictionary = {}) -> void:
	if not actor and owner:
		actor = owner as BaseEnemy
