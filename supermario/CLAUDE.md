# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

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

## Implementation Notes

These expand on the system summaries in `README.md` with details that aren't
obvious from reading the code in isolation.

### GameManager

- `.gd` autoloads can't use `@export`, so game-wide config lives in `resources/config/game_config.tres` (a `GameConfig` resource), loaded via `preload`.
- Run-state reset (score / coins / lives / power) is centralized in `_reset_run_state()`. Both `start_new_game()` and `reset_for_title()` call it — don't duplicate the reset logic.
- `_enter_level()` has exactly three callers: `start_new_game()`, `advance_to_next_level()`, `respawn_current_level()`. Do not add a fourth — extend one of these.
- Music playback is triggered by GameManager in `_start_level()` from the level config — level scenes do not handle music.
- **GameManager owns the level timer tick.** It stores `time_remaining` and `_timer_active`, drives the countdown in `_process()`, emits `EventBus.time_tick`, and calls `_player.die()` on timeout.
- **`_spawn_player()`** instances the player scene, positions it at the `PlayerStart` marker, and subscribes to the player's `died` and `death_animation_finished` signals.
- GameManager has `process_mode = PROCESS_MODE_ALWAYS` so it runs during pause and other tree-paused states.

### Player System

- **Signals:** `died` (emitted from `die()`), `death_animation_finished` (emitted from `DeathState` when the bounce animation ends). GameManager subscribes to both — the player does not call GameManager directly for death/life logic.
- **Public API:** `update_collision_shape`, `start_invincibility`, `die`, `take_damage`, `power_up(item_type, position)`, `enter_pipe(pipe, target)`, `start_flagpole(flagpole)`. The rule: if cross-file code has a legitimate reason to call it, it's public. Do not add an underscore-prefixed wrapper for callers from outside the file.
- **Power-state on spawn:** `player_controller._ready()` calls `update_collision_shape()` so a newly instanced player picks up `GameManager.current_power_state`. Load-bearing for Fire Mario persisting across level transitions — `player.tscn` bakes in the Small collision, so without this line Mario would spawn with the wrong collision box on 1-2 after beating 1-1 as Fire Mario.

### Camera Controller

- Reads facing from the parent's `Visuals` child for look-ahead direction.
- Auto-detects level bounds from the first `TileMapLayer` in the scene via `get_used_rect()`. No manual camera setup needed in level scenes.
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
`_bump_offset`) and the per-frame tween in `_process()`. Subclasses (`brick_block`,
`question_block`, `hidden_block`) call `start_bump()` to kick it off; the base
handles the tween and subclass scripts update their `AnimatedSprite2D` position
from `_bump_offset`.

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

### Pickup System

Pickups use composition over inheritance. Each pickup keeps its natural node
type (`Area2D` for static pickups like coins/fire flowers, `CharacterBody2D`
for moving pickups like mushrooms/starman/1-up) and shares collection logic
via `PickupHelper` (`scripts/pickups/pickup_helper.gd`), a `RefCounted` that
handles the collected guard, optional sound, and `queue_free()`.

Usage: `var _pickup := PickupHelper.new()`, then call
`_pickup.try_collect(self, sound)` in the body-entered callback. Returns
`false` if already collected.

### Enemy System

- `koopa_shell.gd` is a standalone `CharacterBody2D` with IDLE/MOVING states and combo kill tracking. Koopa spawns it on stomp.
- `enemy_base._disable_all_collision()` zeros `collision_layer` / `collision_mask` and disables hitbox `monitoring`/`monitorable`. Called from death-animation paths in `enemy_base.gd` and `goomba.gd`.

### Pipe Warp

- `pipe.gd` (StaticBody2D) uses `AnimatedSprite2D` child nodes (cap + body sprites) configured in `pipe.tscn`. The `_build_sprites()` method sets animation names and positions based on `pipe_height`. A `WarpZone` `Area2D` sits on top. When the player is on the zone, grounded, and presses down, `player.enter_pipe(self, target)` is called.
- **Z-ordering:** Player default `z_index` is 10 (set in `player.tscn`). Pipes are at 5 with `z_as_relative = false`. `PipeEnterState.enter()` caches the previous `z_index`, drops it to 0 (below the pipe rim), and `exit()` restores it. Don't mutate `z_index` from the pipe script — the state owns that lifecycle so death-during-warp can't leave Mario stuck behind geometry.
- During the tween, the player's `CollisionShape2D.disabled` is toggled via `set_deferred`. Velocity is zeroed and `apply_gravity()` / `move_and_slide()` are skipped — position is driven by Tween directly. Re-enable on exit (also deferred to avoid a one-frame overlap at the destination pipe).

### Effects

To add an effect: create a `.tscn` scene with a `Node2D` root and script,
preload it in `effects_manager.gd`, and call `_spawn_effect()` from the
appropriate signal handler.

### Grow / Shrink Pause Rule

`GrowState` and `ShrinkState` freeze gameplay via `get_tree().paused = true`.
The player node is `PROCESS_MODE_ALWAYS` so the flicker animation continues.
On exit, the tree is unpaused and the player returns to its previous state
(cached via `state_machine.previous_state_name`). The collision shape is
resized once at the end, not during the flicker.

Any node that must keep running during grow/shrink needs `PROCESS_MODE_ALWAYS`
(e.g., the power-up ring effect).

### UI Behavior

- **Title screen** resets `GameManager` on load and has a 0.3s input delay to prevent stale presses carrying over from the previous run. Accepts `start`, `jump`, or `pause` actions.

### Shared Helpers

Reach for these instead of re-pasting boilerplate:

- `scripts/objects/block_base.gd` — bump animation state for all interactable blocks (extends `StaticBody2D`).
- `scripts/objects/emerge_helper.gd` — lazy-init + vertical tween for items that emerge from question blocks.
- `scripts/pickups/pickup_helper.gd` — collected guard + sound + queue_free for all pickups.
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
`_life_lost` before emitting `death_animation_finished`; `FlagpoleState`
advances to `_phase = 3` before emitting `level_completed`.

### GDScript Typed Array Invariance

GDScript typed arrays are invariant: `Array[SubType]` does not assign to
`Array[ParentType]`. When a config resource types an array as
`Array[LevelConfig]`, a consumer script that preloads the `.tres` may see it
as `Array[Resource]`. Use `Resource` in function signatures when accepting
elements from cross-script typed arrays.

## Working Agreement

- Small, focused edits — keep scripts beginner-readable.
- Do not edit generated files: `.godot/*`, `*.import`, `*.uid`.
- Be careful editing `project.godot` — a single malformed line breaks project loading.
- Preserve existing line endings and formatting.
- Visuals come from generated sprite sheets in `sprites/`. To change art, edit `tools/sprites/generate_sprites.py` and re-run it; do not hand-edit the PNG/SVG outputs. Then run `generate_sprite_frames.py` to update the `SpriteFrames` resources.
- Conventions in `README.md` (typed signatures, no `class_name`, `StateIds` over string literals, `_prefix` privacy) apply.

## Asset Pipeline — Tool Paths

- **Inkscape**: `"/c/Program Files/Inkscape/bin/inkscape.exe"`. Export: `inkscape input.svg --export-type=png --export-filename=output.png -w 64 -h 64`.
- **rfxgen**: `"D:/rfxgen_v5.0_win_x64/rfxgen.exe" -g coin -o sound.wav`. SFX files live in `audio/sfx/` as `.wav`.
