class_name MenuScreen
extends Node

var party_data: PartyData
var menu: MainMenu
var cursor_move_sfx: AudioStream
var confirm_sfx: AudioStream
var cancel_sfx: AudioStream

var _active := false
var _cursor_index := 0

func open() -> void:
	_active = true
	_cursor_index = 0
	_on_open()

func _on_open() -> void:
	pass

func close() -> void:
	_active = false
	menu.return_to_main()

func _input(event: InputEvent) -> void:
	if not _active:
		return
	if not GameState.is_state(GameState.State.MENU):
		return
	_handle_input(event)

func _handle_input(event: InputEvent) -> void:
	if event.is_action_pressed("move_up"):
		_move_cursor(-1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("move_down"):
		_move_cursor(1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("confirm"):
		_on_confirm()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("cancel"):
		_on_cancel()
		get_viewport().set_input_as_handled()

func _move_cursor(direction: int) -> void:
	var count := _get_item_count()
	if count <= 0:
		return
	_cursor_index = (_cursor_index + direction + count) % count
	_update_display()
	SfxManager.play(cursor_move_sfx)

func _get_item_count() -> int:
	return 0

func _on_confirm() -> void:
	pass

func _on_cancel() -> void:
	SfxManager.play(cancel_sfx)
	close()

func _update_display() -> void:
	pass

func _get_panel() -> VBoxContainer:
	return menu.get_right_panel()

func _clear_panel() -> void:
	for child: Node in _get_panel().get_children():
		child.queue_free()
