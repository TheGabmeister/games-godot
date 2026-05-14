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
  enemies/            # Enemy base class + specific enemies (waver, zeela, sidehopper)
  pickups/            # Pickup drop script
  hud/                # HUD controller
  camera/             # Camera controller
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
  Camera2D
  StateMachine
    Idle, Walk, Run, Crouch, Jump, SpinJump, Fall, WallJump, MorphBall, Hurt
  DamageFlasher                          # reusable sprite flash component
  WeaponSystem                           # firing, charge, beam limit, weapon cycling
```

## Architecture: GameManager Autoload

`GameManager` (autoload) spawns the player and HUD into any stage scene. Stages don't need scripts — just place a `Marker2D` in the `player_start` group (use `GameConsts.GROUP_PLAYER_START`) at the desired spawn position.

- `_ready()` uses `call_deferred` to find the marker after the main scene loads (autoloads initialize before the main scene)
- Spawns `Player` at the marker's position, then spawns the HUD and wires signals via `connect_to_player()`
- `GameManager.player` provides the player reference to any system that needs it

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

**Next:** Phase 3.1 — Room transitions & doors.
