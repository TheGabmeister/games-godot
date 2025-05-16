extends AudioStreamPlayer

func _ready():
	stream = AudioStreamPolyphonic.new()
	stream.polyphony = 10
func _enter_tree():
	Bus.sfx_play_sound.connect(_play_sound)

func _exit_tree():
	Bus.sfx_play_sound.disconnect(_play_sound)
	
func _play_sound(sound: AudioStream):
	
	if !playing: self.play()
	
	var polyphonic_stream_playback := get_stream_playback()
	polyphonic_stream_playback.play_stream(sound)
	play()
