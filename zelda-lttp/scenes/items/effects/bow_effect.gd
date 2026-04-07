extends BaseItemEffect

const ARROW_SCENE := preload("res://scenes/items/arrow.tscn")
const LOCK_DURATION := 0.3


func can_use(player: CharacterBody2D) -> bool:
	return PlayerState.arrows > 0


func activate(player: CharacterBody2D) -> float:
	AudioManager.play_sfx(&"arrow_fire")
	var arrow: Area2D = ARROW_SCENE.instantiate()
	arrow.direction = player.facing_direction.normalized()
	arrow.global_position = player.global_position + player.facing_direction * 8.0
	player.get_parent().add_child(arrow)
	return LOCK_DURATION
