extends AudioStreamPlayer

var _music_position := 0.0
var _is_paused := false

func _enter_tree():
	Bus.music_play.connect(_play_music)

func _exit_tree():
	Bus.music_play.disconnect(_play_music)
	
func _play_music(sound: AudioStream):
	stream = sound
	play()
	_is_paused = false

func _toggle_pause_music():
	if _is_paused == true:
		_is_paused = false
		play(_music_position)
	else:
		_is_paused = true
		_music_position = get_playback_position()
		stop()

func _stop_music():
	stop()
	_is_paused = false
