extends BasePlayerState

var _item: ItemData = null
var _auto_dismiss_timer: float = -1.0
var _dismissed: bool = false


func enter(msg: Dictionary = {}) -> void:
	super.enter(msg)
	_item = msg.get("item", null) as ItemData
	_dismissed = false
	player.velocity = Vector2.ZERO

	if not _item:
		state_machine.transition_to(&"Idle")
		return

	# Pause the game
	player.get_tree().paused = true

	# Trigger visual: arms-up pose
	player.set_meta("item_get_active", true)
	player.set_meta("item_get_data", _item)
	player.player_body.queue_redraw()

	# Play fanfare
	if _item.item_type == ItemData.ItemType.RESOURCE:
		AudioManager.play_sfx(&"item_fanfare_minor")
	else:
		AudioManager.play_sfx(&"item_fanfare")

	# Show dialog — dialog_box owns the close and emits dialog_closed
	var text: String = "You got the %s! %s" % [_item.display_name, _item.description]
	EventBus.dialog_requested.emit([text])

	# Auto-dismiss for minor chest resources
	var auto_dismiss: bool = msg.get("auto_dismiss", false)
	if auto_dismiss:
		_auto_dismiss_timer = 1.5
	else:
		_auto_dismiss_timer = -1.0

	# Await dialog_closed from the dialog box (single emitter)
	EventBus.dialog_closed.connect(_on_dialog_closed, CONNECT_ONE_SHOT)


func update(delta: float) -> void:
	super.update(delta)
	if _dismissed:
		return

	if _auto_dismiss_timer > 0.0:
		_auto_dismiss_timer -= delta
		if _auto_dismiss_timer <= 0.0:
			# Force-close the dialog — dialog_box will emit dialog_closed
			EventBus.dialog_force_close.emit()


func handle_input(_event: InputEvent) -> void:
	# Do not intercept interact — let dialog_box handle it and emit dialog_closed
	pass


func _on_dialog_closed() -> void:
	if _dismissed:
		return
	_dismissed = true
	if _item:
		PlayerState.acquire(_item)
	player.get_tree().paused = false

	player.remove_meta("item_get_active")
	player.remove_meta("item_get_data")
	player.player_body.queue_redraw()

	state_machine.transition_to(&"Idle")


func exit() -> void:
	# Safety cleanup — disconnect if still connected
	if EventBus.dialog_closed.is_connected(_on_dialog_closed):
		EventBus.dialog_closed.disconnect(_on_dialog_closed)
	if player.get_tree().paused:
		player.get_tree().paused = false
	if player.has_meta("item_get_active"):
		player.remove_meta("item_get_active")
		player.remove_meta("item_get_data")
		player.player_body.queue_redraw()
