extends Node

const DEFAULT_VOLUME_DB := -12.0

var _player: AudioStreamPlayer

func _ready() -> void:
	_player = AudioStreamPlayer.new()
	_player.name = "AudioStreamPlayer"
	add_child(_player)

func play_music(stream: AudioStream, volume_db: float = DEFAULT_VOLUME_DB) -> void:
	if stream == null:
		return

	stream.set("loop", true)
	if _player.stream != stream:
		_player.stream = stream
	_player.volume_db = volume_db
	_player.play()

func stop_music() -> void:
	_player.stop()
