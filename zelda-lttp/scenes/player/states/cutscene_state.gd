extends BasePlayerState

## Player state during cutscenes. Input is disabled; the player holds position.
## Cutscene scripts can move the player via Cutscene.move_entity().


func enter(msg: Dictionary = {}) -> void:
	super.enter(msg)
	player.velocity = Vector2.ZERO


func handle_input(_event: InputEvent) -> void:
	# All input blocked during cutscenes
	pass


func physics_update(_delta: float) -> void:
	# No movement
	pass
