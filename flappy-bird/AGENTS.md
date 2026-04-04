# AGENTS.md

## Project Overview

- This repo is a small Godot 4.6 Flappy Bird clone.
- The main scene is `res://scenes/main.tscn`.
- Gameplay is code-driven: the bird, pipes, and ground are drawn from GDScript instead of imported art assets.
- The project currently has no gameplay sprites, textures, or audio assets beyond the default window icon.
- Global game state lives in the `GameManager` autoload at `res://autoload/game_manager.gd`.
- Editable gameplay tuning lives in `res://resources/game_config.tres`, backed by `res://resources/game_config.gd`.
- The game runs in a `480x720` viewport with `canvas_items` stretch mode.

## Repository Layout

- `project.godot`: project configuration, main scene, `GameManager` autoload registration, input map, window size.
- `autoload/game_manager.gd`: shared game state, state machine, score, and centralized start/restart flow.
- `resources/game_config.gd`: `Resource` script that defines editable gameplay values and computed helpers such as screen bounds and spawn positions.
- `resources/game_config.tres`: inspector-editable gameplay tuning asset used by gameplay scripts.
- `scenes/main.tscn`: root gameplay scene with `Bird`, `PipeContainer`, `Ground`, `PipeSpawnTimer`, and `HUD`.
- `scenes/bird.tscn`: `CharacterBody2D` player scene.
- `scenes/pipe_pair.tscn`: obstacle scene with top pipe, bottom pipe, and score zone.
- `scripts/main.gd`: pipe spawning and ground drawing.
- `scripts/bird.gd`: flap physics, collision/game-over handling, and procedural bird drawing.
- `scripts/pipe_pair.gd`: pipe movement, collision setup, score trigger, and procedural pipe drawing.
- `scripts/hud.gd`: score, start, game-over, and restart UI state.
- `*.gd.uid`: Godot script UID metadata files; normally leave them alone unless Godot regenerates them.

## Gameplay Architecture

- `GameManager` is the source of truth for:
  - `score`
  - round state via `GameState` (`IDLE`, `PLAYING`, `GAME_OVER`)
  - `is_idle`, `is_playing`, `is_game_over`, and restart gating
  - `game_started`, `game_over`, `score_changed`, `restart_enabled`, and `state_changed`
- The `"flap"` input action is defined in `project.godot` and currently binds `Space` and left mouse button.
- Start and restart input are handled centrally in `autoload/game_manager.gd` via `_unhandled_input()`.
- Restart flow uses `GameManager.start_game()` again instead of reloading the scene.
- `GameManager` waits 1 second after game over before enabling restart and emitting `restart_enabled`; `scripts/hud.gd` only reflects that state in the UI.
- Pipes spawn from `scripts/main.gd` on a repeating `Timer`.
- `scripts/main.gd` clears existing pipes on every `game_started` signal and stops spawning on `game_over`.
- Scoring happens in `scripts/pipe_pair.gd` when the bird enters `ScoreZone`.
- `gap_center_y` on each pipe pair is configured by `scripts/main.gd` before the node is added to the tree, and `scripts/pipe_pair.gd` builds collision shapes from that value in `_ready()`.
- `scripts/main.gd` draws the ground visuals in `_draw()`, while the `Ground` node in `scenes/main.tscn` is collision-only.
- The bird has an idle bobbing state before the first start, and continues falling for a short time after game over because `_physics_process()` still applies gravity in that state.
- `scripts/bird.gd`, `scripts/main.gd`, and `scripts/pipe_pair.gd` each preload `res://resources/game_config.tres` directly instead of using a config autoload.

## Scene And Collision Assumptions

- The bird is on collision layer `1` and collides with layer `2`.
- Ground and pipes use collision layer `2`.
- `ScoreZone` is an `Area2D` with `collision_mask = 1` so it only reacts to the bird.
- `TopPipe`, `BottomPipe`, and `ScoreZone` collision shapes are replaced dynamically in `scripts/pipe_pair.gd`; scene defaults are only placeholders.
- Keep node names stable unless you also update the matching `$NodePath` references in scripts.
- `scripts/main.gd`, `scripts/hud.gd`, and `scripts/pipe_pair.gd` all rely on direct `$NodePath` lookups via typed `@onready` variables.

## Editing Guidelines

- Prefer typed GDScript and keep the current style:
  - `snake_case` for functions and variables
  - `SCREAMING_SNAKE_CASE` for constants
  - explicit type annotations where the file already uses them
- Follow the existing private-member convention: internal fields and cached node references use a leading underscore such as `_started` or `_pipe_container`.
- Prefer typed `@onready` node references for stable child lookups instead of repeated raw `$NodePath` access during gameplay.
- Preserve tabs/formatting produced by Godot-style GDScript files already in the repo.
- When changing procedural visuals in `_draw()`, make sure the node still calls `queue_redraw()` when state changes over time.
- Route shared state changes through `GameManager` instead of duplicating state in scene scripts.
- Prefer input actions such as `"flap"` over hardcoded key checks in gameplay scripts.
- Keep editable gameplay values in `resources/game_config.tres`; keep derived, non-editable helpers in `resources/game_config.gd`.
- If you change screen bounds, remember `SCREEN_WIDTH` and `SCREEN_HEIGHT` are derived from `project.godot`, while gameplay spacing and movement values live in `game_config.tres`.
- If you change restart or start flow, check `autoload/game_manager.gd`, `scripts/hud.gd`, and `scripts/bird.gd` so state ownership, UI, and player behavior stay in sync.
- Avoid editing `.godot/` generated files unless the task is specifically about editor metadata.

## Running And Verification

- Preferred local editor/run command in this workspace:
  - `D:\Godot_v4.6.2-stable_win64.exe --path C:\dev\games-godot\flappy-bird`
- Run the game directly without opening the editor:
  - `D:\Godot_v4.6.2-stable_win64.exe --path C:\dev\games-godot\flappy-bird --run`
- Headless smoke test:
  - `D:\Godot_v4.6.2-stable_win64.exe --path C:\dev\games-godot\flappy-bird --headless --quit`
- Use the headless command as a quick verification after script or scene changes. It will catch parse/load errors, but not gameplay regressions.

## Agent Notes

- Before changing scene structure, inspect the related `.tscn` and script together because this project relies on direct node paths.
- Since restart does not reload the scene, watch for state that must be reset manually on `game_started`.
- If you add new gameplay input, define the action in `project.godot` and keep lifecycle handling centralized in `GameManager` when appropriate.
- If you change pipe spawning or pipe setup timing, preserve the current assumption that `gap_center_y` is assigned before `_ready()` runs on the spawned pipe pair.
- If you modify game-over timing, remember `GameManager` currently owns the async restart delay and the HUD only reacts to `restart_enabled`.
- If you introduce assets, document their paths and whether they replace any procedural drawing currently done in code.
