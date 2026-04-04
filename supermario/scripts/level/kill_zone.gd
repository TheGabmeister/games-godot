extends Area2D


func _ready() -> void:
	collision_layer = 512  # Layer 9 (KillZone)
	collision_mask = 2 | 4  # Layer 2 (Player) + Layer 3 (Enemies)
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if body.has_method("die"):
		body.die()
	else:
		body.queue_free()
