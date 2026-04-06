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

`SPEC.md` is the design authority. The project is **mid-implementation** — currently through Phase 6 of 10 phases in §15. Many features described in SPEC.md are **intentionally deferred** to later phases, including pipe warps, fireballs, starman, menus, and audio wiring. Before "fixing" something that looks missing, check §15 to see if it's a deferred feature — introducing it early is scope creep, not a bug fix.

When in doubt: read the relevant §9/§14/§15 subsection before touching code. Spec decisions are binding and many gotchas are documented there.

## Architecture

### Autoloads (loaded in this order)

1. **EventBus** — Pure signal hub. All cross-system communication goes through here. ~30 signals covering player, scoring, enemies, blocks, game state.
2. **GameManager** — Persistent game state: score, coins, lives, timer, power state (`SMALL`/`BIG`/`FIRE`), game state (`TITLE`/`PLAYING`/`PAUSED`/`GAME_OVER`/`LEVEL_COMPLETE`/`TRANSITIONING`).
3. **AudioManager** — Registry-based audio skeleton. SFX/music registries map `StringName` keys to file paths (currently empty — fill paths to add audio). SFX pool of 10+6 players, music crossfade via dual `AudioStreamPlayer`.
4. **SceneManager** — Fade-to-black scene transitions, level intro overlay.
5. **CameraEffects** — Screen shake with decay (exposes `get_shake_offset()` — does NOT write to camera directly), freeze frame via time scale dip. The player controller composes shake offset with its own look-ahead offset each frame.

### Player System

The player uses a **state machine with child nodes** pattern:

- `player_controller.gd` (CharacterBody2D) — movement helpers, collision shape management, stomp/damage handling. Tunables come from `@export` Resource configs (see Tunables section).
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

**Contrast: hidden blocks.** Hidden blocks start with `CollisionShape2D.disabled = true` so the player passes through them. The slide-iteration pattern cannot detect them (no collision to slide against). `hidden_block.gd` uses a different pattern: a child `Area2D` monitoring the Player layer (`collision_mask = 2`) listens for `body_entered`, checks `body.velocity.y < 0` (player moving up), then enables the `StaticBody2D` collision via `set_deferred("disabled", false)`. This is the canonical pattern for any "toggle-able collision" block — don't try to shoehorn the slide-iteration approach.

### Item Spawning and `_ready()` Timing

In Godot 4, `_ready()` fires **synchronously inside `add_child()`**, before any subsequent lines in the caller run. This trips up item spawners that set position after `add_child`:

```gdscript
var item := scene.instantiate() as Node2D
get_parent().add_child(item)       # _ready() fires HERE, with default position (0, 0)
item.global_position = spawn_pos   # Too late — anything _ready() snapshotted is already stale
```

Items that need to know their spawn position (e.g., for emerge animations) must **not** capture it in `_ready()`. The project convention is **lazy-initialization on the first `_process` / `_physics_process` tick** via a boolean flag:

```gdscript
var _emerge_initialized: bool = false

func _process(delta: float) -> void:
    if not _emerge_initialized:
        _emerge_start_y = global_position.y
        _emerge_initialized = true
    # ...rest of emerge logic
```

See [fire_flower.gd](scripts/objects/fire_flower.gd) and [mushroom.gd](scripts/objects/mushroom.gd) for the pattern in use. Both have explanatory comments in `_ready()` warning against "fixing" the code back to the broken form.

**Testing caveat:** a timing test that extends `SceneTree` and does work in `_initialize()` has different `_ready` ordering than real scene gameplay (`_ready` is deferred there). Always verify frame/tree ordering with a `Node2D`-based test scene, not a `SceneTree` script.

### Enemy System

Enemies use the same state-machine-like pattern as the player but simpler:

- `enemy_base.gd` (CharacterBody2D) — gravity, patrol movement, wall reversal, flip-death animation. Reads speed/gravity from `@export var config: Resource` (EnemyConfig).
- `goomba.gd` / `koopa.gd` extend enemy_base. Koopa spawns a `koopa_shell.tscn` on stomp.
- `koopa_shell.gd` — standalone CharacterBody2D with IDLE/MOVING state machine, combo kill tracking.
- `enemy_spawner.gd` — script on the Enemies container node. Activates children when camera approaches within `activation_distance` pixels. Cleans up enemies far behind camera.

**Stomp vs damage detection:** Player has two Area2D children:
- `StompDetector` (at feet, masks Layer 5 EnemyHitbox) — `area_entered` checks `velocity.y > 0` for stomps
- `Hurtbox` (body area, on Layer 4, masks Layer 5) — `area_entered` handles damage

Both may fire for the same enemy in the same frame. The hurtbox handler has a position guard (`velocity.y > 0 and player above enemy → skip`) to avoid double-triggering on stomps. Enemies disable their hitbox `monitorable` on death, which is the primary guard.

**Enemy methods used by duck typing:** `stomp_kill() -> bool`, `is_dangerous() -> bool`, `try_kick(direction) -> bool`, `shell_kill()`, `activate()`, `is_active() -> bool`, `die()`.

### Effects System

`effects_manager.gd` (Node2D in the level scene) listens to EventBus signals and spawns visual effects:
- `score_popup.gd` — rising/fading point numbers on `score_awarded`
- `brick_particle.gd` — tumbling fragments on `block_broken`
- `stomp_puff.gd` — expanding particle ring on `enemy_stomped`
- `coin_pop.gd` — spinning coin arc on `item_spawned(&"coin")`

Player-attached effects: `damage_flash.gd` (red tint on `player_damaged`), `motion_trail.gd` (afterimages at top speed).

### Grow/Shrink States and Pause Rule

`GrowState` and `ShrinkState` freeze gameplay via `get_tree().paused = true` while the player flickers between forms. The player node is set to `PROCESS_MODE_ALWAYS` so the animation continues. On exit, the tree is unpaused and the player returns to the state it came from (cached via `state_machine.previous_state_name`). The collision shape is resized once at the end, not during the flicker.

**Caution:** Any node that must keep running during grow/shrink needs `PROCESS_MODE_ALWAYS` (e.g., the power-up ring effect). The SceneManager overlay already uses a high CanvasLayer and is unaffected.

### Color Palette

`color_palette.gd` holds all named color constants. Access via preload: `const P := preload("res://scripts/color_palette.gd")` then `P.MARIO_RED`.

### Collision Layers

Layers 1-10 are named in `project.godot`. Key separation: `CharacterBody2D` nodes only mask layer 1 (Terrain) for physics. `Area2D` nodes handle all overlap detection (stomp, damage, items, killzone) on layers 4-10.

## Tunables

Gameplay tunables live in Godot `Resource` files (`.tres`) under `resources/config/`, with script definitions in `scripts/config/`. Each script extends `Resource` with `@export` vars. Consuming scripts declare `@export var config: Resource` and are wired to the `.tres` in their scene file.

**Current config resources:**
- `PlayerMovementConfig` — walk/run speed, gravity, jump, coyote time, collision sizes, stomp bounce, invincibility
- `CameraConfig` — look-ahead distance/speed, smoothing, no-backtrack offset
- `EnemyConfig` — patrol speed, gravity (one `.tres` per enemy type: goomba, koopa)
- `BlockBumpConfig` — bump amplitude/duration, pulse frequency (shared by all block types)
- `ItemConfig` — mushroom speed/gravity, emerge height/duration
- `LevelTimingConfig` — intro duration, fade duration, death timing
- `EffectsConfig` — score popup speed, damage flash duration, trail spacing, grow/shrink rate

**Pattern:** Scripts that are scene-instanced (player, enemies, blocks, items) use `@export` wired in the `.tscn`. Autoloads and state nodes that can't use `@export` use `const preload("res://resources/config/...")` as a justified exception.

**Do not introduce a centralized `settings.gd` god-object.** The agreed direction is per-category `Resource` subclasses, not a single config file. `ProjectSettings` is reserved for truly global flags (difficulty, debug toggles), not gameplay values. New tunables go in the appropriate existing config resource, or a new one if no category fits.

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
