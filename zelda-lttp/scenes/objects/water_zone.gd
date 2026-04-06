extends Area2D

## Place as an Area2D with collision_layer=128 (Triggers), collision_mask=2 (Player).
## When the player enters, calls player.set_in_water(true).
## When the player exits, calls player.set_in_water(false).


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node) -> void:
	if body is Player:
		(body as Player).set_in_water(true)


func _on_body_exited(body: Node) -> void:
	if body is Player:
		(body as Player).set_in_water(false)
