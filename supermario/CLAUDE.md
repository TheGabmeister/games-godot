# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Godot 4.6 Super Mario Bros recreation. 2D platformer using only primitive shapes (no sprites/textures) — all visuals are code-drawn via `_draw()`, `Polygon2D`, `ColorRect`, etc. Uses Forward Plus renderer for WorldEnvironment bloom/glow effects. See `SPEC.md` for the full design document.

## Running

```bash
godot --path .                     # Run the game
godot --headless --path . --quit   # Headless validation (parse errors, project loading)
```

If `godot` is not on PATH, use: `d:\Godot_v4.6.2-stable_win64.exe`

## Validation

No automated test suite. Validate changes by:
- Running headless to check for script parse errors
- Running the game windowed to verify gameplay

**Known quirk:** `--headless --quit` exits before indexing new `class_name` scripts. We avoid `class_name` declarations and use `preload()` with `res://` paths instead (e.g., `extends "res://scripts/player/player_states/player_state.gd"`).

## Architecture

### Autoloads (loaded in this order)

1. **EventBus** — Pure signal hub. All cross-system communication goes through here. ~30 signals covering player, scoring, enemies, blocks, game state.
2. **GameManager** — Persistent game state: score, coins, lives, timer, power state (`SMALL`/`BIG`/`FIRE`), game state (`TITLE`/`PLAYING`/`PAUSED`/`GAME_OVER`/`LEVEL_COMPLETE`/`TRANSITIONING`).
3. **AudioManager** — Registry-based audio skeleton. SFX/music registries map `StringName` keys to file paths (currently empty — fill paths to add audio). SFX pool of 10+6 players, music crossfade via dual `AudioStreamPlayer`.
4. **SceneManager** — Fade-to-black scene transitions, level intro overlay.
5. **CameraEffects** — Screen shake with decay, freeze frame via time scale dip.

### Player System

The player uses a **state machine with child nodes** pattern:

- `player_controller.gd` (CharacterBody2D) — physics constants, movement helpers, collision shape management
- `state_machine.gd` — delegates `_process`/`_physics_process`/`_unhandled_input` to the active state
- States extend `player_state.gd` base via `extends "res://..."` paths. Each state owns its own transition logic.
- `player_drawer.gd` — procedural `_draw()` rendering for Small/Big/Crouching Mario with walk cycle animation

States transition themselves (e.g., `state_machine.transition_to(&"JumpState")`). The controller provides helpers but doesn't decide when to switch states.

### Level System

- `level_base.gd` — programmatically creates a `TileSet` at runtime via `terrain_tileset.gd`, paints ground/stairs/pits onto a `TileMapLayer`
- Only static terrain uses `TileMapLayer`. Interactive objects (blocks, enemies, items) are individual scene instances placed under container `Node2D` nodes.
- `parallax_controller.gd` — procedural cloud/hill/bush drawing with parallax offset from camera. Looks up the player camera lazily in `_process` (not `_ready`) because the parallax node is earlier in the scene tree than the player.
- Camera: child of player, horizontal follow only, look-ahead offset, `limit_left` ratchets forward to prevent backtracking. Parallax reads `camera.get_screen_center_position()` (not `global_position`) so smoothing/offset are honored.

### Block Bump Detection

Question blocks and brick blocks expose a `bump_from_below()` method. They do NOT use `Area2D` overlap detection — that approach fails because `body_entered` doesn't fire reliably on touching contact, and `velocity.y` is zeroed by `move_and_slide()` before the signal fires.

Instead, the player's `check_ceiling_bumps()` (called from `JumpState` after `move_and_slide`) iterates `get_slide_collision()` looking for collisions with a downward-pointing normal (`normal.y > 0.5`) and calls `bump_from_below()` on the collider if the method exists. Any new interactable block must implement this method to respond to head bumps.

### Color Palette

`color_palette.gd` holds all named color constants. Access via preload: `const P := preload("res://scripts/color_palette.gd")` then `P.MARIO_RED`.

### Collision Layers

Layers 1-10 are named in `project.godot`. Key separation: `CharacterBody2D` nodes only mask layer 1 (Terrain) for physics. `Area2D` nodes handle all overlap detection (stomp, damage, items, killzone) on layers 4-10.

## GDScript Conventions

- Typed signatures: `func name(param: Type) -> ReturnType:`
- `snake_case` for variables/functions, `_prefix` for private
- No `class_name` — use `preload()` paths to avoid headless indexing issues
- Prefer Input Map actions (`&"jump"`, `&"run"`) over hard-coded keys
- Use `res://` paths for all asset/script references
- Only include `_process`/`_physics_process` when actually used

## Working Agreement

- Small, focused edits — keep scripts beginner-readable
- Do not edit generated files: `.godot/*`, `*.import`, `*.uid`
- Be careful editing `project.godot` — malformed entries break project loading
- Preserve existing line endings and formatting
- All visuals must use primitive shapes and `_draw()` — no sprite textures
