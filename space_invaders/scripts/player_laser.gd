extends Node2D

var speed = 300

func _process(delta):
	position.y -= speed * delta

func _on_area_2d_area_entered(area: Area2D) -> void:
	if area.is_in_group("enemies"):
		area.get_parent().queue_free()
		queue_free()
