extends Node

const POOL_SIZE: int = 16

var _players: Array[AudioStreamPlayer] = []

func _ready() -> void:
	for i: int in POOL_SIZE:
		var asp := AudioStreamPlayer.new()
		add_child(asp)
		_players.append(asp)


func play(stream: AudioStream, volume_db: float = 0.0) -> void:
	for asp: AudioStreamPlayer in _players:
		if not asp.playing:
			asp.stream = stream
			asp.volume_db = volume_db
			asp.play()
			return