extends Node

const SFX_POOL_SIZE: int = 10
const SFX_2D_POOL_SIZE: int = 6
const MUSIC_FADE_DURATION: float = 0.5

var _sfx_registry: Dictionary[StringName, String] = {
	&"jump": "",
	&"jump_big": "",
	&"stomp": "",
	&"coin": "",
	&"block_bump": "",
	&"block_break": "",
	&"powerup": "",
	&"powerdown": "",
	&"fireball": "",
	&"kick": "",
	&"pipe": "",
	&"1up": "",
	&"death": "",
	&"flagpole": "",
	&"game_over": "",
	&"stage_clear": "",
	&"warning": "",
}

var _music_registry: Dictionary[StringName, String] = {
	&"overworld": "",
	&"underground": "",
	&"star": "",
	&"hurry": "",
}

var _sfx_pool: Array[AudioStreamPlayer] = []
var _sfx_pool_index: int = 0
var _sfx_2d_pool: Array[AudioStreamPlayer2D] = []
var _sfx_2d_pool_index: int = 0

var _music_a: AudioStreamPlayer
var _music_b: AudioStreamPlayer
var _active_music: AudioStreamPlayer
var _current_music_name: StringName = &""


func _ready() -> void:
	_build_sfx_pool()
	_build_music_players()
	_connect_signals()


func play_sfx(sound_name: StringName, position: Vector2 = Vector2.ZERO) -> void:
	var path := _sfx_registry.get(sound_name, "") as String
	if path.is_empty():
		return
	var stream := load(path) as AudioStream
	if stream == null:
		return
	if position == Vector2.ZERO:
		var player := _sfx_pool[_sfx_pool_index]
		player.stream = stream
		player.play()
		_sfx_pool_index = (_sfx_pool_index + 1) % SFX_POOL_SIZE
	else:
		var player := _sfx_2d_pool[_sfx_2d_pool_index]
		player.stream = stream
		player.global_position = position
		player.play()
		_sfx_2d_pool_index = (_sfx_2d_pool_index + 1) % SFX_2D_POOL_SIZE


func play_music(music_name: StringName) -> void:
	if music_name == _current_music_name:
		return
	var path := _music_registry.get(music_name, "") as String
	if path.is_empty():
		stop_music()
		return
	var stream := load(path) as AudioStream
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


func _build_sfx_pool() -> void:
	for i in SFX_POOL_SIZE:
		var player := AudioStreamPlayer.new()
		player.bus = &"SFX"
		add_child(player)
		_sfx_pool.append(player)
	for i in SFX_2D_POOL_SIZE:
		var player := AudioStreamPlayer2D.new()
		player.bus = &"SFX"
		add_child(player)
		_sfx_2d_pool.append(player)


func _build_music_players() -> void:
	_music_a = AudioStreamPlayer.new()
	_music_a.bus = &"Music"
	add_child(_music_a)
	_music_b = AudioStreamPlayer.new()
	_music_b.bus = &"Music"
	add_child(_music_b)
	_active_music = _music_a


func _connect_signals() -> void:
	EventBus.coin_collected.connect(func(pos: Vector2) -> void: play_sfx(&"coin", pos))
	EventBus.player_died.connect(func() -> void:
		play_sfx(&"death")
		stop_music()
	)
	EventBus.enemy_stomped.connect(func(pos: Vector2) -> void: play_sfx(&"stomp", pos))
	EventBus.block_bumped.connect(func(pos: Vector2) -> void: play_sfx(&"block_bump", pos))
	EventBus.block_broken.connect(func(pos: Vector2) -> void: play_sfx(&"block_break", pos))
	EventBus.player_powered_up.connect(func(_type: StringName) -> void: play_sfx(&"powerup"))
	EventBus.player_damaged.connect(func() -> void: play_sfx(&"powerdown"))
	EventBus.level_started.connect(func(_w: int, _l: int) -> void: play_music(&"overworld"))
	EventBus.level_completed.connect(func() -> void:
		stop_music()
		play_sfx(&"stage_clear")
	)
	EventBus.game_over.connect(func() -> void:
		stop_music()
		play_sfx(&"game_over")
	)
	EventBus.one_up_earned.connect(func() -> void: play_sfx(&"1up"))
	EventBus.flagpole_reached.connect(func(_h: float) -> void: play_sfx(&"flagpole"))
