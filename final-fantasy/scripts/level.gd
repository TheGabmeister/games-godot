extends Node2D

@export var music: AudioStream

@onready var warrior: CharacterBody2D = $Warrior

func _ready() -> void:
	GameState.transition(GameState.State.FIELD)
	if music:
		MusicManager.play(music)
	if GameState.has_spawn_override:
		warrior.position = GameState.spawn_position
		GameState.has_spawn_override = false
