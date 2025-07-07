# event bus implementation in Godot

extends Node

# Because the event bus is autoloaded, we add this to ignore the warnings
@warning_ignore_start("unused_signal") 

signal enemy_killed(score: int)
signal player_killed()
signal player_spawned()
signal update_score(score: int)
signal update_hi_score(score: int)

signal sfx_play_sound(sound: AudioStream)

signal music_play(sound: AudioStream)
signal music_pause_toggle()
signal music_stop()
