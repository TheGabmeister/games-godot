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

**GameManager** (`autoload/game_manager.gd`) is the sole autoload singleton. It owns all game state (`score`, `is_playing`, `is_game_over`) and emits three signals: `game_started`, `game_over`, `score_changed`. All other scripts connect to these signals — components never reference each other directly.

```
Input → GameManager.start_game()/end_game()/add_score()
         ↓ signals
    Bird, Main, HUD react independently
```

### Collision Layers

- **Layer 1:** Bird (CharacterBody2D) — masks layer 2
- **Layer 2:** Pipes and ground (StaticBody2D) — mask 0
- **ScoreZone:** Area2D with layer 0, masks layer 1 — triggers `body_entered` when bird passes through

Bird detects pipe/ground hits via `move_and_slide()` + `get_slide_collision_count()`. Score zones use Area2D `body_entered` signal with a `_scored` flag to prevent duplicates.

### Key Conventions

- Private members prefixed with `_` (e.g., `_started`, `_pipe_container`)
- Input action `"flap"` is registered programmatically in GameManager (SPACE + left click)
- PipePair collision shapes are created dynamically in `_setup_pipes()` based on `gap_center_y` (set by Main before `add_child`)
- `queue_redraw()` is called each physics frame for animated elements (bird wing, rotation)
