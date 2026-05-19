extends Node

var _player: AudioStreamPlayer
var _current_track: StringName = &""


func _ready() -> void:
	_player = AudioStreamPlayer.new()
	add_child(_player)
	var _err := _player.finished.connect(_on_finished)


func play(id: StringName, stream: AudioStream, volume_db: float = 0.0) -> void:
	if _current_track == id and _player.playing:
		return
	_current_track = id
	_player.stream = stream
	_player.volume_db = volume_db
	_player.play()


func stop() -> void:
	_player.stop()
	_current_track = &""


func get_current_track() -> StringName:
	return _current_track


func _on_finished() -> void:
	if _current_track != &"" and _player.stream != null:
		_player.play()
