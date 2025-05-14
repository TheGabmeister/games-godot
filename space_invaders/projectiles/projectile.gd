extends Node2D

@export var speed: float = 300.0
@export var target_group: String = ""

func _process(delta: float) -> void:
	position.y += speed * delta

func _on_area_2d_area_entered(area: Area2D) -> void:
	if area.get_parent().has_meta(IHittable.IHITTABLE):
		var i: IHittable = area.get_parent().get_meta(IHittable.IHITTABLE)
		i.on_hit(self)
	queue_free()
