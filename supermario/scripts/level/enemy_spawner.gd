extends Node2D

@export var activation_distance: float = 640.0
@export var cleanup_distance: float = 640.0


func _process(_delta: float) -> void:
	var camera := get_viewport().get_camera_2d()
	if not camera:
		return
	var cam_center_x := camera.get_screen_center_position().x
	var viewport_half := get_viewport_rect().size.x / camera.zoom.x / 2.0
	var cam_right := cam_center_x + viewport_half
	var cam_left := cam_center_x - viewport_half

	for child in get_children():
		if not is_instance_valid(child):
			continue
		if child.has_method("activate") and child.has_method("is_active"):
			if not child.is_active():
				if child.global_position.x < cam_right + activation_distance:
					child.activate()
			else:
				if child.global_position.x < cam_left - cleanup_distance:
					child.queue_free()
