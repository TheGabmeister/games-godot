extends Node

func _enter_tree():
	Bus.sfx_play_sound.connect(_play_sound)

func _exit_tree():
	Bus.sfx_play_sound.disconnect(_play_sound)
	
func _play_sound():
	pass
