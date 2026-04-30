# Super Mario Bros (Godot 4.6)

A 2D Super Mario Bros recreation built in Godot 4.6. Sprites are generated
from a Python + Inkscape pipeline (`tools/sprites/generate_sprites.py`) into
sheets under `sprites/`. Ships with World 1-1 and 1-2, Fire Mario, starman,
piranha plants, pipe warps, the flagpole sequence, and a full title / pause
/ game-over flow.

## Project Pillars

- **Generated sprite sheets.** Characters, items, blocks, and terrain are SVG-authored in `tools/sprites/generate_sprites.py` and exported as 32 px-cell PNG sheets. Frame selection happens in small per-entity scripts.
- **Tight, readable platforming** that feels close to classic SMB.
- **Modern polish** through particles, glow, screen shake, transitions.
- **Audio-ready** registry-based architecture; SFX/music plug in by filling paths.

Out of scope: online play, save files, level editor, mobile-specific controls.

## Running

```bash
godot --path .                     # Run the game
godot --headless --path . --quit   # Headless validation (parse errors, project loading)
```

If `godot` is not on PATH, use `d:\Godot_v4.6.2-stable_win64.exe`.

There is no automated test suite. Validate changes by running headless to catch
parse/load errors, then running the game windowed to verify gameplay.

> **Quirk:** `--headless --quit` exits before indexing new `class_name` scripts.
> The project avoids `class_name` entirely and uses `preload()` with `res://`
> paths instead.

## Project Configuration

| Setting        | Value                                       |
|----------------|---------------------------------------------|
| Viewport       | 1200 × 900                                  |
| Window         | Uses viewport size                          |
| Stretch        | `canvas_items`, aspect `keep`               |
| Renderer       | Forward Plus (required for 2D bloom/glow)   |
| Physics        | Godot 2D (Jolt is enabled for 3D but unused)|
| Tile grid      | 32 × 32 px                                  |

### Input Actions

| Action                       | Keyboard          | Gamepad         |
|------------------------------|-------------------|-----------------|
| `move_left` / `move_right`   | A/D, Arrows       | D-pad, L-stick  |
| `jump`                       | Space, W, Up      | South button    |
| `run` (also fires fireballs) | Left Shift, J     | West button     |
| `crouch`                     | S, Down           | D-pad Down      |
| `pause`                      | Escape, P         | Start           |

## Repository Layout

```text
res://
  scenes/
    main.tscn                    # Top-level shell
    levels/                      # world_1_1, world_1_2, test_level
    player/                      # player.tscn
    enemies/                     # goomba, koopa, koopa_shell, piranha_plant
    objects/                     # blocks, items, pipe, flagpole, castle
    ui/                          # title, hud, pause, game_over, level_complete

  scripts/
    autoloads/                   # event_bus, game_manager, sfx_manager,
                                 # music_manager, scene_manager, camera_effects
    player/                      # controller, drawer, state_machine,
                                 # player_states/, player_state_ids.gd
    enemies/                     # enemy_base + per-type scripts
    objects/                     # block_base, blocks, items, pipe, flagpole,
                                 # emerge_helper.gd
    effects/                     # effects_manager + per-effect scripts
    level/                       # level_base, level_1_2, parallax_controller,
                                 # tileset_builder, enemy_spawner, kill_zone
    config/                      # Resource subclasses for tunables
    ui/                          # screen scripts

  resources/
    config/                      # .tres tunable instances
    default_bus_layout.tres

  shaders/                       # glow_pulse, star_power, etc.
  audio/                         # music/, sfx/ (placeholder slots)
```

Generated files under `.godot/`, `*.uid`, and `*.import` are not hand-edited.

## Architecture

### Autoloads (loaded in this order)

1. **EventBus** — pure signal hub. ~30 signals covering player, scoring, enemies, blocks, and game state. Cross-system communication should prefer signals over hard references.
2. **GameManager** — persistent state (score, coins, lives, timer, power state, game state) and the entire level-transition flow. Single funnel `_enter_level(path)` for all transitions, called by `start_new_game()`, `advance_to_next_level()`, and `respawn_current_level()`.
3. **SfxManager** — event-driven SFX playback. Callers own `AudioStream` references and emit `EventBus.sfx_requested(sound)`; the manager only owns the SFX player pool.
4. **MusicManager** — event-driven music playback. Callers own music streams and emit music request/stop/duck events; the manager only owns dual `AudioStreamPlayer` crossfade plumbing.
5. **SceneManager** — fade transitions and the level-intro overlay. Public API: `change_scene`, `change_scene_no_fade`, `fade_out` / `fade_in`, `show_level_intro`.
6. **CameraEffects** — screen shake (the camera controller reads `get_shake_offset()` per frame) and freeze-frame via time-scale dip.

### Game Flow

```
Title Screen
  → start_new_game() → _enter_level(1-1)
                         → TRANSITIONING → fade_out → scene swap
                         → show_level_intro (2.5s)
                         → PLAYING + timer start

Flagpole → level_completed → tally → advance_to_next_level()
                                     OR return_to_title()
Death → lose_life()
        → lives > 0  → respawn_current_level (deferred, power → SMALL)
        → lives = 0  → GAME_OVER → game_over_screen → return_to_title()
Pause ↔ Resume (Escape)
```

`GameManager._enter_level()` is the only place level transitions happen. Level
scripts (`level_base.gd`, `level_1_2.gd`) are pure scene construction — they
paint terrain and set up the camera, but never touch run state, timers, or the
intro overlay.

### Player System

State machine with child nodes:

- **`player_controller.gd`** (CharacterBody2D) — movement helpers, collision shape management, stomp/damage handling, fireball shooting, star power, pipe entry, flagpole grab. Tunables come from `@export var movement: PlayerMovementConfig` and `@export var effects: EffectsConfig` wired in `player.tscn`.
- **`camera_controller.gd`** — script on the `Camera2D` child of the player. Owns horizontal look-ahead, screen-shake compositing, and the no-backtrack `limit_left` ratchet.
- **`state_machine.gd`** — delegates `_process` / `_physics_process` / `_unhandled_input` to the active state.
- **States** in `scripts/player/player_states/`: `Idle`, `Run`, `Jump`, `Fall`, `Crouch`, `Death`, `Grow`, `Shrink`, `PipeEnter`, `Flagpole`. Each state owns its own transition logic.
- **Sprite frame selection** lives in `player_controller._update_sprite_frame()` — picks frames from `sprites/player_sheet.png` based on `displayed_power_state`, movement velocity, current state name, and crouch flag. Star power tints the sprite via `_sprite.modulate`.

State-name references go through `scripts/player/player_state_ids.gd` (a constants-only `RefCounted`). Use `state_machine.transition_to(StateIds.JUMP)`, never `&"JumpState"` string literals — a rename in the scene tree would otherwise be silent.

Star power is a flag on the controller (`_is_star_powered`), not a state. Fireballs are standalone `CharacterBody2D` scenes; the player tracks active count in `_active_fireballs` (max 2), decrementing on each fireball's `tree_exited`.

### Level System

- **`level_base.gd`** (overworld) and **`level_1_2.gd`** (underground) construct scenes only — they paint terrain via the shared builder and place interactive objects.
- **`tileset_builder.gd`** — parameterized procedural TileSet builder. `create_tileset(top_color, fill_color)` returns a 2-tile atlas with collision polygons, used by both levels with different palette colors.
- Only static terrain uses `TileMapLayer`. Blocks, enemies, and items are individual scene instances under container `Node2D` nodes.
- **`parallax_controller.gd`** — places repeating cloud/hill/bush sprites from `sprites/background_decor_sheet.png` with parallax driven by the player camera's screen center.
- **`enemy_spawner.gd`** — activates enemies as the camera approaches `activation_distance`, cleans up enemies left far behind.

### Enemy System

- **`enemy_base.gd`** (CharacterBody2D) — gravity, patrol, wall reversal, flip-death animation. Tunables come from per-type `EnemyConfig` resources.
- **Goomba**, **Koopa**, **Koopa Shell**, **Piranha Plant** extend or compose with the base. Piranha Plant is a `Node2D` (tween-based emerge/retract), not a `CharacterBody2D`, and is not stompable.
- The player has two `Area2D` children: `StompDetector` (feet) and `Hurtbox` (body). Both may fire for the same enemy in one frame; the hurtbox handler skips damage when the player is above and the enemy is stompable.
- Enemy duck-typed methods: `stomp_kill`, `is_stompable`, `is_dangerous`, `try_kick`, `shell_kill`, `non_stomp_kill`, `activate`, `is_active`, `die`.

### Blocks and Items

- **`block_base.gd`** — bump animation state shared by `brick_block`, `question_block`, and `hidden_block`. Subclasses extend it via `extends "res://scripts/objects/block_base.gd"` and call `start_bump()` to trigger the animation.
- Solid blocks expose **`bump_from_below()`**, called by the player's slide-collision check. Hidden blocks use a different pattern (a child `Area2D` checks for upward player contact) since slide-iteration can't detect a body with collision disabled.
- **`emerge_helper.gd`** — `RefCounted` shared by `mushroom`, `fire_flower`, and `starman` for the lazy-init upward emerge tween (composed via `var _emerge := EmergeHelper.new()`).
- **Pipe warps** disable the player's collision and tween position directly during entry/exit, with `z_index` dropped so Mario passes behind the pipe rim.

### Effects System

`effects_manager.gd` is a Node2D in each level. It listens for EventBus signals
(`score_awarded`, `block_broken`, `enemy_stomped`, `item_spawned(coin)`) and
spawns effects via the private `_spawn_effect(script, pos, z)` helper.

Per-effect scripts in `scripts/effects/`: `score_popup`, `brick_particle`,
`stomp_puff`, `coin_pop`, `damage_flash`, `motion_trail`, `power_up_effect`.

Effects are scriptless `Node2D`s with a script attached at runtime — they are
not `.tscn` scenes. To add one: write a `Node2D`-extending script with its own
`_process` / `_draw` / lifetime, preload it, then call `_spawn_effect()` from
the appropriate signal handler.

### UI Layer

- **Title screen** (`title_screen.gd`) — the main scene set in `project.godot`.
- **Pause menu** (`pause_menu.gd`) — `PROCESS_MODE_WHEN_PAUSED` `CanvasLayer`. Toggles `get_tree().paused` and ducks music.
- **Game over** (`game_over_screen.gd`) — `PROCESS_MODE_ALWAYS`. Shows for 3s on `game_over`, returns to title.
- **Level complete** (`level_complete.gd`) — `PROCESS_MODE_ALWAYS`. Score tally, then calls `GameManager.advance_to_next_level()`.

### Tunables

Gameplay tunables live in Godot `Resource` files (`.tres`) under
`resources/config/`, with script definitions in `scripts/config/`. Each script
extends `Resource` with `@export` vars; consuming scenes assign concrete
`.tres` instances in the inspector.

| Resource              | Covers                                                       |
|-----------------------|--------------------------------------------------------------|
| `PlayerMovementConfig`| walk/run speed, gravity, jump, coyote time, collision sizes  |
| `CameraConfig`        | look-ahead, smoothing, no-backtrack offset                   |
| `EnemyConfig`         | patrol speed, gravity (one `.tres` per enemy type)           |
| `BlockBumpConfig`     | bump amplitude/duration/pulse                                |
| `ItemConfig`          | mushroom speed/gravity, emerge height/duration               |
| `LevelTimingConfig`   | intro, fade, death timing                                    |
| `EffectsConfig`       | popup speed, flash duration, trail spacing, grow/shrink rate |

Scene-instanced scripts (player, enemies, blocks, items) use `@export var config: Resource` wired in the `.tscn`. Autoloads and state nodes that can't use `@export` use `const preload("res://resources/config/...")` as a justified exception.

> **Don't introduce a centralized `settings.gd` god-object.** Per-category
> Resource subclasses are the agreed direction. `ProjectSettings` is reserved
> for truly global flags (difficulty, debug toggles), not gameplay values.

## Collision Layers

| Layer | Name         | Used By                                  |
|-------|--------------|------------------------------------------|
| 1     | Terrain      | TileMap terrain, blocks, pipes           |
| 2     | Player       | Player `CharacterBody2D`                 |
| 3     | Enemies      | Enemy `CharacterBody2D`                  |
| 4     | PlayerHitbox | Player `Area2D` hurtbox / stomp detector |
| 5     | EnemyHitbox  | Enemy `Area2D` hitboxes                  |
| 6     | Items        | Coins and power-ups                      |
| 7     | Fireballs    | Player fireballs                         |
| 8     | KoopaShell   | Moving shell                             |
| 9     | KillZone     | Pit death area                           |
| 10    | Interactable | Flagpole, pipe-warp triggers             |

`CharacterBody2D` nodes only mask `Terrain` for physics. All overlap detection
(stomp, damage, items, killzone) goes through `Area2D` on layers 4-10.

## Visual Style

- Sprite sheets generated from `tools/sprites/generate_sprites.py` (SVG → Inkscape → PNG). Each cell is 32×32; sheets are laid out as `cols × rows` grids.
- Per-entity drawer scripts use `Sprite2D.region_rect` to pick the frame; `scripts/visuals/sprite_region_helper.gd` is the shared helper.
- Geometry stays aligned to the 32 px grid.
- Bold silhouettes, high contrast, no tiny detail.
- WorldEnvironment uses subtle bloom; Forward Plus is required for the glow.

## GDScript Conventions

- Typed signatures: `func name(param: Type) -> ReturnType:`.
- `snake_case` for variables/functions, `_prefix` for private — and it means it. If external code has a legitimate reason to call something, it is public; do not reach across files into an underscore-prefixed member.
- No `class_name` declarations — use `preload()` with `res://` paths.
- Prefer Input Map actions (`&"jump"`, `&"run"`) over hard-coded keys.
- Reference player states via `StateIds.X`, not `&"XState"` string literals.
- Only include `_process` / `_physics_process` when actually used.

## Architectural Decisions

1. **`CharacterBody2D` over `RigidBody2D`** for the player — platformer controls require deterministic, frame-accurate movement.
2. **`TileMapLayer` for static terrain only.** Interactive objects are scene instances because blocks, pipes, and items need custom logic and per-instance state.
3. **Dedicated player state machine** — movement, damage, growth, pipes, and flagpole behaviors would otherwise turn into brittle condition chains in the controller.
4. **EventBus-based decoupling** — HUD, audio, scoring, and effects react to gameplay without hard scene dependencies.
5. **Forward Plus renderer** — the visual pitch depends on subtle bloom and post-processing on a 2D canvas.
6. **Sprite-sheet rendering with code-side frame selection** — sheets are generated programmatically (no hand-painted assets), and per-entity scripts pick frames from state. Keeps art reproducible while leaving animation logic in code.
7. **32 px grid** — preserves classic Mario spacing and keeps scene authoring simple.
8. **Per-category Resource tunables, not a god-object.** Categories are clear from gameplay structure, and `.tres` variants give designer-friendly tuning without code changes.
