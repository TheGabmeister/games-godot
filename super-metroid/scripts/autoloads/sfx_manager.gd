extends Node

const POOL_SIZE: int = 16

var _players: Array[AudioStreamPlayer] = []
var _loops: Dictionary[StringName, AudioStreamPlayer] = {}


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


func play_loop(id: StringName, stream: AudioStream, volume_db: float = 0.0) -> void:
	if _loops.has(id):
		return
	var asp := AudioStreamPlayer.new()
	asp.stream = stream
	asp.volume_db = volume_db
	add_child(asp)
	asp.play()
	_loops[id] = asp


func stop_loop(id: StringName) -> void:
	if _loops.has(id):
		var asp: AudioStreamPlayer = _loops[id]
		asp.stop()
		asp.queue_free()
		var _erased := _loops.erase(id)


func is_loop_playing(id: StringName) -> bool:
	return _loops.has(id)
