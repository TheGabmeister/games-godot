extends Node

var _bgm_player_a: AudioStreamPlayer
var _bgm_player_b: AudioStreamPlayer
var _active_bgm: AudioStreamPlayer
var _sfx_pool: Array[AudioStreamPlayer] = []
var _current_bgm_track: StringName = &""

const SFX_POOL_SIZE := 8


func _ready() -> void:
	_bgm_player_a = AudioStreamPlayer.new()
	_bgm_player_a.bus = "Master"
	add_child(_bgm_player_a)

	_bgm_player_b = AudioStreamPlayer.new()
	_bgm_player_b.bus = "Master"
	add_child(_bgm_player_b)

	_active_bgm = _bgm_player_a

	for i in SFX_POOL_SIZE:
		var sfx_player := AudioStreamPlayer.new()
		sfx_player.bus = "Master"
		add_child(sfx_player)
		_sfx_pool.append(sfx_player)


func play_bgm(track_name: StringName) -> void:
	if track_name == _current_bgm_track:
		return
	_current_bgm_track = track_name
	var path := "res://audio/bgm/%s.ogg" % track_name
	if ResourceLoader.exists(path):
		var stream := load(path) as AudioStream
		_active_bgm.stream = stream
		_active_bgm.play()
	else:
		print("[Audio][BGM] %s (placeholder)" % track_name)


func stop_bgm() -> void:
	_bgm_player_a.stop()
	_bgm_player_b.stop()
	_current_bgm_track = &""


func play_sfx(sfx_name: StringName) -> void:
	var path := "res://audio/sfx/%s.ogg" % sfx_name
	if ResourceLoader.exists(path):
		var stream := load(path) as AudioStream
		var player := _get_available_sfx_player()
		if player:
			player.stream = stream
			player.play()
	else:
		print("[Audio][SFX] %s (placeholder)" % sfx_name)


func set_bgm_volume(db: float) -> void:
	_bgm_player_a.volume_db = db
	_bgm_player_b.volume_db = db


func set_sfx_volume(db: float) -> void:
	for player in _sfx_pool:
		player.volume_db = db


func _get_available_sfx_player() -> AudioStreamPlayer:
	for player in _sfx_pool:
		if not player.playing:
			return player
	return _sfx_pool[0]
