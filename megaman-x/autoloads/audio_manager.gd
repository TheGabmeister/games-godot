extends Node

const DEFAULT_MUSIC_EVENTS := {
	&"title_theme": {"duration": 1.8, "mix_rate": 22050.0},
	&"test_stage_theme": {"duration": 2.2, "mix_rate": 22050.0},
}

const DEFAULT_SFX_EVENTS := {
	&"player_buster_shot": {"duration": 0.14, "mix_rate": 22050.0},
	&"player_charge_start": {"duration": 0.22, "mix_rate": 22050.0},
	&"player_charge_full": {"duration": 0.32, "mix_rate": 22050.0},
	&"player_charge_release": {"duration": 0.2, "mix_rate": 22050.0},
	&"player_hurt": {"duration": 0.18, "mix_rate": 22050.0},
	&"stage_clear_fanfare": {"duration": 0.6, "mix_rate": 22050.0},
}

var _music_player: AudioStreamPlayer
var _sfx_players: Array[AudioStreamPlayer] = []
var _music_events: Dictionary = {}
var _sfx_events: Dictionary = {}
var last_music_event: StringName = &""
var last_sfx_event: StringName = &""


func _ready() -> void:
	_music_player = AudioStreamPlayer.new()
	_music_player.name = "MusicPlayer"
	add_child(_music_player)

	for index in range(4):
		var sfx_player := AudioStreamPlayer.new()
		sfx_player.name = "SfxPlayer%d" % index
		add_child(sfx_player)
		_sfx_players.append(sfx_player)

	_register_default_events()


func register_music_event(event_id: StringName, stream: AudioStream) -> void:
	_music_events[event_id] = stream


func register_sfx_event(event_id: StringName, stream: AudioStream) -> void:
	_sfx_events[event_id] = stream


func has_music_event(event_id: StringName) -> bool:
	return _music_events.has(event_id)


func has_sfx_event(event_id: StringName) -> bool:
	return _sfx_events.has(event_id)


func play_music(event_id: StringName) -> void:
	if not _music_events.has(event_id):
		return

	last_music_event = event_id
	_music_player.stream = _music_events[event_id]
	_music_player.play()


func stop_music() -> void:
	_music_player.stop()


func play_sfx(event_id: StringName) -> void:
	if not _sfx_events.has(event_id):
		return

	last_sfx_event = event_id
	for sfx_player in _sfx_players:
		if sfx_player.playing:
			continue

		sfx_player.stream = _sfx_events[event_id]
		sfx_player.play()
		return

	_sfx_players[0].stream = _sfx_events[event_id]
	_sfx_players[0].play()


func _register_default_events() -> void:
	for event_id in DEFAULT_MUSIC_EVENTS.keys():
		var music_config: Dictionary = DEFAULT_MUSIC_EVENTS[event_id]
		register_music_event(event_id, _build_placeholder_stream(music_config))

	for event_id in DEFAULT_SFX_EVENTS.keys():
		var sfx_config: Dictionary = DEFAULT_SFX_EVENTS[event_id]
		register_sfx_event(event_id, _build_placeholder_stream(sfx_config))


func _build_placeholder_stream(configuration: Dictionary) -> AudioStreamGenerator:
	var stream := AudioStreamGenerator.new()
	stream.mix_rate = float(configuration.get("mix_rate", 22050.0))
	stream.buffer_length = float(configuration.get("duration", 0.2))
	return stream
