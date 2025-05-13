extends Node2D

@export var speed = 300.0
@export var target_group = ""

func _process(delta):
	position.y += speed * delta

func _on_area_2d_area_entered(area: Area2D) -> void:
	if target_group == "":
		return
	else:
		if area.is_in_group(target_group):
			area.get_parent().queue_free()
			queue_free()
