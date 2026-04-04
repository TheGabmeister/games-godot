# AGENTS.md

## Project Overview

- This repo is a small Godot 4.6 Flappy Bird clone.
- The main scene is `res://scenes/main.tscn`.
- Gameplay is code-driven: the bird, pipes, and ground are drawn from GDScript instead of imported art assets.
- Global game state lives in the `GameManager` autoload at `res://autoload/game_manager.gd`.

## Repository Layout

- `project.godot`: project configuration, main scene, autoload registration, window size.
- `autoload/game_manager.gd`: shared game state, score, start/end events, input action setup.
- `scenes/main.tscn`: root gameplay scene with `Bird`, `PipeContainer`, `Ground`, `PipeSpawnTimer`, and `HUD`.
- `scenes/bird.tscn`: `CharacterBody2D` player scene.
- `scenes/pipe_pair.tscn`: obstacle scene with top pipe, bottom pipe, and score zone.
- `scripts/main.gd`: pipe spawning and ground drawing.
- `scripts/bird.gd`: flap physics, collision/game-over handling, and procedural bird drawing.
- `scripts/pipe_pair.gd`: pipe movement, collision setup, score trigger, and procedural pipe drawing.
- `scripts/hud.gd`: score, start, game-over, and restart UI state.

## Gameplay Architecture

- `GameManager` is the source of truth for:
  - `score`
  - `is_playing`
  - `is_game_over`
  - `game_started`, `game_over`, and `score_changed`
- The `"flap"` input action is created in code by `GameManager._setup_input_actions()`. It currently binds `Space` and left mouse button.
- Restart flow uses `GameManager.start_game()` again instead of reloading the scene.
- Pipes spawn from `scripts/main.gd` on a repeating `Timer`.
- Scoring happens in `scripts/pipe_pair.gd` when the bird enters `ScoreZone`.

## Scene And Collision Assumptions

- The bird is on collision layer `1` and collides with layer `2`.
- Ground and pipes use collision layer `2`.
- `ScoreZone` is an `Area2D` with `collision_mask = 1` so it only reacts to the bird.
- Keep node names stable unless you also update the matching `$NodePath` references in scripts.

## Editing Guidelines

- Prefer typed GDScript and keep the current style:
  - `snake_case` for functions and variables
  - `SCREAMING_SNAKE_CASE` for constants
  - explicit type annotations where the file already uses them
- Preserve tabs/formatting produced by Godot-style GDScript files already in the repo.
- When changing procedural visuals in `_draw()`, make sure the node still calls `queue_redraw()` when state changes over time.
- Route shared state changes through `GameManager` instead of duplicating state in scene scripts.
- Prefer input actions such as `"flap"` over hardcoded key checks in gameplay scripts.
- Avoid editing `.godot/` generated files unless the task is specifically about editor metadata.

## Running And Verification

- Preferred local editor/run command in this workspace:
  - `D:\Godot_v4.6.2-stable_win64.exe --path C:\dev\games-godot\flappy-bird`
- Headless smoke test:
  - `D:\Godot_v4.6.2-stable_win64.exe --path C:\dev\games-godot\flappy-bird --headless --quit`
- Use the headless command as a quick verification after script or scene changes. It will catch parse/load errors, but not gameplay regressions.

## Agent Notes

- Before changing scene structure, inspect the related `.tscn` and script together because this project relies on direct node paths.
- Since restart does not reload the scene, watch for state that must be reset manually on `game_started`.
- If you add new gameplay input, register it centrally in `GameManager`.
- If you introduce assets, document their paths and whether they replace any procedural drawing currently done in code.
