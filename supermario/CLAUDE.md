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
- For larger features, follow the per-phase manual checklists in `SPEC.md` §15 (each phase has a **Testing & verification** block with headless checks, manual gameplay steps, and a bug watchlist — use these as gates before moving on)

**Known quirk:** `--headless --quit` exits before indexing new `class_name` scripts. We avoid `class_name` declarations and use `preload()` with `res://` paths instead (e.g., `extends "res://scripts/player/player_states/player_state.gd"`).

## SPEC.md and Phase Structure

`SPEC.md` is the design authority. All 10 implementation phases (§15) are complete. The project has: full World 1-1 and World 1-2 levels, Fire Mario/fireballs, starman, piranha plants, pipe warps, flagpole sequence, title screen, pause menu, game over, level complete flow, and audio wiring (registry-based, asset paths empty until audio files are added).

When in doubt: read the relevant §9/§14/§15 subsection before touching code. Spec decisions are binding and many gotchas are documented there.

## Architecture

### Autoloads (loaded in this order)

1. **EventBus** — Pure signal hub. All cross-system communication goes through here. ~30 signals covering player, scoring, enemies, blocks, game state.
2. **GameManager** — Persistent game state: score, coins, lives, timer, power state (`SMALL`/`BIG`/`FIRE`), game state (`TITLE`/`PLAYING`/`PAUSED`/`GAME_OVER`/`LEVEL_COMPLETE`/`TRANSITIONING`). Level progression via `LEVEL_SCENES` dictionary and `LEVEL_ORDER` array. Run-state reset (score/coins/lives/world/level/power) is centralized in `_reset_run_state()` — both `start_new_game()` and `reset_for_title()` call it. Timer ticks (`EventBus.time_tick`) are emitted only when the displayed integer second changes, deduped via `_last_time_tick`. The cache resets in `start_level_timer()` so the first tick of every level always emits.
3. **AudioManager** — Registry-based audio. SFX/music registries map `StringName` keys to file paths (currently empty — fill paths to add audio). Unknown keys log a warning. SFX pool of 10+6 players, music crossfade via dual `AudioStreamPlayer`. All EventBus-to-audio wiring is already connected. Streams are loaded lazily via `_get_sfx_stream()` / `_get_music_stream()` and cached in `_sfx_streams` / `_music_streams` dictionaries — `load()` runs at most once per asset per session, then subsequent plays are pure dictionary lookups.
4. **SceneManager** — Fade-to-black scene transitions and level intro overlay. Public API: `change_scene(path)` (fade out → swap → fade in), `change_scene_no_fade(path)` (swap only — use when the caller is running its own fade sequence, as `GameManager._enter_level` does), `fade_out(duration)` / `fade_in(duration)` (standalone tweens, `duration < 0` uses the config default), `show_level_intro(world, level, lives)`. External callers should never reach in and tween the internal `_fade_rect` directly; use these methods.
5. **CameraEffects** — Screen shake with decay (exposes `get_shake_offset()` — does NOT write to camera directly), freeze frame via time scale dip. The camera controller (script on the player's `Camera2D` child) reads the shake offset every frame and composes it with its look-ahead.
6. **Palette** — `res://scripts/color_palette.gd`. Constants-only script holding every named color used by `_draw()` methods. Accessed as `Palette.MARIO_RED`, `Palette.PIPE_GREEN`, etc. No per-file preload needed.

### Game Flow

```
Title Screen → GameManager.start_new_game() → _enter_level(1-1)
                                                  → TRANSITIONING
                                                  → fade_out
                                                  → scene swap
                                                  → show_level_intro (2.5s)
                                                  → PLAYING + timer start
  → Flagpole → EventBus.level_completed → level_complete tally
             → GameManager.advance_to_next_level() → _enter_level(next) or return_to_title()
  → Death → lose_life() → lives > 0 → respawn_current_level.call_deferred()
                                     → power reset to SMALL → _enter_level(current)
  → Death → lose_life() → lives = 0 → GAME_OVER → game_over_screen (3s) → return_to_title()
  → Pause (Escape) → Resume
```

**GameManager owns the entire level-transition flow.** Level scripts (`level_base.gd`, `level_1_2.gd`) are pure scene construction — they paint terrain and set up the camera, but they do not touch run state, timers, or the intro overlay. All transitions go through `GameManager._enter_level(scene_path)`, which sets `TRANSITIONING`, fades out, swaps the scene via `SceneManager.change_scene_no_fade()`, runs the intro overlay via `SceneManager.show_level_intro()`, sets `PLAYING`, and starts the timer. There are exactly three callers: `start_new_game()` (from title screen, full state reset), `advance_to_next_level()` (from `level_complete.gd`, preserves power/coins/score/lives), and `respawn_current_level()` (deferred from `lose_life()` after death, resets power to SMALL). `return_to_title()` handles the non-gameplay transition to the title screen. Do not add a fourth entry point — extend one of these instead.

### Player System

The player uses a **state machine with child nodes** pattern:

- `player_controller.gd` (CharacterBody2D) — movement helpers, collision shape management, stomp/damage handling, fireball shooting, star power, pipe entry, flagpole grab. Tunables come from `@export var movement: PlayerMovementConfig` and `@export var effects: EffectsConfig` wired in `player.tscn`.
- `camera_controller.gd` — script attached to the `Camera2D` child of the player. Owns look-ahead in the facing direction, screen-shake compositing (via `CameraEffects.get_shake_offset()`), and the no-backtrack `limit_left` ratchet. Reads facing from the parent's `Visuals` child. Exposes `reset_no_backtrack()` for pipe warps. Self-registers with `CameraEffects` in `_ready()`.
- `state_machine.gd` — delegates `_process`/`_physics_process`/`_unhandled_input` to the active state
- States extend `player_state.gd` base via `extends "res://..."` paths. Each state owns its own transition logic.
- `player_drawer.gd` — procedural `_draw()` rendering for Small/Big/Crouching Mario with walk cycle animation and star power palette cycling

States: `IdleState`, `RunState`, `JumpState`, `FallState`, `CrouchState`, `DeathState`, `GrowState`, `ShrinkState`, `PipeEnterState`, `FlagpoleState`.

**State IDs:** All state-name references go through `scripts/player/player_state_ids.gd` — a constants-only `RefCounted` preloaded as `const StateIds := preload(...)`. Callers use `state_machine.transition_to(StateIds.JUMP)`, not `&"JumpState"` string literals. A rename in the scene tree would be silent with string literals; the `StateIds` indirection gives you one place to update.

States transition themselves (e.g., `state_machine.transition_to(StateIds.JUMP)`). The controller provides helpers but doesn't decide when to switch states.

**Public player API:** `update_collision_shape()`, `start_invincibility()`, `die()`, `take_damage()`, `power_up(item_type, position)`, `enter_pipe(pipe, target)`, `start_flagpole(flagpole)` are public because external callers (states, items, enemies) need them. Do not add underscore-prefixed versions — the rule is: if cross-file code has a legitimate reason to call it, it's public. Same rule on `GameManager`: `start_level_timer()` / `stop_level_timer()` / `advance_to_next_level()` / `respawn_current_level()` / `return_to_title()` are the public flow API, not underscore helpers.

**Power-state on spawn:** `player_controller._ready()` calls `update_collision_shape()` so a newly instanced player picks up `GameManager.current_power_state`. Load-bearing for Fire Mario persisting across level transitions — the scene file bakes in the Small collision, so without this line the player would spawn with the wrong collision box on 1-2 after beating 1-1 as Fire Mario.

**Star power:** Managed by `_is_star_powered` flag on the player controller (not a state). 10-second duration, palette cycling in drawer, kills enemies on hurtbox contact, warning flashes in last 2 seconds.

**Fireballs:** Fire Mario shoots on `run` press, max 2 tracked via `_active_fireballs` counter. Fireballs are standalone `CharacterBody2D` scenes that self-destruct on wall/enemy contact. The counter decrements via `tree_exited` callback.

### Level System

- `level_base.gd` (World 1-1) — programmatically creates a `TileSet` at runtime via `tileset_builder.gd` (passing `GROUND_GREEN` / `GROUND_BROWN` from the palette), paints ground/stairs/pits onto a `TileMapLayer`. **Pure scene construction only** — does not drive the intro overlay, timer, or respawn. All run-state flow is owned by `GameManager._enter_level()`.
- `level_1_2.gd` (World 1-2) — underground variant using `tileset_builder.gd` with `UNDERGROUND_DARK` / `UNDERGROUND_BASE`, ceiling tiles, raised platforms. Same construction-only rule: no flow logic.
- Only static terrain uses `TileMapLayer`. Interactive objects (blocks, enemies, items) are individual scene instances placed under container `Node2D` nodes.
- `parallax_controller.gd` — procedural cloud/hill/bush drawing with parallax offset from camera. Looks up the player camera lazily in `_process` (not `_ready`) because the parallax node is earlier in the scene tree than the player.
- Camera: child of player, horizontal follow only, look-ahead offset, `limit_left` ratchets forward to prevent backtracking. Parallax reads `camera.get_screen_center_position()` (not `global_position`) so smoothing/offset are honored.

### Block Bump Detection

Question blocks and brick blocks expose a `bump_from_below()` method. They do NOT use `Area2D` overlap detection — that approach fails because `body_entered` doesn't fire reliably on touching contact, and `velocity.y` is zeroed by `move_and_slide()` before the signal fires.

Instead, the player's `check_ceiling_bumps()` (called from `JumpState` after `move_and_slide`) iterates `get_slide_collision()` looking for collisions with a downward-pointing normal (`normal.y > 0.5`) and calls `bump_from_below()` on the collider if the method exists. Any new interactable block must implement this method to respond to head bumps.

The block animation state (`_bumping`, `_bump_time`, `_bump_offset`) and the per-frame tween live in `block_base.gd`, which `brick_block.gd`, `question_block.gd`, and `hidden_block.gd` all extend via `extends "res://scripts/objects/block_base.gd"`. Subclasses call `start_bump()` on the base to kick off the animation; the base's `_process` handles the tween and `queue_redraw()`.

**Contrast: hidden blocks.** Hidden blocks start with `CollisionShape2D.disabled = true` so the player passes through them. The slide-iteration pattern cannot detect them (no collision to slide against). `hidden_block.gd` uses a different pattern: a child `Area2D` monitoring the Player layer (`collision_mask = 2`) listens for `body_entered`, checks `body.velocity.y < 0` (player moving up), then enables the `StaticBody2D` collision via `set_deferred("disabled", false)`. This is the canonical pattern for any "toggle-able collision" block — don't try to shoehorn the slide-iteration approach.

### Item Spawning and `_ready()` Timing

In Godot 4, `_ready()` fires **synchronously inside `add_child()`**, before any subsequent lines in the caller run. Items that need to know their spawn position (e.g., for emerge animations) must **not** capture it in `_ready()`. The project convention is **lazy-initialization on the first tick**. The shared `EmergeHelper` (`scripts/objects/emerge_helper.gd`) is a `RefCounted` that captures the start position lazily and runs the upward tween. `mushroom.gd`, `fire_flower.gd`, and `starman.gd` compose with it via `var _emerge := EmergeHelper.new()`. Note: `coin_pop.gd` uses the older inline `_initialized` flag pattern — if you touch it, consider whether the helper applies (it doesn't quite, since coin_pop just captures spawn_y rather than tweening over a fixed distance).

### Enemy System

Enemies use the same state-machine-like pattern as the player but simpler:

- `enemy_base.gd` (CharacterBody2D) — gravity, patrol movement, wall reversal, flip-death animation. Reads speed/gravity from `@export var config: Resource` (EnemyConfig).
- `goomba.gd` / `koopa.gd` extend enemy_base. Koopa spawns a `koopa_shell.tscn` on stomp.
- `koopa_shell.gd` — standalone CharacterBody2D with IDLE/MOVING state machine, combo kill tracking.
- `piranha_plant.gd` — Node2D (not CharacterBody2D). Tween-based emerge/retract. Not stompable (`is_stompable() -> false`). Vulnerable to fireballs and star power. Hitbox disabled when fully retracted.
- `enemy_spawner.gd` — script on the Enemies container node. Activates children when camera approaches within `activation_distance` pixels. Cleans up enemies far behind camera.

**Stomp vs damage detection:** Player has two Area2D children:
- `StompDetector` (at feet, masks Layer 5 EnemyHitbox) — `area_entered` checks `velocity.y > 0` for stomps
- `Hurtbox` (body area, on Layer 4, masks Layer 5) — `area_entered` handles damage

Both may fire for the same enemy in the same frame. The hurtbox handler skips damage when the player is above the enemy and the enemy is stompable. Enemies that return `is_stompable() -> false` (like piranha plants) bypass this guard and always damage on contact.

**Enemy methods used by duck typing:** `stomp_kill() -> bool`, `is_stompable() -> bool`, `is_dangerous() -> bool`, `try_kick(direction) -> bool`, `shell_kill()`, `non_stomp_kill()`, `activate()`, `is_active() -> bool`, `die()`.

### Pipe Warp System

`pipe.gd` (StaticBody2D) draws the pipe via `_draw()` and manages a `WarpZone` Area2D on top. When the player is on the zone, grounded, and presses down, `player.enter_pipe(self, target)` is called.

`PipeEnterState` disables collision, drops `z_index` to 0 (below pipe's 5), tweens player down behind the pipe, fades via SceneManager, repositions at target pipe, tweens out, restores `z_index` to 10, re-enables collision.

**Player z_index:** Default is 10 (set in `player.tscn`). Pipes are at 5 (`z_as_relative = false`). During pipe entry, player drops to 0, restored on exit.

### Effects System

`effects_manager.gd` (Node2D in the level scene) listens to EventBus signals and spawns visual effects:
- `score_popup.gd` — rising/fading point numbers on `score_awarded`
- `brick_particle.gd` — tumbling fragments on `block_broken`
- `stomp_puff.gd` — expanding particle ring on `enemy_stomped`
- `coin_pop.gd` — spinning coin arc on `item_spawned(&"coin")`

Player-attached effects: `damage_flash.gd` (red tint on `player_damaged`), `motion_trail.gd` (afterimages at top speed).

All four effects-manager spawns go through `_spawn_effect(script, pos, z)` — a private helper that does the `Node2D.new() + set_script() + add_child()` dance in one place. Adding a new effect is: write the script (extends `Node2D`, owns its own `_process`/`_draw`/lifetime), preload it, call `_spawn_effect()` from the appropriate signal handler. Effects are *not* `.tscn` scenes — see the comment above `_spawn_effect` for the rationale.

### Shared Helpers

Several small helper scripts encapsulate patterns that were duplicated across multiple files. Reach for these instead of re-pasting boilerplate:

- `scripts/objects/block_base.gd` — bump animation state for all interactable blocks (extends `StaticBody2D`).
- `scripts/objects/emerge_helper.gd` — lazy-init + vertical tween for items that emerge from question blocks (`RefCounted`, composed via `var _emerge := EmergeHelper.new()`).
- `scripts/level/tileset_builder.gd` — parameterized procedural TileSet builder. `create_tileset(top_color, fill_color)` returns a 2-tile atlas with collision polygons. Used by `level_base.gd` (overworld) and `level_1_2.gd` (underground), both passing colors from `color_palette.gd`.
- `enemy_base._disable_all_collision()` — sets `collision_layer = 0`, `collision_mask = 0`, and disables the hitbox's `monitoring` and `monitorable`. Called from death-animation paths in `enemy_base.gd` and `goomba.gd`.

### UI Layer

- **Title screen** (`title_screen.gd`) — main scene in `project.godot`. Resets GameManager on load. 0.3s input delay prevents stale presses carrying over.
- **Pause menu** (`pause_menu.gd`) — `PROCESS_MODE_WHEN_PAUSED` CanvasLayer. Toggles `get_tree().paused` and ducks music.
- **Game over** (`game_over_screen.gd`) — `PROCESS_MODE_ALWAYS`. Shows 3s on `game_over` signal, returns to title.
- **Level complete** (`level_complete.gd`) — `PROCESS_MODE_ALWAYS`. Score tally, then calls `GameManager.advance_to_next_level()` which handles both the "next level" and "no more levels → title" cases.

### Grow/Shrink States and Pause Rule

`GrowState` and `ShrinkState` freeze gameplay via `get_tree().paused = true` while the player flickers between forms. The player node is set to `PROCESS_MODE_ALWAYS` so the animation continues. On exit, the tree is unpaused and the player returns to the state it came from (cached via `state_machine.previous_state_name`). The collision shape is resized once at the end, not during the flicker.

**Caution:** Any node that must keep running during grow/shrink needs `PROCESS_MODE_ALWAYS` (e.g., the power-up ring effect). The SceneManager overlay already uses a high CanvasLayer and is unaffected.

### Color Palette

`color_palette.gd` holds all named color constants and is registered as the `Palette` autoload in `project.godot`. Access directly — `Palette.MARIO_RED`, `Palette.PIPE_GREEN`, etc. No per-file preload needed.

### Collision Layers

Layers 1-10 are named in `project.godot`. Key separation: `CharacterBody2D` nodes only mask layer 1 (Terrain) for physics. `Area2D` nodes handle all overlap detection (stomp, damage, items, killzone) on layers 4-10. Layer 7 (Fireballs) is used by fireball hitboxes to detect enemy hitboxes on layer 5.

## Gotchas

### TileSet Collision Polygon Origin

In Godot 4's TileSet, collision polygon coordinates are relative to the **tile center**, not the top-left. A full-tile collision polygon must be offset by half the tile size:

```gdscript
var half: int = TILE_SIZE / 2
var polygon := PackedVector2Array([
    Vector2(-half, -half), Vector2(TILE_SIZE - half, -half),
    Vector2(TILE_SIZE - half, TILE_SIZE - half), Vector2(-half, TILE_SIZE - half),
])
```

Using `(0, 0)` to `(TILE_SIZE, TILE_SIZE)` shifts the collision 8px right and down from the visual.

### Shared Sub-Resources in Instanced Scenes

Scene `.tscn` sub-resources (like `RectangleShape2D`) are **shared across all instances** of that scene. Modifying a shape at runtime (e.g., resizing a pipe's collision based on `pipe_height`) mutates it for every instance. Fix: create a new shape per instance in `_ready()`:

```gdscript
var body_shape := RectangleShape2D.new()
body_shape.size = Vector2(32, h)
_col_shape.shape = body_shape
```

### One-Shot Guards

Any callback that triggers a scene transition, life loss, or level completion must have a one-shot guard to prevent firing every frame. Examples: `DeathState` has `_life_lost`, `FlagpoleState` advances to `_phase = 3` before emitting `level_completed`.

## Tunables

Gameplay tunables live in Godot `Resource` files (`.tres`) under `resources/config/`, with script definitions in `scripts/config/`. Each script extends `Resource` with `@export` vars. Consuming scripts declare `@export var config: Resource` and are wired to the `.tres` in their scene file.

**Current config resources:**
- `PlayerMovementConfig` — walk/run speed, gravity, jump, coyote time, collision sizes, stomp bounce, invincibility
- `CameraConfig` — look-ahead distance/speed, smoothing, no-backtrack offset (wired to the `Camera2D` node in `player.tscn`, not the player root)
- `EnemyConfig` — patrol speed, gravity (one `.tres` per enemy type: goomba, koopa)
- `BlockBumpConfig` — bump amplitude/duration, pulse frequency (shared by all block types)
- `ItemConfig` — mushroom speed/gravity, emerge height/duration
- `LevelTimingConfig` — intro duration, fade duration, death timing
- `EffectsConfig` — score popup speed, damage flash duration, trail spacing, grow/shrink rate

**Pattern:** Scripts that are scene-instanced (player, enemies, blocks, items) use `@export` wired in the `.tscn`. Autoloads and state nodes that can't use `@export` use `const preload("res://resources/config/...")` as a justified exception.

**Do not introduce a centralized `settings.gd` god-object.** The agreed direction is per-category `Resource` subclasses, not a single config file. `ProjectSettings` is reserved for truly global flags (difficulty, debug toggles), not gameplay values. New tunables go in the appropriate existing config resource, or a new one if no category fits.

## GDScript Conventions

- Typed signatures: `func name(param: Type) -> ReturnType:`
- `snake_case` for variables/functions, `_prefix` for private — and it means it. If external code needs to call something, make it public; do not reach across files into an underscore-prefixed member.
- No `class_name` — use `preload()` paths to avoid headless indexing issues
- Prefer Input Map actions (`&"jump"`, `&"run"`) over hard-coded keys
- Use `res://` paths for all asset/script references
- Only include `_process`/`_physics_process` when actually used
- Reference player states via `StateIds.X` (preloaded from `res://scripts/player/player_state_ids.gd`), not `&"XState"` string literals — a rename in the scene tree is silent otherwise.

## Working Agreement

- Small, focused edits — keep scripts beginner-readable
- Do not edit generated files: `.godot/*`, `*.import`, `*.uid`
- Be careful editing `project.godot` — malformed entries break project loading
- Preserve existing line endings and formatting
- All visuals must use primitive shapes and `_draw()` — no sprite textures
