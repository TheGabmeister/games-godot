extends Node

const SFX_POOL_SIZE: int = 10

var _sfx_pool: Array[AudioStreamPlayer] = []
var _sfx_pool_index: int = 0


func _ready() -> void:
	_build_sfx_pool()
	EventBus.sfx_requested.connect(play_sfx)


func play_sfx(sound: AudioStream) -> void:
	if sound == null:
		return
	var player := _sfx_pool[_sfx_pool_index]
	player.stream = sound
	player.play()
	_sfx_pool_index = (_sfx_pool_index + 1) % SFX_POOL_SIZE


func _build_sfx_pool() -> void:
	for i in SFX_POOL_SIZE:
		var player := AudioStreamPlayer.new()
		player.bus = &"SFX"
		add_child(player)
		_sfx_pool.append(player)
