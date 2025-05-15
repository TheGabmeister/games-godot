extends Node2D

func _on_area_2d_area_entered(area: Area2D):
	if area.has_method("on_hit"):
		area.on_hit()
	queue_free()
