# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Running the Project

```bash
# Launch Godot editor with the project
/d/Godot_v4.6.2-stable_win64.exe --path /c/dev/games-godot/flappy-bird

# Run the game directly (no editor)
/d/Godot_v4.6.2-stable_win64.exe --path /c/dev/games-godot/flappy-bird --run

# Check for script compile errors (headless)
/d/Godot_v4.6.2-stable_win64.exe --path /c/dev/games-godot/flappy-bird --headless --quit
```

## Architecture

Godot 4.6 project (480x720 viewport, canvas_items stretch mode). All visuals use `_draw()` — no sprites, textures, or audio.

### Signal-Driven Game Flow

**GameManager** (`autoload/game_manager.gd`) is the sole autoload singleton. It owns all game state via a `GameState` enum (`IDLE`, `PLAYING`, `GAME_OVER`) with computed properties (`is_idle`, `is_playing`, `is_game_over`). It handles all input (start, restart) and emits signals: `game_started`, `game_over`, `score_changed`, `restart_enabled`, `state_changed`. All other scripts connect to these signals — components never reference each other directly.

```
Input → GameManager.start_game()/end_game()/add_score()
         ↓ signals
    Bird, Main, HUD react independently
```

### Game Config Resource

Tunable gameplay values live in a `GameConfig` Resource (`resources/game_config.gd` + `resources/game_config.tres`). Scripts load it via `const GAME_CONFIG := preload("res://resources/game_config.tres")`. Derived properties (e.g., `GROUND_TOP_Y`, `BIRD_START_POSITION`, `PIPE_SPAWN_X`) are computed from base values, and screen dimensions are read from `ProjectSettings` — not hardcoded. Values are editable in the Godot inspector.

### Collision Layers

- **Layer 1:** Bird (CharacterBody2D) — masks layer 2
- **Layer 2:** Pipes and ground (StaticBody2D) — mask 0
- **ScoreZone:** Area2D with layer 0, masks layer 1 — triggers `body_entered` when bird passes through

Bird detects pipe/ground hits via `move_and_slide()` + `get_slide_collision_count()`. Score zones use Area2D `body_entered` signal with a `_scored` flag to prevent duplicates.

### Key Conventions

- Private members prefixed with `_` (e.g., `_can_restart`, `_pipe_container`)
- Input action `"flap"` is defined in the project input map (SPACE + left click)
- PipePair collision shapes are created dynamically in `_setup_pipes()` based on `gap_center_y` (set by Main before `add_child`)
- `queue_redraw()` is called each physics frame for animated elements (bird wing, rotation)
- Restart is gated by a 1-second delay in GameManager (`_enable_restart_after_delay`) to prevent accidental restarts
