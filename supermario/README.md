# Super Mario Bros (Godot 4.6)

A 2D Super Mario Bros recreation built in Godot 4.6. Sprites are generated
from a Python + Inkscape pipeline (`tools/sprites/generate_sprites.py`) into
sheets under `sprites/`. Ships with World 1-1 and 1-2, Fire Mario, starman,
piranha plants, pipe warps, the flagpole sequence, and a full title / pause
/ game-over flow.

## Project Pillars

- **Generated sprite sheets.** Characters, items, blocks, and terrain are SVG-authored in `tools/sprites/generate_sprites.py` and exported as 32 px-cell PNG sheets. `tools/sprites/generate_sprite_frames.py` slices these into Godot `SpriteFrames` resources under `resources/sprite_frames/`.
- **Tight, readable platforming** that feels close to classic SMB.
- **Modern polish** through particles, glow, and transitions.
- **Audio-ready** architecture; SFX live in `audio/sfx/` as WAV files, music is wired through `LevelConfig` resources.

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
| Viewport       | 1024 × 768                                  |
| Window         | Uses viewport size                          |
| Stretch        | `canvas_items`                              |
| Renderer       | Forward Plus (required for 2D bloom/glow)   |
| Texture filter | Nearest (pixel-art)                         |
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
| `start`                      | Enter             | Start           |

## Repository Layout

```text
res://
  scenes/
    main.tscn                    # Unused shell (boot scene is title_screen)
    levels/                      # world_1_1, world_1_2, test_level
    player/                      # player.tscn
    enemies/                     # goomba, koopa, koopa_shell, piranha_plant
    objects/                     # blocks, items, pipe, flagpole, castle, fireball
    effects/                     # score_popup, brick_particle, stomp_puff,
                                 # coin_pop, power_up_effect
    ui/                          # title_screen, hud, game_over

  scripts/
    autoloads/                   # event_bus, game_manager, sfx_manager,
                                 # music_manager, ui_manager
    player/                      # controller, camera_controller, state_machine,
                                 # player_states/, player_state_ids.gd
    enemies/                     # enemy_base + per-type scripts
    objects/                     # block_base, blocks, items, pipe, flagpole,
                                 # emerge_helper.gd
    effects/                     # effects_manager + per-effect scripts
    level/                       # enemy_spawner, kill_zone
    config/                      # Resource subclasses for tunables
    pickups/                     # pickup_helper.gd
    ui/                          # title_screen, hud, game_over_screen

  resources/
    config/                      # .tres tunable instances
    sprite_frames/               # SpriteFrames .tres for AnimatedSprite2D
    tilesets/                    # terrain_tileset.tres
    default_bus_layout.tres

  sprites/                       # Generated PNG sprite sheets (32px cells)
  shaders/                       # background_gradient
  audio/sfx/                     # SFX .wav files
  tools/
    sprites/                     # generate_sprites.py, generate_sprite_frames.py, svg/
    tileset_builder_reference.gd # Reference for how the tileset was built
```

Generated files under `.godot/`, `*.uid`, and `*.import` are not hand-edited.

## Architecture

### Autoloads (loaded in this order)

1. **EventBus** — pure signal hub. 28 signals covering audio, player, scoring, level, enemies, blocks, and game state. Cross-system communication should prefer signals over hard references.
2. **GameManager** — persistent state (score, coins, lives, timer, power state, game state), level-transition flow, player spawning, timer countdown, pause/resume, and level-complete scoring. Central authority for run lifecycle.
3. **SfxManager** — event-driven SFX playback. Callers own `AudioStream` references and emit `EventBus.sfx_requested(sound)`; the manager only owns the SFX player pool.
4. **MusicManager** — event-driven music playback. Callers own music streams and emit `music_requested` / `music_stop_requested`; the manager only owns dual `AudioStreamPlayer` crossfade plumbing.
5. **UIManager** — instances the `GameOver` overlay scene once at startup. The overlay persists across scene changes — it is **not** placed in level scenes.

### Game Flow

```
Title Screen
  → start_new_game() → _enter_level(0)
                         → TRANSITIONING → scene swap + player spawn
                         → PLAYING + timer start + music

Flagpole → flagpole_reached → timer stops
        → level_completed → stops music, stage_clear SFX, time bonus
                          → LEVEL_COMPLETE → 2s delay → advance_to_next_level()
                                                        OR return_to_title()
Death → _on_player_died → stops timer + music
     → _on_death_animation_finished → lose_life()
        → lives > 0  → respawn_current_level (deferred, power → SMALL)
        → lives = 0  → GAME_OVER → game_over screen (3s) → return_to_title()
Pause ↔ Resume (Escape/P) — GameManager toggles tree.paused
```

`GameManager._enter_level()` is the only place level transitions happen. Level
scenes are pure data — they contain terrain, blocks, enemies, and markers but
no attached scripts. GameManager spawns the player at the `PlayerStart` marker.

### Player System

State machine with child nodes:

- **`player_controller.gd`** (CharacterBody2D) — movement helpers, collision shape management, stomp/damage handling, fireball shooting, star power, pipe entry, flagpole grab. Tunables come from `@export var movement: Resource` and `@export var effects: Resource` wired in `player.tscn`.
- **`camera_controller.gd`** — script on the `Camera2D` child of the player. Owns horizontal look-ahead and the no-backtrack `limit_left` ratchet.
- **`state_machine.gd`** — delegates `_process` / `_physics_process` / `_unhandled_input` to the active state.
- **States** in `scripts/player/player_states/`: `Idle`, `Run`, `Jump`, `Fall`, `Crouch`, `Death`, `Grow`, `Shrink`, `PipeEnter`, `Flagpole`. Each state owns its own transition logic.
- **Sprite animation** lives in `player_controller._update_sprite_frame()` — calls `AnimatedSprite2D.play()` with animation names (e.g., `small_idle`, `big_walk`, `fire_jump`) built from `displayed_power_state` and current movement/state. Star power tints the sprite via `_sprite.modulate`.

State-name references go through `scripts/player/player_state_ids.gd` (a constants-only `RefCounted`). Use `state_machine.transition_to(StateIds.JUMP)`, never `&"JumpState"` string literals — a rename in the scene tree would otherwise be silent.

Star power is a flag on the controller (`_is_star_powered`), not a state. Fireballs are standalone `CharacterBody2D` scenes; the player tracks active count in `_active_fireballs` (max 2), decrementing on each fireball's `tree_exited`.

### Level System

- Level scenes are pure `.tscn` data — hand-painted terrain, placed blocks/enemies, a `PlayerStart` marker, and an `Effects` node. No scene scripts.
- **GameManager** spawns the player at the `PlayerStart` (`Marker2D`) node and drives all run lifecycle (timer, death, level complete).
- **Terrain is hand-painted** in the editor using `TileMapLayer` with a baked `TileSet` resource (`resources/tilesets/terrain_tileset.tres`). See `tools/tileset_builder_reference.gd` for how the tileset was originally constructed.
- Only static terrain uses `TileMapLayer`. Blocks, enemies, and items are individual scene instances under container `Node2D` nodes.
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

`effects_manager.gd` is a `Node2D` placed in each level scene. It listens for
EventBus signals (`score_awarded`, `block_broken`, `enemy_stomped`,
`item_spawned(coin)`) and spawns effects via preloaded `.tscn` scenes.

Effect scenes in `scenes/effects/`: `score_popup`, `brick_particle`,
`stomp_puff`, `coin_pop`, `power_up_effect`. Each is a `Node2D` with an
`AnimatedSprite2D` child and a script that handles animation and lifetime.

The manager's `_spawn_effect(scene, pos, z)` helper calls `scene.instantiate()`,
sets position and z_index, then `add_child()`.

Player-attached effects (`damage_flash`, `motion_trail`) are wired directly
in `player.tscn`, not via the effects manager.

### UI Layer

- **Title screen** (`title_screen.gd`) — the main scene set in `project.godot`.
- **HUD** (`hud.gd`) — `CanvasLayer` instanced in each level scene. Displays score, coins, world name, timer. Listens to EventBus signals.
- **Game over** (`game_over_screen.gd`) — `PROCESS_MODE_ALWAYS` `CanvasLayer`, instanced once by `UIManager`. Shows for 3s on `game_over`, returns to title.
- **Pause** — handled by `GameManager` directly via `get_tree().paused`. No separate pause menu scene.
- **Level complete** — handled by `GameManager._on_level_completed()`: stops timer/music, plays stage clear SFX, calculates time bonus, then advances after a 2s delay.

### Tunables

Gameplay tunables live in Godot `Resource` files (`.tres`) under
`resources/config/`, with script definitions in `scripts/config/`. Each script
extends `Resource` with `@export` vars; consuming scenes assign concrete
`.tres` instances in the inspector.

| Resource              | Covers                                                       |
|-----------------------|--------------------------------------------------------------|
| `GameConfig`          | ordered `levels` array of `LevelConfig` resources            |
| `LevelConfig`         | display_name, scene, time_limit, music                       |
| `PlayerMovementConfig`| walk/run speed, gravity, jump, coyote time, collision sizes  |
| `CameraConfig`        | look-ahead, smoothing, no-backtrack offset                   |
| `EnemyConfig`         | patrol speed, gravity (one `.tres` per enemy type)           |
| `BlockBumpConfig`     | bump amplitude/duration/pulse                                |
| `ItemConfig`          | mushroom speed/gravity, emerge height/duration               |
| `LevelTimingConfig`   | intro/fade duration, death animation timing                  |
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
- `tools/sprites/generate_sprite_frames.py` slices sheets into `SpriteFrames` resources (`.tres`) under `resources/sprite_frames/`, defining animation sequences with `AtlasTexture` sub-resources.
- Per-entity scripts use `AnimatedSprite2D` with these `SpriteFrames` resources and call `_sprite.play(animation_name)` to select frames.
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
6. **Sprite-sheet rendering with `AnimatedSprite2D`** — sheets are generated programmatically (no hand-painted assets), sliced into `SpriteFrames` resources, and per-entity scripts select animations by name. Keeps art reproducible while leveraging Godot's built-in animation system.
7. **32 px grid** — preserves classic Mario spacing and keeps scene authoring simple.
8. **Per-category Resource tunables, not a god-object.** Categories are clear from gameplay structure, and `.tres` variants give designer-friendly tuning without code changes.
