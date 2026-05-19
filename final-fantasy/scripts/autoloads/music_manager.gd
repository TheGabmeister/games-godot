extends Node

var _player: AudioStreamPlayer


func _ready() -> void:
	_player = AudioStreamPlayer.new()
	add_child(_player)
	_player.finished.connect(_on_finished)


func play(stream: AudioStream, volume_db: float = 0.0) -> void:
	if _player.stream == stream and _player.playing:
		return
	_player.stream = stream
	_player.volume_db = volume_db
	_player.play()


func stop() -> void:
	_player.stop()
	_player.stream = null


func _on_finished() -> void:
	if _player.stream != null:
		_player.play()
