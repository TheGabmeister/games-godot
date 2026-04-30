extends Node

const SFX_POOL_SIZE: int = 10
const MUSIC_FADE_DURATION: float = 0.5

var _sfx_registry: Dictionary[StringName, String] = {
	&"jump": "res://audio/sfx/jump.wav",
	&"jump_big": "res://audio/sfx/jump_big.wav",
	&"stomp": "res://audio/sfx/stomp.wav",
	&"coin": "res://audio/sfx/coin.wav",
	&"block_bump": "res://audio/sfx/block_bump.wav",
	&"block_break": "res://audio/sfx/block_break.wav",
	&"powerup": "res://audio/sfx/powerup.wav",
	&"powerdown": "res://audio/sfx/powerdown.wav",
	&"fireball": "res://audio/sfx/fireball.wav",
	&"kick": "res://audio/sfx/kick.wav",
	&"pipe": "res://audio/sfx/pipe.wav",
	&"1up": "res://audio/sfx/1up.wav",
	&"death": "res://audio/sfx/death.wav",
	&"flagpole": "res://audio/sfx/flagpole.wav",
	&"game_over": "res://audio/sfx/game_over.wav",
	&"stage_clear": "res://audio/sfx/stage_clear.wav",
	&"warning": "res://audio/sfx/warning.wav",
}

var _music_registry: Dictionary[StringName, String] = {
	&"overworld": "",
	&"underground": "",
	&"star": "",
	&"hurry": "",
}

var _sfx_streams: Dictionary[StringName, AudioStream] = {}
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


func play_sfx(sound_name: StringName) -> void:
	if not _sfx_registry.has(sound_name):
		push_warning("AudioManager: unknown SFX key '%s'" % sound_name)
		return
	var stream := _get_sfx_stream(sound_name)
	if stream == null:
		return
	var player := _sfx_pool[_sfx_pool_index]
	player.stream = stream
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


func _get_sfx_stream(sound_name: StringName) -> AudioStream:
	if _sfx_streams.has(sound_name):
		return _sfx_streams[sound_name]
	var path: String = _sfx_registry[sound_name]
	if path.is_empty():
		return null
	var stream := load(path) as AudioStream
	if stream != null:
		_sfx_streams[sound_name] = stream
	return stream


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
	EventBus.coin_collected.connect(func(_pos: Vector2) -> void: play_sfx(&"coin"))
	EventBus.player_died.connect(func() -> void:
		play_sfx(&"death")
		stop_music()
	)
	EventBus.enemy_stomped.connect(func(_pos: Vector2) -> void: play_sfx(&"stomp"))
	EventBus.block_bumped.connect(func(_pos: Vector2) -> void: play_sfx(&"block_bump"))
	EventBus.block_broken.connect(func(_pos: Vector2) -> void: play_sfx(&"block_break"))
	EventBus.player_powered_up.connect(func(_type: StringName) -> void: play_sfx(&"powerup"))
	EventBus.player_damaged.connect(func() -> void: play_sfx(&"powerdown"))
	EventBus.level_started.connect(func(_w: int, l: int) -> void:
		if l >= 2:
			play_music(&"underground")
		else:
			play_music(&"overworld")
	)
	EventBus.level_completed.connect(func() -> void:
		stop_music()
		play_sfx(&"stage_clear")
	)
	EventBus.game_over.connect(func() -> void:
		stop_music()
		play_sfx(&"game_over")
	)
	EventBus.one_up_earned.connect(func() -> void: play_sfx(&"1up"))
