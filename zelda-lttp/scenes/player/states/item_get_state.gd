extends BasePlayerState

var _item: ItemData = null
var _auto_dismiss_timer: float = -1.0
var _waiting_for_dismiss: bool = false


func enter(msg: Dictionary = {}) -> void:
	super.enter(msg)
	_item = msg.get("item", null) as ItemData
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

	# Show dialog
	var text: String = "You got the %s! %s" % [_item.display_name, _item.description]
	EventBus.dialog_requested.emit([text])

	# Auto-dismiss for minor chest resources
	var auto_dismiss: bool = msg.get("auto_dismiss", false)
	if auto_dismiss:
		_auto_dismiss_timer = 1.5
	else:
		_auto_dismiss_timer = -1.0

	_waiting_for_dismiss = true


func update(delta: float) -> void:
	super.update(delta)
	if not _waiting_for_dismiss:
		return

	if _auto_dismiss_timer > 0.0:
		_auto_dismiss_timer -= delta
		if _auto_dismiss_timer <= 0.0:
			_dismiss()


func handle_input(event: InputEvent) -> void:
	if not _waiting_for_dismiss:
		return
	if event.is_action_pressed("interact") or event.is_action_pressed("action_sword"):
		_dismiss()


func _dismiss() -> void:
	_waiting_for_dismiss = false
	if _item:
		PlayerState.acquire(_item)
	player.get_tree().paused = false
	EventBus.dialog_closed.emit()

	player.remove_meta("item_get_active")
	player.remove_meta("item_get_data")
	player.player_body.queue_redraw()

	state_machine.transition_to(&"Idle")


func exit() -> void:
	if player.get_tree().paused:
		player.get_tree().paused = false
	if player.has_meta("item_get_active"):
		player.remove_meta("item_get_active")
		player.remove_meta("item_get_data")
		player.player_body.queue_redraw()
