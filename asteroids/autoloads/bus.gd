# event bus implementation in Godot

extends Node

# Because the event bus is autoloaded, we add this to ignore the warnings
@warning_ignore_start("unused_signal") 

signal enemy_killed(score: int)
signal player_killed()
signal update_score(score: int)
signal update_hi_score(score: int)
