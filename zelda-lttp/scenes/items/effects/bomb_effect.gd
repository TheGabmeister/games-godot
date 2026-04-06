extends BaseItemEffect

const BOMB_SCENE := preload("res://scenes/items/bomb.tscn")
const LOCK_DURATION := 0.2


func can_use(player: CharacterBody2D) -> bool:
	return PlayerState.bombs > 0


func activate(player: CharacterBody2D) -> float:
	var bomb: Node2D = BOMB_SCENE.instantiate()
	bomb.global_position = player.global_position
	player.get_parent().add_child(bomb)
	return LOCK_DURATION
