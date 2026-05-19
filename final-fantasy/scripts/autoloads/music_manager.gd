extends Node

var _player: AudioStreamPlayer


func _ready() -> void:
	_player = AudioStreamPlayer.new()
	_player.bus = &"Music"
	add_child(_player)
	_player.finished.connect(_on_finished)


func play(stream: AudioStream) -> void:
	if _player.stream == stream and _player.playing:
		return
	_player.stream = stream
	_player.play()


func stop() -> void:
	_player.stop()
	_player.stream = null


func _on_finished() -> void:
	if _player.stream != null:
		_player.play()
