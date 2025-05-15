extends Node

func _on_area_2d_area_entered(_area: Node2D) -> void:
	queue_free()
