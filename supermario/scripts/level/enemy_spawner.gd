extends Node2D

const ACTIVATION_DISTANCE := 320.0
const CLEANUP_DISTANCE := 320.0


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
				# Activate when within range of camera right edge
				if child.global_position.x < cam_right + ACTIVATION_DISTANCE:
					child.activate()
			else:
				# Clean up enemies far behind the camera
				if child.global_position.x < cam_left - CLEANUP_DISTANCE:
					child.queue_free()
