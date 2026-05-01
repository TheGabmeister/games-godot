extends Node

# Audio
signal sfx_requested(sound: AudioStream)
signal music_requested(music: AudioStream)
signal music_stop_requested
signal music_duck_requested(enabled: bool)

# Player
signal player_respawned
signal player_powered_up(power_up_type: StringName)
signal player_power_state_changed(old_state: int, new_state: int)
signal player_damaged
signal player_star_power_started
signal player_star_power_ended

# Scoring and HUD
signal coin_collected(position: Vector2)
signal score_awarded(points: int, position: Vector2)
signal score_changed(new_score: int)
signal lives_changed(new_lives: int)
signal coins_changed(new_coin_count: int)
signal time_tick(time_remaining: int)
signal one_up_earned

# Level
signal level_started(display_name: String)
signal level_completed
signal flagpole_reached(height_ratio: float)

# Enemies
signal enemy_stomped(position: Vector2)
signal enemy_killed(position: Vector2, enemy_type: StringName)
signal combo_stomp(count: int, position: Vector2)

# Blocks and items
signal block_bumped(position: Vector2)
signal block_broken(position: Vector2)
signal item_spawned(item_type: StringName, position: Vector2)

# Game state
signal game_paused
signal game_resumed
signal game_over
