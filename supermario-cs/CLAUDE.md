# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

A 2D Super Mario Bros inspired platformer built in **Godot 4.6 with C#**. All visuals use procedural primitive shapes (no sprites/textures). The full design spec lives in [SPEC.md](SPEC.md).

## Build & Run

```bash
# Build C# project
dotnet build supermario-cs.csproj

# Validate Godot project loads without errors
godot --headless --path . --quit

# Open in Godot editor (then F5 to run)
godot --path .
```

No test framework is configured. Validation is done by building and running in the Godot editor. Always run `dotnet build` before `godot --headless` — the headless launch validates project structure, not C# syntax.

## Project Configuration

- **Engine:** Godot 4.6, Forward Plus renderer
- **SDK:** Godot.NET.Sdk 4.6.2, targeting .NET 8.0 (.NET 9.0 for Android)
- **Root namespace:** `supermariocs`
- **Viewport:** 512x448 px, window 1024x896 (2x scale, `canvas_items` stretch)
- **Tile grid:** 16x16 px (32x28 visible tiles)
- **Main scene:** `res://scenes/main.tscn`

## Architecture

### Scene Ownership Model

`main.tscn` is the persistent shell — it is never unloaded. Level scenes are loaded into a `SceneRoot` child and swapped by `SceneManager`.

**Lives under Main (persistent):** Player, HUD (CanvasLayer), WorldEnvironment, overlay layers.
**Lives inside level scenes (swapped):** terrain, blocks, enemies, pipes, spawn markers (`Marker2D`), kill zones, camera bounds, decorations.

On level load, `SceneManager` moves the Player to the level's `PlayerSpawn` marker. On death/respawn, the player is repositioned — never re-instantiated.

### Autoload Singletons

Five global singletons registered in `project.godot`, all inheriting `Node`:

| Singleton | Responsibility |
|-----------|---------------|
| **EventBus** | Central signal hub — `[Signal]` delegates for player, scoring, level, enemy, block events |
| **GameManager** | Single source of truth for game state: score, coins, lives, power state, timer, game state machine |
| **AudioManager** | Music crossfade (2 players), pooled SFX (10 non-positional + 6 positional), registry pattern with safe no-op on empty paths |
| **SceneManager** | Fade transitions, scene loading into `SceneRoot`, level intro overlays, player repositioning |
| **CameraEffects** | Screen shake and freeze frame on the active Camera2D |

**Autoload order matters.** Register in this order in `project.godot` (EventBus first, GameManager second, others can load after):

```
EventBus → GameManager → AudioManager / SceneManager / CameraEffects
```

**Dependency direction is one-way.** SceneManager calls into GameManager (`StartLevel(config)`, reads `Lives` and `CurrentGameState`). GameManager never calls SceneManager — when it needs a scene change, it updates `CurrentGameState` and emits EventBus signals (`LevelCompleted`, `GameOver`); SceneManager listens and reacts.

### Per-Level Parameters (LevelConfig)

Each level scene exports a `LevelConfig` resource (`Scripts/Config/LevelConfig.cs`) that declares its identity, time limit, music track, and environment overrides. On level load, `SceneManager` reads the config and forwards it:

- `GameManager.StartLevel(config)` → resets `TimeRemaining` to `config.TimeLimit`, updates world/level, emits `LevelStarted`
- `AudioManager.PlayMusic(config.MusicTrack)` → begins playback
- `WorldEnvironment` adjusted if `config.IsUnderground` or `config.SkyColorOverride` is set

One `.tres` per level under `resources/config/` (e.g., `level_1_1.tres`). Tuning time limits or swapping music requires only an inspector edit — no code changes.

### Power State Authority

`GameManager.CurrentPowerState` is the single source of truth. The player reads it on spawn/respawn via `_Ready()`, and the state machine writes through `GameManager.SetPowerState()`. The player never stores its own shadow copy. `LoseLife()` resets to `Small` before the respawn cycle.

### Player Controller

`CharacterBody2D` with a **state machine** pattern. Each state (`PlayerState` subclass) implements `Enter()`, `Exit()`, `ProcessInput()`, `ProcessFrame()`, `ProcessPhysics()`. Note: `delta` is `double` in Godot C#, not `float`.

States: Idle, Run, Jump, Fall, Crouch, Death, Grow, Shrink, PipeEnter, Flagpole.

Visual rendering is separated into a dedicated **drawer node** (`PlayerDrawer`) using `_Draw()`, keeping gameplay logic independent of visual construction.

### Collision Layers

| Layer | Name | Purpose |
|-------|------|---------|
| 1 | Terrain | TileMap, blocks, pipes |
| 2 | Player | Player CharacterBody2D |
| 3 | Enemies | Enemy CharacterBody2D (does not self-mask) |
| 4 | PlayerHitbox | Player Area2D hurtbox/stomp |
| 5 | EnemyHitbox | Enemy Area2D hitboxes |
| 6 | Items | Coins, power-ups |
| 7 | Fireballs | Player fireballs |
| 8 | KoopaShell | Moving shells |
| 9 | KillZone | Pit death areas |
| 10 | Interactable | Flagpole, pipe warp triggers |

### Key Patterns

- **Drawer pattern:** Gameplay logic on main node, visuals in a `*Drawer` child using `_Draw()`. Enables palette swaps without touching gameplay code.
- **Event bus over hard references:** Cross-system communication uses EventBus signals. Local/obvious interactions can use direct references.
- **Color palette:** Static class `P` holds all `static readonly Color` constants (e.g., `P.CoinGold`, `P.MarioRed`).
- **Pipe warps:** Destination is a `WarpScenePath` + `WarpSpawnMarker` pair, not a `NodePath` — supports cross-scene warps (World 1-2, bonus rooms).
- **Hidden blocks:** Use a dual-shape approach — `StaticBody2D` collision starts disabled, a separate `Area2D` sensor detects upward head contact and triggers reveal.

### Z-Index Convention

- Background/terrain: 0
- Pipes: 5 (absolute, `ZAsRelative = false`)
- Player: 10 (dropped below pipe z during pipe warp tweens)
- HUD/UI: 100+

## C# / Godot Conventions

- Classes use `public partial class` (required by Godot source generators)
- Lifecycle methods: `_Ready()`, `_Process(double delta)`, `_PhysicsProcess(double delta)`
- Physics constants as `const` fields in `PascalCase` (e.g., `WalkSpeed`, `JumpVelocity`)
- Color constants as `static readonly` fields in `PascalCase` (e.g., `SkyBlue`, `MarioRed`)
- File naming: `PascalCase.cs` for scripts (e.g., `PlayerController.cs`, `EventBus.cs`)
- Directory naming: `PascalCase` for script directories (e.g., `Scripts/Player/PlayerStates/`)
- Scene naming: `snake_case.tscn`
- Use `StringName` for frequently-used string keys (input actions, signal names, registry keys)
- `Vector2` is a struct — cannot assign to `.X`/`.Y` directly; use `new Vector2(x, Scale.Y)` pattern

## Constraints

- The `.claude/settings.json` denies access to files outside this project directory
- AGENTS.md is excluded per hook configuration
