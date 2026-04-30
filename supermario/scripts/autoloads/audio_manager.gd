extends Node

const SFX_POOL_SIZE: int = 10
const MUSIC_FADE_DURATION: float = 0.5

var _music_registry: Dictionary[StringName, String] = {
	&"overworld": "",
	&"underground": "",
	&"star": "",
	&"hurry": "",
}

var _music_streams: Dictionary[StringName, AudioStream] = {}

var _sfx_pool: Array[AudioStreamPlayer] = []
var _sfx_pool_index: int = 0

var _music_a: AudioStreamPlayer
var _music_b: AudioStreamPlayer
var _active_music: AudioStreamPlayer
var _current_music_name: StringName = &""


func _ready() -> void:
	_build_sfx_pool()
	_build_music_players()
	_connect_signals()


func play_sfx(sound: AudioStream) -> void:
	if sound == null:
		return
	var player := _sfx_pool[_sfx_pool_index]
	player.stream = sound
	player.play()
	_sfx_pool_index = (_sfx_pool_index + 1) % SFX_POOL_SIZE


func play_music(music_name: StringName) -> void:
	if music_name == _current_music_name:
		return
	if not _music_registry.has(music_name):
		push_warning("AudioManager: unknown music key '%s'" % music_name)
		return
	var stream := _get_music_stream(music_name)
	if stream == null:
		stop_music()
		return

	_current_music_name = music_name
	var incoming := _music_b if _active_music == _music_a else _music_a
	incoming.stream = stream
	incoming.volume_db = -40.0
	incoming.play()

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(_active_music, "volume_db", -40.0, MUSIC_FADE_DURATION)
	tween.tween_property(incoming, "volume_db", 0.0, MUSIC_FADE_DURATION)
	tween.set_parallel(false)
	tween.tween_callback(_active_music.stop)

	_active_music = incoming


func stop_music() -> void:
	_current_music_name = &""
	var tween := create_tween()
	tween.tween_property(_active_music, "volume_db", -40.0, MUSIC_FADE_DURATION)
	tween.tween_callback(_active_music.stop)


func set_music_ducked(enabled: bool) -> void:
	var target_db := -10.0 if enabled else 0.0
	var tween := create_tween()
	tween.tween_property(_active_music, "volume_db", target_db, 0.2)


func _get_music_stream(music_name: StringName) -> AudioStream:
	if _music_streams.has(music_name):
		return _music_streams[music_name]
	var path: String = _music_registry[music_name]
	if path.is_empty():
		return null
	var stream := load(path) as AudioStream
	if stream != null:
		_music_streams[music_name] = stream
	return stream


func _build_sfx_pool() -> void:
	for i in SFX_POOL_SIZE:
		var player := AudioStreamPlayer.new()
		player.bus = &"SFX"
		add_child(player)
		_sfx_pool.append(player)


func _build_music_players() -> void:
	_music_a = AudioStreamPlayer.new()
	_music_a.bus = &"Music"
	add_child(_music_a)
	_music_b = AudioStreamPlayer.new()
	_music_b.bus = &"Music"
	add_child(_music_b)
	_active_music = _music_a


func _connect_signals() -> void:
	EventBus.sfx_requested.connect(play_sfx)
	EventBus.player_died.connect(func() -> void:
		stop_music()
	)
	EventBus.level_started.connect(func(_w: int, l: int) -> void:
		if l >= 2:
			play_music(&"underground")
		else:
			play_music(&"overworld")
	)
	EventBus.level_completed.connect(func() -> void:
		stop_music()
	)
	EventBus.game_over.connect(func() -> void:
		stop_music()
	)
