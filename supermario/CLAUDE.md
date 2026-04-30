# CLAUDE.md

Guidance for Claude Code (claude.ai/code) when working in this repository.

`README.md` is the developer-facing overview: project pillars, repository
layout, autoloads, system summaries, tunables table, collision layers,
conventions, and architectural decisions. **Read it first.** This file
covers what the README intentionally leaves out: the non-obvious
implementation details, gotchas, and working agreements that only matter
once you start editing code.

## Coding Principles

- **Godot game programming best practices**
- **KISS** — simplest thing that works. 
- **YAGNI** — don't build for hypothetical needs. No abstraction layers "for later."
- **DRY** — remove real duplication, not shape-similar code. Wrong abstraction costs more than repetition.
- **Locality of change** — adding a new entity, tile, or feature should require changes in as few files as possible. 

When in doubt: for code one person owns and rarely changes, lean KISS. For interfaces many contributors touch, lean locality of change.


## Validation

No automated test suite. Validate changes by:
- `godot --headless --path . --quit` to catch script parse errors and missing-resource warnings
- Running the game windowed (`godot --path .`) to verify gameplay
- Spot-checking the relevant subsystem manually after touching it

If `godot` is not on PATH, use `d:\Godot_v4.6.2-stable_win64.exe`.

**Known quirk:** `--headless --quit` exits before indexing new `class_name`
scripts. The project avoids `class_name` entirely; use `preload()` with
`res://` paths instead (e.g., `extends "res://scripts/player/player_states/player_state.gd"`).

## Implementation Notes

These expand on the system summaries in `README.md` with details that aren't
obvious from reading the code in isolation.

### GameManager

- Run-state reset (score / coins / lives / world / level / power) is centralized in `_reset_run_state()`. Both `start_new_game()` and `reset_for_title()` call it — don't duplicate the reset logic.
- Timer ticks (`EventBus.time_tick`) emit only when the displayed integer second changes, deduped via `_last_time_tick`. The cache resets in `start_level_timer()` so the first tick of every level always emits.
- `_enter_level()` has exactly three callers: `start_new_game()`, `advance_to_next_level()`, `respawn_current_level()`. Do not add a fourth — extend one of these.
- Public flow API (no underscore prefix): `start_level_timer`, `stop_level_timer`, `advance_to_next_level`, `respawn_current_level`, `return_to_title`.

### SfxManager and MusicManager

- Audio managers are playback plumbing only. Gameplay/UI callers own `AudioStream` references and emit EventBus audio requests.
- SFX uses `EventBus.sfx_requested(sound)`, handled by `SfxManager`'s pooled `AudioStreamPlayer`s.
- Music uses `EventBus.music_requested(music)`, `music_stop_requested`, and `music_duck_requested(enabled)`, handled by `MusicManager`'s dual-player crossfade setup.

### SceneManager

External callers must use the public API and never tween the internal
`_fade_rect` directly:

- `change_scene(path)` — fade out → swap → fade in
- `change_scene_no_fade(path)` — swap only (use when running your own fade sequence; `GameManager._enter_level` does this)
- `fade_out(duration)` / `fade_in(duration)` — standalone tweens. `duration < 0` uses the config default.
- `show_level_intro(world, level, lives)`

### Player System

- **Public API:** `update_collision_shape`, `start_invincibility`, `die`, `take_damage`, `power_up(item_type, position)`, `enter_pipe(pipe, target)`, `start_flagpole(flagpole)`. The rule: if cross-file code has a legitimate reason to call it, it's public. Do not add an underscore-prefixed wrapper for callers from outside the file.
- **Power-state on spawn:** `player_controller._ready()` calls `update_collision_shape()` so a newly instanced player picks up `GameManager.current_power_state`. Load-bearing for Fire Mario persisting across level transitions — `player.tscn` bakes in the Small collision, so without this line Mario would spawn with the wrong collision box on 1-2 after beating 1-1 as Fire Mario.
- **States transition themselves** (e.g., `state_machine.transition_to(StateIds.JUMP)`). The controller provides movement helpers but does not decide when to switch states.
- **Tunables:** `@export var movement: PlayerMovementConfig` and `@export var effects: EffectsConfig` are wired in `player.tscn`. `CameraConfig` is wired to the `Camera2D` child node, not the player root.

### Camera Controller

- Script lives on the `Camera2D` child of the player. Reads facing from the parent's `Visuals` child for look-ahead direction.
- Self-registers with `CameraEffects` in `_ready()` and reads `get_shake_offset()` per frame, composing it with the look-ahead.
- Exposes `reset_no_backtrack()` for pipe warps to break the `limit_left` ratchet.

### Block Bump Detection

Question/brick blocks expose `bump_from_below()`. They do **not** use `Area2D`
overlap detection — `body_entered` doesn't fire reliably on touching contact,
and `velocity.y` is zeroed by `move_and_slide()` before any signal could fire.

The player's `check_ceiling_bumps()` (called from `JumpState` after
`move_and_slide`) iterates `get_slide_collision()` for collisions with
`normal.y > 0.5` and calls `bump_from_below()` on the collider if the method
exists. Any new interactable solid block must implement this method.

`block_base.gd` owns the bump animation state (`_bumping`, `_bump_time`,
`_bump_offset`) and the per-frame tween. Subclasses (`brick_block`,
`question_block`, `hidden_block`) call `start_bump()` to kick it off; the base
handles the tween and `queue_redraw()`.

**Hidden blocks are different.** They start with `CollisionShape2D.disabled = true`
so the player passes through them — slide-iteration cannot detect them. Instead,
a child `Area2D` monitors the Player layer (`collision_mask = 2`) and listens
for `body_entered`, checks `body.velocity.y < 0` (player moving up), then
enables the `StaticBody2D` collision via `set_deferred("disabled", false)`.
This is the canonical pattern for any "toggle-able collision" block — don't
shoehorn the slide-iteration approach.

### Item Spawning and `_ready()` Timing

In Godot 4, `_ready()` fires **synchronously inside `add_child()`**, before
any subsequent lines in the caller run. Items that need to know their spawn
position must **not** capture it in `_ready()`. The convention is
**lazy-initialization on the first tick**.

`emerge_helper.gd` (`RefCounted`) is the shared helper — captures start position
lazily, runs the upward tween. `mushroom.gd`, `fire_flower.gd`, and `starman.gd`
compose with it via `var _emerge := EmergeHelper.new()`. Note: `coin_pop.gd`
uses an older inline `_initialized` flag (it captures `spawn_y` rather than
tweening over a fixed distance, so the helper doesn't quite apply).

### Enemy System

- Stomp vs damage: both `StompDetector` (feet, masks layer 5) and `Hurtbox` (body, on layer 4 masks layer 5) may fire for the same enemy in one frame. The hurtbox handler skips damage when the player is above and the enemy is stompable. Enemies returning `is_stompable() -> false` (e.g., piranha plants) bypass this guard and always damage on contact.
- `koopa_shell.gd` is a standalone `CharacterBody2D` with IDLE/MOVING states and combo kill tracking. Koopa spawns it on stomp.
- `enemy_base._disable_all_collision()` zeros `collision_layer` / `collision_mask` and disables hitbox `monitoring`/`monitorable`. Called from death-animation paths in `enemy_base.gd` and `goomba.gd`.

### Pipe Warp

- `pipe.gd` (StaticBody2D) draws via `_draw()` and manages a `WarpZone` `Area2D` on top. When the player is on the zone, grounded, and presses down, `player.enter_pipe(self, target)` is called.
- **Z-ordering:** Player default `z_index` is 10 (set in `player.tscn`). Pipes are at 5 with `z_as_relative = false`. `PipeEnterState.enter()` caches the previous `z_index`, drops it to 0 (below the pipe rim), and `exit()` restores it. Don't mutate `z_index` from the pipe script — the state owns that lifecycle so death-during-warp can't leave Mario stuck behind geometry.
- During the tween, the player's `CollisionShape2D.disabled` is toggled via `set_deferred`. Velocity is zeroed and `apply_gravity()` / `move_and_slide()` are skipped — position is driven by Tween directly. Re-enable on exit (also deferred to avoid a one-frame overlap at the destination pipe).

### Effects Spawning

`effects_manager._spawn_effect(script, pos, z)` does the
`Node2D.new() + set_script() + add_child()` dance in one place. Effects are
not `.tscn` scenes — they're scriptless `Node2D`s with a script attached at
runtime (see the comment above `_spawn_effect` for the rationale).

To add an effect: write a `Node2D`-extending script with its own `_process`
/ `_draw` / lifetime, preload it, and call `_spawn_effect()` from the
appropriate signal handler.

Player-attached effects (`damage_flash`, `motion_trail`) are wired directly
in `player.tscn`, not via the effects manager.

### Grow / Shrink Pause Rule

`GrowState` and `ShrinkState` freeze gameplay via `get_tree().paused = true`.
The player node is `PROCESS_MODE_ALWAYS` so the flicker animation continues.
On exit, the tree is unpaused and the player returns to its previous state
(cached via `state_machine.previous_state_name`). The collision shape is
resized once at the end, not during the flicker.

Any node that must keep running during grow/shrink needs `PROCESS_MODE_ALWAYS`
(e.g., the power-up ring effect). The `SceneManager` overlay uses a high
`CanvasLayer` and is unaffected.

### Parallax

`parallax_controller.gd` looks up the player camera lazily in `_process` (not
`_ready`) because the parallax node is earlier in the scene tree than the
player. It reads `camera.get_screen_center_position()` (not `global_position`)
so smoothing and offset are honored.

### UI Behavior

- **Title screen** resets `GameManager` on load and has a 0.3s input delay to prevent stale presses carrying over from the previous run.
- **Pause menu** (`PROCESS_MODE_WHEN_PAUSED`) ducks music while paused.
- **Level complete** calls `GameManager.advance_to_next_level()`, which handles both the "next level" and "no more levels → title" cases.

### Shared Helpers

Reach for these instead of re-pasting boilerplate:

- `scripts/objects/block_base.gd` — bump animation state for all interactable blocks (extends `StaticBody2D`).
- `scripts/objects/emerge_helper.gd` — lazy-init + vertical tween for items that emerge from question blocks.
- `scripts/level/tileset_builder.gd` — `create_tileset(top_color, fill_color)` returns a 2-tile atlas with collision polygons. Used by both `level_base.gd` (overworld) and `level_1_2.gd` (underground), passing colors from `color_palette.gd`.
- `enemy_base._disable_all_collision()` — used in death-animation paths.

## Gotchas

### TileSet Collision Polygon Origin

In Godot 4's TileSet, collision polygon coordinates are relative to the
**tile center**, not the top-left. A full-tile collision polygon must be
offset by half the tile size:

```gdscript
var half: int = TILE_SIZE / 2
var polygon := PackedVector2Array([
    Vector2(-half, -half), Vector2(TILE_SIZE - half, -half),
    Vector2(TILE_SIZE - half, TILE_SIZE - half), Vector2(-half, TILE_SIZE - half),
])
```

Using `(0, 0)` to `(TILE_SIZE, TILE_SIZE)` shifts the collision 16 px right and
down from the visual.

### Shared Sub-Resources in Instanced Scenes

Scene `.tscn` sub-resources (like `RectangleShape2D`) are **shared across all
instances** of that scene. Modifying a shape at runtime (e.g., resizing a
pipe's collision based on `pipe_height`) mutates it for every instance. Fix:
create a new shape per instance in `_ready()`:

```gdscript
var body_shape := RectangleShape2D.new()
body_shape.size = Vector2(32, h)
_col_shape.shape = body_shape
```

### One-Shot Guards

Any callback that triggers a scene transition, life loss, or level completion
needs a one-shot guard to prevent firing every frame. `DeathState` uses
`_life_lost`; `FlagpoleState` advances to `_phase = 3` before emitting
`level_completed`.

## Working Agreement

- Small, focused edits — keep scripts beginner-readable.
- Do not edit generated files: `.godot/*`, `*.import`, `*.uid`.
- Be careful editing `project.godot` — a single malformed line breaks project loading.
- Preserve existing line endings and formatting.
- All visuals must use primitive shapes and `_draw()` — no sprite textures.
- Conventions in `README.md` (typed signatures, no `class_name`, `StateIds` over string literals, `_prefix` privacy) apply.

## Asset Pipeline

- **Sprites**: each entity/item gets its own SVG and PNG file, exported via Inkscape. 
  - Inkscape path: `"/c/Program Files/Inkscape/bin/inkscape.exe"`. Export: `inkscape input.svg --export-type=png --export-filename=output.png -w 64 -h 64`.
- **Sounds**: generate with rfxgen (`"D:/rfxgen_v5.0_win_x64/rfxgen.exe" -g coin -o sound.wav`).
- **Music**: Python scripts in `tools/music/` use `midiutil` to generate MIDI -> FluidSynth renders with a soundfont to WAV -> ffmpeg converts to OGG. Tool paths: `D:/fluidsynth-v2.5.4-win10-x64-cpp11/bin/fluidsynth.exe`, `D:/ffmpeg-8.1-essentials_build/bin/ffmpeg.exe`, soundfont `D:/GeneralUser-GS/GeneralUser-GS.sf2`.  
