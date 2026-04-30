extends Node

const MUSIC_FADE_DURATION: float = 0.5

var _music_a: AudioStreamPlayer
var _music_b: AudioStreamPlayer
var _active_music: AudioStreamPlayer
var _current_music: AudioStream


func _ready() -> void:
	_build_music_players()
	EventBus.music_requested.connect(play_music)
	EventBus.music_stop_requested.connect(stop_music)
	EventBus.music_duck_requested.connect(set_music_ducked)


func play_music(music: AudioStream) -> void:
	if music == null:
		stop_music()
		return
	if music == _current_music:
		return

	_current_music = music
	var incoming := _music_b if _active_music == _music_a else _music_a
	incoming.stream = music
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
	_current_music = null
	var tween := create_tween()
	tween.tween_property(_active_music, "volume_db", -40.0, MUSIC_FADE_DURATION)
	tween.tween_callback(_active_music.stop)


func set_music_ducked(enabled: bool) -> void:
	var target_db := -10.0 if enabled else 0.0
	var tween := create_tween()
	tween.tween_property(_active_music, "volume_db", target_db, 0.2)


func _build_music_players() -> void:
	_music_a = AudioStreamPlayer.new()
	_music_a.bus = &"Music"
	add_child(_music_a)
	_music_b = AudioStreamPlayer.new()
	_music_b.bus = &"Music"
	add_child(_music_b)
	_active_music = _music_a
