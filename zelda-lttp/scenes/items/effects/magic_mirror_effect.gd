class_name MagicMirrorEffect extends BaseItemEffect


func can_use(player: CharacterBody2D) -> bool:
	# Can only use in the Dark World
	if not SceneManager.current_room_data:
		return false
	return SceneManager.current_room_data.world_type == &"dark"


func activate(player: CharacterBody2D) -> float:
	EventBus.world_switch_requested.emit(&"light")
	return 0.0  # No lock duration — transition handles timing
