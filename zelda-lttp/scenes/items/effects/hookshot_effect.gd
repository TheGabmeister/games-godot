extends BaseItemEffect

const HOOKSHOT_SCENE := preload("res://scenes/items/hookshot.tscn")
const SAFETY_TIMEOUT := 5.0


func can_use(_player: CharacterBody2D) -> bool:
	return true


func activate(player: CharacterBody2D) -> float:
	var hook: Node2D = HOOKSHOT_SCENE.instantiate()
	hook.direction = player.facing_direction.normalized()
	hook.origin_player = player
	hook.global_position = player.global_position
	player.get_parent().add_child(hook)
	return SAFETY_TIMEOUT
