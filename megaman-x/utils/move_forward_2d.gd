extends Node

@export var _speed := 100.0

func _process(delta: float) -> void:
	# code here
	if owner:
		var direction = Vector2.RIGHT.rotated(owner.rotation)
		owner.position += direction * _speed * delta
	pass
