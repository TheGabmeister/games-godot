class_name MagicMirrorEffect extends BaseItemEffect


func can_use(player: CharacterBody2D) -> bool:
	# Can only use in the Dark World
	if not SceneManager.current_room_data:
		return false
	return SceneManager.current_room_data.world_type == &"dark"


func activate(player: CharacterBody2D) -> float:
	EventBus.world_switch_requested.emit(&"light")
	# Return enough lock time to cover the fade-out + load + fade-in transition.
	# SceneManager.switch_world() disables player control separately, so this just
	# keeps ItemUseState from dropping back to Idle mid-transition.
	return 2.0
