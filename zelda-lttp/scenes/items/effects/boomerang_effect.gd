extends BaseItemEffect

const BOOMERANG_SCENE := preload("res://scenes/items/boomerang.tscn")
const LOCK_DURATION := 0.3


func can_use(_player: CharacterBody2D) -> bool:
	return true


func activate(player: CharacterBody2D) -> float:
	var boom: Area2D = BOOMERANG_SCENE.instantiate()
	boom.origin_player = player
	boom.direction = player.facing_direction.normalized()
	boom.global_position = player.global_position + player.facing_direction * 6.0
	player.get_parent().add_child(boom)
	return LOCK_DURATION
