extends Node2D

var speed = 200

func _process(delta):
	position.y -= speed * delta

func _on_area_2d_area_entered(area: Area2D) -> void:
	pass # Replace with function body.
