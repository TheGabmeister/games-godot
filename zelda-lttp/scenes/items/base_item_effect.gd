class_name BaseItemEffect extends RefCounted


func can_use(_player: CharacterBody2D) -> bool:
	return true


## Execute the item effect. Returns the duration (seconds) that
## ItemUseState should lock the player before returning to Idle.
func activate(_player: CharacterBody2D) -> float:
	return 0.0
