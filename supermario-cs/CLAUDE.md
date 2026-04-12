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

No test framework is configured. Validation is done by building and running in the Godot editor.

## Project Configuration

- **Engine:** Godot 4.6, Forward Plus renderer
- **SDK:** Godot.NET.Sdk 4.6.2, targeting .NET 8.0 (.NET 9.0 for Android)
- **Root namespace:** `supermariocs`
- **Viewport:** 512x448 px, window 1024x896 (2x scale, `canvas_items` stretch)
- **Tile grid:** 16x16 px (32x28 visible tiles)
- **Main scene:** `res://scenes/main.tscn`

## Architecture

### Autoload Singletons

Five global singletons registered in `project.godot`, all extending `Node`:

| Singleton | Responsibility |
|-----------|---------------|
| **EventBus** | Central signal hub for cross-system communication (player, scoring, level, enemy, block signals) |
| **GameManager** | Persistent game state: score, coins, lives, power state, game state machine, timer |
| **AudioManager** | Music crossfade (2 players), pooled SFX (10 non-positional + 6 positional), registry pattern with safe no-op on empty paths |
| **SceneManager** | Fade transitions, scene loading, level intro overlays |
| **CameraEffects** | Screen shake and freeze frame on the active Camera2D |

### Player Controller

`CharacterBody2D` with a **state machine** pattern. Each state (`PlayerState` subclass) implements `Enter()`, `Exit()`, `ProcessInput()`, `ProcessFrame()`, `ProcessPhysics()`.

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
- **Enemies:** All extend a shared base (`CharacterBody2D`). Gravity, wall reversal, edge detection, and off-screen cleanup are shared behavior.
- **Blocks:** `StaticBody2D` roots. Question blocks are content-generic via an exported `contents` field. Brick behavior depends on player power state.
- **Primitive rendering:** All characters/objects use `Polygon2D`, `Line2D`, `draw_rect()`, `draw_circle()`, `ColorRect`. Only terrain uses `TileMapLayer`.

### Enums

```csharp
enum PowerState { Small, Big, Fire }
enum GameState { Title, Playing, Paused, GameOver, LevelComplete, Transitioning }
```

### Z-Index Convention

- Background/terrain: 0
- Pipes: 5 (absolute, `z_as_relative = false`)
- Player: 10 (dropped below pipe z during pipe warp tweens)
- HUD/UI: 100+

## C# / Godot Conventions

- Classes use `public partial class` (required by Godot source generators)
- Lifecycle methods: `_Ready()`, `_Process(double delta)`, `_PhysicsProcess(double delta)`
- Physics constants as `const` fields in `UPPER_CASE`
- File naming: `snake_case.cs` for scripts
- Scene naming: `snake_case.tscn`
- Use `StringName` for frequently-used string keys (input actions, signal names, registry keys)

## Constraints

- The `.claude/settings.json` denies access to files outside this project directory
- AGENTS.md is excluded per hook configuration
- The SPEC.md uses GDScript syntax for examples but this is a **C# project** — translate all GDScript patterns to idiomatic C#
