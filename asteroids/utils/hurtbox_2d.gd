extends Node2D

func _on_area_2d_area_entered(area: Area2D):
	if area.has_method("on_hit"):
		area.on_hit()
	else:
		@warning_ignore("assert_always_true")
		assert("No 'on_hit' method. Check collision logic.")
	queue_free()
