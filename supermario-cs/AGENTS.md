# AGENTS.md

Guidance for coding agents working in this repository.

## Project Overview

A 2D Super Mario Bros inspired platformer built in Godot 4.6 with C#.

- Visuals are procedural primitive shapes only.
- The design source of truth is [SPEC.md](SPEC.md).
- Repo-specific implementation guidance also exists in [CLAUDE.md](CLAUDE.md).

## Build and Validation

Run these from the repo root:

```bash
dotnet build supermario-cs.csproj
godot --headless --path . --quit
godot --path .
```

Notes:

- Run `dotnet build` before `godot --headless`; the headless check validates the Godot project structure, not C# syntax.
- No dedicated automated test framework is configured yet.

## Project Configuration

- Engine: Godot 4.6
- Renderer: Forward Plus
- SDK: Godot.NET.Sdk 4.6.2
- Target framework: .NET 8.0
- Root namespace: `supermariocs`
- Viewport: `512x448`
- Window: `1024x896`
- Stretch mode: `canvas_items`
- Tile grid: `16x16`
- Main scene: `res://scenes/main.tscn`

## Architecture

### Scene Ownership Model

`main.tscn` is the persistent shell and should not be unloaded.

Persistent under `Main`:

- Player
- HUD
- `WorldEnvironment`
- overlay / transition UI

Loaded per level into `SceneRoot`:

- terrain
- blocks
- enemies
- pipes
- kill zones
- spawn markers
- camera bounds
- background decoration

Rules:

- `SceneManager` loads and swaps level scenes under `SceneRoot`.
- On level load, move the existing player to the level's `PlayerSpawn` marker.
- On death/respawn, reposition the player instead of instantiating a new one.

### Autoloads

The project expects these `Node`-based singletons:

- `EventBus`: cross-system signals
- `GameManager`: score, coins, lives, timer, power state, game state
- `AudioManager`: music and SFX
- `SceneManager`: transitions, scene loading, level intro flow
- `CameraEffects`: shake and freeze-frame behavior on the active camera

### State Ownership

- `GameManager.CurrentPowerState` is the single source of truth for Mario's power form.
- Player states must update power via `GameManager.SetPowerState(...)`.
- Respawn should restore the player from `GameManager`, not from a duplicate local copy.

## Gameplay Patterns

- Use `CharacterBody2D` for the player and enemy actors that need deterministic movement.
- Keep gameplay logic separate from rendering with the drawer pattern:
  gameplay on the main node, visuals in a child `*Drawer` node using `_Draw()`.
- Prefer EventBus signals for non-local communication such as HUD, scoring, audio, and effects.
- Terrain belongs in `TileMapLayer`; interactive blocks and objects should remain separate scene instances.
- Pipe warp destinations should be modeled as `WarpScenePath` plus `WarpSpawnMarker`, not a raw `NodePath`.
- Hidden blocks need a separate detection mechanism; do not rely on a fully non-colliding block somehow being hit.

## Conventions

- Use `public partial class` for Godot C# scripts.
- Use `_Ready()`, `_Process(double delta)`, and `_PhysicsProcess(double delta)`.
- Use `PascalCase.cs` for script filenames.
- Use `snake_case.tscn` for scenes.
- Use `PascalCase` for script directories.
- Use `StringName` for repeated keys like actions, signal names, and registries.
- Keep color constants in a shared palette class, typically `P`.

## Collision Layers

| Layer | Name |
|-------|------|
| 1 | Terrain |
| 2 | Player |
| 3 | Enemies |
| 4 | PlayerHitbox |
| 5 | EnemyHitbox |
| 6 | Items |
| 7 | Fireballs |
| 8 | KoopaShell |
| 9 | KillZone |
| 10 | Interactable |

## Working Rules

- Avoid hand-editing generated Godot files under `.godot/`, `*.uid`, or `*.import`.
- Keep new code aligned with the current spec instead of inventing parallel architecture.
- If the spec and implementation disagree, resolve the contradiction explicitly instead of silently picking one.
