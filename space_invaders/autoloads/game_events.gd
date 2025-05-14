extends Node

# Because the event bus is autoloaded, we add this to ignore the warnings
@warning_ignore_start("unused_signal") 

signal enemy_killed(score: int)

@warning_ignore_restore("unused_signal")
