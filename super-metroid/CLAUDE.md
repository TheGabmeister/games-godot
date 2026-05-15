# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Super Metroid recreation in Godot 4.6 (GDScript). 2D Metroidvania platformer. Phase 1 (core movement & camera) and Phase 2 (combat, enemies & HUD) are implemented. SPEC.md defines all gameplay systems, PHASES.md defines the 8-phase build order.

## Engine & Runtime

- **Godot 4.6**, Forward Plus renderer, D3D12 driver (Windows)
- **Language:** GDScript (static typing enforced — Untyped Declaration set to Error)
- **Viewport:** 640x480 internal, 1280x960 window (2x integer scaling, nearest-neighbor filtering)
- **Tile size:** 32x32, **Player sprite:** 64x96 standing, 32x32 morph ball

## Key Documents

- **SPEC.md** — Complete gameplay systems spec. Consult before implementing any mechanic.
- **PHASES.md** — 8-phase build plan in dependency order. Follow this order.
- **AGENTS.md** — Development conventions and validation commands for coding agents.

## External Tools (all on PATH)

| Tool | Command | Notes |
|---|---|---|
| Inkscape | `inkscape` | SVG → PNG export |
| ffmpeg | `ffmpeg` | Audio synthesis and conversion |
| fluidsynth | `fluidsynth` | MIDI synthesis (soundfonts in `D:\Tools\`) |
| Godot | `Godot_v4.6.2-stable_win64.exe` | Use bare name, not full path |
| Blender | `blender` | 3D model generation via Python scripts |

## Validation

```powershell
Godot_v4.6.2-stable_win64.exe --path . --headless --quit
```

After adding a new script with `class_name`, run the editor once to register it in the class cache:
```powershell
Godot_v4.6.2-stable_win64.exe --path . --headless --editor --quit
```

## Project Structure

```
scripts/              # All GDScript files, organized by system
  player/             # Player controller, state machine, constants, weapon system
    states/           # Individual state scripts (idle, walk, run, hurt, etc.)
  combat/             # Projectile base class, damage flasher
    projectiles/      # Projectile and bomb scripts
  doors/              # Door and Room scripts
  enemies/            # Enemy base class + specific enemies (waver, zeela, sidehopper)
  pickups/            # Pickup drop script
  hud/                # HUD controller
  camera/             # Camera controller (standalone scene, not child of Player)
  autoloads/          # SfxManager, MusicManager, GameManager singletons
player/               # Player assets
  sprites/            # SVG sources + exported PNGs + generation scripts
  audio/              # .ogg sound effects (footsteps, jump, morph, damage, alarm)
combat/               # Combat assets
  sprites/            # Projectile, bomb, VFX sprites
  audio/              # Beam fire, charge, missile, bomb SFX
enemies/              # Enemy assets
  sprites/            # Enemy sprite sheets
  audio/              # Enemy hit/death SFX
pickups/              # Pickup assets
  sprites/            # Drop pickup sprites
hud/                  # HUD assets
  sprites/            # Icons, tank pips
props/                # Environment assets
  tiles/              # Tile SVGs + PNGs
  doors/              # Door sprites (blue, red, gray) + audio
scenes/               # Playable .tscn scenes
  rooms/              # Room scenes (room_a through room_d test rooms)
  doors/              # Door base scene
  projectiles/        # Projectile scenes (power_beam, charge_beam, missile, bomb)
  enemies/            # Enemy scenes (waver, zeela, sidehopper)
  pickups/            # Pickup drop scenes
data/                 # Reserved for game data (empty)
```

Key rule: **all scripts go in `scripts/`** with subdirectories by system. Assets (sprites, audio, scenes) go in their module folder (player/, props/).

## Architecture: Player State Machine

The player uses a **state pattern** with separate scripts per state:

- `player.gd` (CharacterBody2D) — owns physics, exposes helper methods for states
- `player_state_machine.gd` — manages transitions, auto-discovers child state nodes
- `player_state.gd` — base class with `enter()`, `exit()`, `handle_input()`, `update()`
- `player_constants.gd` (`class_name PlayerConsts`) — all string constants as `StringName`
- `states/*.gd` — one file per state (idle, walk, run, crouch, jump, spin_jump, fall, wall_jump, morph_ball)

State lifecycle: `Player._physics_process()` → `StateMachine.update()` → `current_state.update()` → `move_and_slide()`.

States transition via `state_machine.transition_to(PlayerConsts.STATE_WALK)`.

### Adding a New State

1. Add constant to `PlayerConsts` (e.g., `STATE_DASH: StringName = &"dash"`)
2. Create `scripts/player/states/dash_state.gd` extending `PlayerState`
3. Add a Node child named "Dash" under StateMachine in `player.tscn` with the script attached

### Player Scene Tree

```
Player (CharacterBody2D)
  PlayerSprite (AnimatedSprite2D)       # standing animations
  MorphBallSprite (AnimatedSprite2D)    # morph ball, hidden by default
  StandingShape (CollisionShape2D)      # 24x44, enabled by default
  CrouchingShape (CollisionShape2D)     # 24x30, disabled
  MorphBallShape (CollisionShape2D)     # 16x16, disabled
  StateMachine
    Idle, Walk, Run, Crouch, Jump, SpinJump, Fall, WallJump, MorphBall, Hurt
  DamageFlasher                          # reusable sprite flash component
  WeaponSystem                           # firing, charge, beam limit, weapon cycling
```

## Architecture: GameManager Autoload

`GameManager` (autoload) owns Player, Camera, and HUD as **root-level siblings** of the current room scene. Rooms are swappable; persistent nodes stay at root.

- `_ready()` uses `call_deferred` to find the `player_start` marker after the main scene loads
- Spawns Player, CameraController, and HUD as children of `get_tree().root` (not the room)
- `GameManager.player` / `GameManager.camera` / `GameManager.current_room` provide references
- `GameManager.door_states: Dictionary` tracks persistent door type changes (red → blue)
- `GameManager.transitioning: bool` gates input, weapon firing, and door triggers during transitions

### Room Transition Sequence

1. Player enters open door trigger → `GameManager.start_transition()` called
2. Input disabled, player auto-walks into doorway
3. Black `ColorRect` overlay (z_index 50) fades in over the room — doors (z_index 100) and player (root-level) stay visible
4. New room loaded and offset one viewport in the scroll direction
5. Camera detaches from player, tweens across both rooms (0.75s sine ease)
6. Old room freed, new room repositioned to origin, camera/player adjusted
7. New room fades in, target door closes behind player
8. Player walks into room, state reset to Idle, input restored

## Architecture: Room & Door System

- **Room:** `room.gd` (`class_name Room`, extends Node2D) — `@export var camera_bounds: Rect2` defines camera limits. Each room is a standalone `.tscn`.
- **Camera:** `camera_controller.gd` (`class_name CameraController`, extends Camera2D) — own scene, follows `target` node, supports `set_room_limits()` / `clear_limits()` for transitions.
- **Door:** `door.gd` (`class_name Door`, extends StaticBody2D) — blocks passage on terrain layer when closed. Child `Hitbox` Area2D (mask=PlayerProjectile) detects shots. Child `Trigger` Area2D (mask=Player) starts transitions. Exports: `door_id`, `door_type` (BLUE/RED/GRAY), `facing` (LEFT/RIGHT/UP/DOWN), `target_scene_path`, `target_door_id`.
- **Door types:** Blue (any weapon opens), Red (5 missiles, persists as blue), Gray (locked until `enemy_group` is empty).
- **Persistence:** Door computes key from `owner.scene_file_path + ":" + door_id`. Red doors that open are stored in `GameManager.door_states` as BLUE.
- **Projectiles spawn into `GameManager.current_room`** (not player parent), so they're cleaned up on room swap.

## Architecture: Combat & Enemies

- **Firing is an overlay, not a state.** `WeaponSystem` (child node of Player) runs its own `_physics_process()` and gets its player reference via `get_parent()` in `_ready()`. No `class_name` — avoids circular dependency with Player. Movement states are unaware of firing.
- **Charge Beam:** Timer on WeaponSystem. Hold fire 2s → charged shot. Resets on weapon switch.
- **Beam limit:** Max 3 Power Beam projectiles on screen. WeaponSystem tracks `active_beams` via `tree_exited` signals.
- **Enemy base class:** `enemy.gd` (CharacterBody2D) with HP, contact damage, `@export var drop_table: Array[DropEntry]`. `DropEntry` is a custom Resource with typed `DropType` enum, weight, and optional scene. Specific enemies override `_physics_process` for AI. SFX and drop scenes are all `@export` vars set in each enemy's `.tscn`.
- **Enemy contact damage:** Each enemy creates an Area2D child in `_ready()` with mask=2 (Player). The `body_entered` signal calls `player.take_damage()`.
- **Damage during physics callbacks:** State transitions from `body_entered` signals must use `call_deferred()` to avoid modifying collision shapes mid-query.
- **DamageFlasher:** Reusable node (`scripts/combat/damage_flasher.gd`) that flashes any CanvasItem. Attach to any scene that needs hit-flash.

## Conventions

- **No magic strings.** Use `PlayerConsts` for player-specific constants, `GameConsts` for game-wide constants (group names, etc.).
- **Static typing enforced.** All variables must have explicit types or use `:=` inference. Capture return values from `connect()` and `erase()` to avoid `RETURN_VALUE_DISCARDED` warnings.
- **`@export` for tunable values.** Physics parameters, SFX, scenes, and textures are exported — no `preload()` paths in scripts. Set assets in `.tscn` scene files instead, where Godot tracks them by `uid://` and survives file moves.
- **Asset pipeline:** SVG source → PNG export via Inkscape CLI. Keep both files paired. Audio generated with ffmpeg, stored as `.ogg`. Run ffmpeg as standalone commands, not chained with `&&` (permission rules match command prefix only).
- **Input actions:** `move_left`, `move_right`, `move_up`, `move_down`, `jump`, `dash`, `fire`, `select_weapon`, `cancel_weapon`, `aim_up`, `aim_down` (defined in project.godot with keyboard + gamepad bindings).
- **Collision layers:** 1=Terrain, 2=Player, 3=Enemy, 4=PlayerProjectile, 5=EnemyProjectile, 6=Pickup. Player mask=1 (terrain). Enemies mask=1 (terrain) with Area2D child mask=2 (player) for contact damage.

## Current State

**Phase 1 implemented:** Walking, running, variable-height jumping, spin jumps, crouching, morph ball (double-tap down), wall jumping (strict sequence with buffer), gravity, slopes, one-way platforms, smooth camera with limits.

**Phase 2 implemented:** Power Beam (8-directional, 3-beam limit), Charge Beam (2s charge, 3x damage), Missiles (ammo-limited), Morph Ball Bombs (3s fuse, max 3, bomb jump impulse), weapon cycling (Select/X), HUD (energy counter, tank pips, weapon icon, ammo, low energy alarm at ≤29), enemy framework (HP, contact damage, DropEntry resources), three enemies (Waver, Zeela, Sidehopper), damage/knockback system (Hurt state + i-frames + DamageFlasher), SfxManager/MusicManager/GameManager autoloads.

**Phase 3.1 implemented:** Room-based world system (each room a standalone scene), door system (blue/red/gray with StaticBody2D + Area2D hitbox/trigger), directional camera scroll transitions with fade-to-black overlay, door state persistence (red→blue), gray door enemy-group tracking, CameraController as own scene (separated from Player), GameManager owns Player/Camera/HUD at root level. 4 test rooms: A (hub), B (blue), C (blue), D (red door + gray door + enemies).

**Next:** Phase 3.2 — Blocks, items & stations.
