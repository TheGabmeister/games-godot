extends Node

var _music_player: AudioStreamPlayer
var _sfx_players: Array[AudioStreamPlayer] = []
var _music_events: Dictionary = {}
var _sfx_events: Dictionary = {}


func _ready() -> void:
	_music_player = AudioStreamPlayer.new()
	_music_player.name = "MusicPlayer"
	add_child(_music_player)

	for index in range(4):
		var sfx_player := AudioStreamPlayer.new()
		sfx_player.name = "SfxPlayer%d" % index
		add_child(sfx_player)
		_sfx_players.append(sfx_player)


func register_music_event(event_id: StringName, stream: AudioStream) -> void:
	_music_events[event_id] = stream


func register_sfx_event(event_id: StringName, stream: AudioStream) -> void:
	_sfx_events[event_id] = stream


func play_music(event_id: StringName) -> void:
	if not _music_events.has(event_id):
		return

	_music_player.stream = _music_events[event_id]
	_music_player.play()


func stop_music() -> void:
	_music_player.stop()


func play_sfx(event_id: StringName) -> void:
	if not _sfx_events.has(event_id):
		return

	for sfx_player in _sfx_players:
		if sfx_player.playing:
			continue

		sfx_player.stream = _sfx_events[event_id]
		sfx_player.play()
		return

	_sfx_players[0].stream = _sfx_events[event_id]
	_sfx_players[0].play()
