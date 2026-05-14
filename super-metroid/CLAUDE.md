# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Super Metroid recreation in Godot 4.6 (GDScript). 2D Metroidvania platformer. Phase 1 (core movement & camera) is implemented. SPEC.md defines all gameplay systems, PHASES.md defines the 8-phase build order.

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
| fluidsynth | `fluidsynth` | MIDI synthesis with `D:\GeneralUser-GS\GeneralUser-GS.sf2` |
| Godot | `Godot_v4.6.2-stable_win64.exe` | At `D:\Godot\` |

## Validation

```powershell
& "D:/Godot/Godot_v4.6.2-stable_win64.exe" --path . --headless --quit
```

## Project Structure

```
scripts/              # All GDScript files, organized by system
  player/             # Player controller, state machine, constants
    states/           # Individual state scripts (idle, walk, run, etc.)
  camera/             # Camera controller
player/               # Player assets
  sprites/            # SVG sources + exported PNGs + generation script
  audio/              # .ogg sound effects
props/                # Environment assets
  sprites/            # Tile SVGs + PNGs
scenes/               # Playable .tscn scenes (test_stage.tscn)
autoloads/            # Reserved for singletons (empty)
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
    Idle, Walk, Run, Crouch, Jump, SpinJump, Fall, WallJump, MorphBall
```

## Conventions

- **No magic strings.** Use `PlayerConsts` for state names, animation names, and shape names.
- **Static typing enforced.** All variables must have explicit types or use `:=` inference.
- **`@export` for tunable values.** Physics parameters (gravity, speeds, jump velocity) are exported on the Player node.
- **Asset pipeline:** SVG source → PNG export via Inkscape CLI. Keep both files paired. Audio generated with ffmpeg, stored as `.ogg`.
- **Input actions:** `move_left`, `move_right`, `move_up`, `move_down`, `jump`, `dash` (defined in project.godot with keyboard + gamepad bindings).

## Current State

**Phase 1 implemented:** Walking, running, variable-height jumping, spin jumps, crouching, morph ball (double-tap down), wall jumping (strict sequence with buffer), gravity, slopes, one-way platforms, smooth camera with limits. Test stage with StaticBody2D blocks.

**Next:** Phase 2 — Combat, enemies & HUD.
