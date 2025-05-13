extends Node2D

@export var speed: float = 300.0
@export var target_group: String = ""

func _process(delta: float) -> void:
	position.y += speed * delta

func _on_area_2d_area_entered(area: Area2D) -> void:
	if target_group == "":
		return
	else:
		if area.is_in_group(target_group):
			area.get_parent().queue_free()
			queue_free()
