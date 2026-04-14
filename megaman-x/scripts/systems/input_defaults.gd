extends RefCounted
class_name InputDefaults


static func ensure_default_input_map() -> void:
	_ensure_move_left()
	_ensure_move_right()
	_ensure_jump()
	_ensure_dash()
	_ensure_shoot()
	_ensure_interact()
	_ensure_weapon_next()
	_ensure_weapon_prev()
	_ensure_sub_tank_use()
	_ensure_pause()
	_ensure_menu_confirm()
	_ensure_menu_cancel()


static func _ensure_move_left() -> void:
	if not _prepare_action(&"move_left"):
		return

	_add_key_event(&"move_left", KEY_A)
	_add_key_event(&"move_left", KEY_LEFT)
	_add_joy_button_event(&"move_left", JOY_BUTTON_DPAD_LEFT)
	_add_joy_axis_event(&"move_left", JOY_AXIS_LEFT_X, -1.0)


static func _ensure_move_right() -> void:
	if not _prepare_action(&"move_right"):
		return

	_add_key_event(&"move_right", KEY_D)
	_add_key_event(&"move_right", KEY_RIGHT)
	_add_joy_button_event(&"move_right", JOY_BUTTON_DPAD_RIGHT)
	_add_joy_axis_event(&"move_right", JOY_AXIS_LEFT_X, 1.0)


static func _ensure_jump() -> void:
	if not _prepare_action(&"jump"):
		return

	_add_key_event(&"jump", KEY_SPACE)
	_add_joy_button_event(&"jump", JOY_BUTTON_A)


static func _ensure_dash() -> void:
	if not _prepare_action(&"dash"):
		return

	_add_key_event(&"dash", KEY_K)
	_add_joy_button_event(&"dash", JOY_BUTTON_B)


static func _ensure_shoot() -> void:
	if not _prepare_action(&"shoot"):
		return

	_add_key_event(&"shoot", KEY_J)
	_add_joy_button_event(&"shoot", JOY_BUTTON_X)


static func _ensure_interact() -> void:
	if not _prepare_action(&"interact"):
		return

	_add_key_event(&"interact", KEY_E)
	_add_key_event(&"interact", KEY_ENTER)
	_add_joy_button_event(&"interact", JOY_BUTTON_Y)


static func _ensure_weapon_next() -> void:
	if not _prepare_action(&"weapon_next"):
		return

	_add_key_event(&"weapon_next", KEY_E)
	_add_key_event(&"weapon_next", KEY_PAGEUP)
	_add_joy_button_event(&"weapon_next", JOY_BUTTON_RIGHT_SHOULDER)


static func _ensure_weapon_prev() -> void:
	if not _prepare_action(&"weapon_prev"):
		return

	_add_key_event(&"weapon_prev", KEY_Q)
	_add_key_event(&"weapon_prev", KEY_PAGEDOWN)
	_add_joy_button_event(&"weapon_prev", JOY_BUTTON_LEFT_SHOULDER)


static func _ensure_sub_tank_use() -> void:
	if not _prepare_action(&"sub_tank_use"):
		return

	_add_key_event(&"sub_tank_use", KEY_V)
	_add_key_event(&"sub_tank_use", KEY_TAB)
	_add_joy_button_event(&"sub_tank_use", JOY_BUTTON_BACK)


static func _ensure_pause() -> void:
	if not _prepare_action(&"pause"):
		return

	_add_key_event(&"pause", KEY_ESCAPE)
	_add_joy_button_event(&"pause", JOY_BUTTON_START)


static func _ensure_menu_confirm() -> void:
	if not _prepare_action(&"menu_confirm"):
		return

	_add_key_event(&"menu_confirm", KEY_ENTER)
	_add_key_event(&"menu_confirm", KEY_SPACE)
	_add_joy_button_event(&"menu_confirm", JOY_BUTTON_A)


static func _ensure_menu_cancel() -> void:
	if not _prepare_action(&"menu_cancel"):
		return

	_add_key_event(&"menu_cancel", KEY_ESCAPE)
	_add_key_event(&"menu_cancel", KEY_BACKSPACE)
	_add_joy_button_event(&"menu_cancel", JOY_BUTTON_B)


static func _prepare_action(action_name: StringName) -> bool:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)

	if not InputMap.action_get_events(action_name).is_empty():
		return false

	return true


static func _add_key_event(action_name: StringName, keycode: Key) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = keycode
	InputMap.action_add_event(action_name, event)


static func _add_joy_button_event(action_name: StringName, button_index: JoyButton) -> void:
	var event := InputEventJoypadButton.new()
	event.button_index = button_index
	InputMap.action_add_event(action_name, event)


static func _add_joy_axis_event(action_name: StringName, axis: JoyAxis, axis_value: float) -> void:
	var event := InputEventJoypadMotion.new()
	event.axis = axis
	event.axis_value = axis_value
	InputMap.action_add_event(action_name, event)
