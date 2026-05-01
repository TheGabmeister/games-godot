extends Node

const DEFAULT_VOLUME_DB := 0.0

var _player: AudioStreamPlayer
var _looping := false

func _ready() -> void:
	_player = AudioStreamPlayer.new()
	_player.name = "AudioStreamPlayer"
	add_child(_player)
	_player.finished.connect(_on_player_finished)

func play_music(stream: AudioStream, volume_db: float = DEFAULT_VOLUME_DB) -> void:
	if stream == null:
		return

	_looping = true
	stream.set("loop", true)
	if _player.stream != stream:
		_player.stream = stream
	_player.volume_db = volume_db
	_player.play()

func stop_music() -> void:
	_looping = false
	_player.stop()

func _on_player_finished() -> void:
	if _looping:
		_player.play()
