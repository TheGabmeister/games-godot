extends StaticBody2D

@export var bump_config: Resource  # BlockBumpConfig
@export var bump_sound: AudioStream

var _bumping: bool = false
var _bump_time: float = 0.0
var _bump_offset: float = 0.0


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0


func _process(delta: float) -> void:
	if _bumping:
		_bump_time += delta
		var t: float = _bump_time / bump_config.bump_duration
		if t >= 1.0:
			_bump_offset = 0.0
			_bumping = false
		else:
			_bump_offset = -bump_config.bump_amplitude * sin(t * PI)
		queue_redraw()


func start_bump() -> void:
	_bumping = true
	_bump_time = 0.0


func play_bump_sound() -> void:
	_play_sound(bump_sound)


func bump_from_below() -> void:
	pass


func _play_sound(sound: AudioStream) -> void:
	if sound != null:
		EventBus.sfx_requested.emit(sound)
