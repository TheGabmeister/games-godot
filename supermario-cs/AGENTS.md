# AGENTS.md

Guidance for coding agents working in this repository.

## Project Overview

A 2D Super Mario Bros inspired platformer built in Godot 4.6 with C#. Ported from a working MonoGame/Nez project at `c:\dev\games-monogame\SuperMario`.

- Visuals are currently placeholder `ColorRect` primitives. No sprite assets yet.
- Implementation specification: [PLAN.md](PLAN.md).
- Repo-specific implementation guidance: [CLAUDE.md](CLAUDE.md).

## Build and Validation

Run these from the repo root:

```bash
dotnet build supermario-cs.csproj
godot --headless --path . --quit
godot --path .
```

Notes:

- Run `dotnet build` before `godot --headless`; the headless check validates the Godot project structure, not C# syntax.
- No automated test framework is configured. Validation is build + manual playtest.

## Project Configuration

- Engine: Godot 4.6
- Renderer: Forward Plus
- SDK: Godot.NET.Sdk 4.6.2
- Target framework: .NET 8.0 (.NET 9.0 for Android)
- Root namespace: `SuperMario`
- Viewport: `512x448`
- Window: `1024x896`
- Stretch mode: `canvas_items`
- Main scene: `res://scenes/boot.tscn` (one-shot bootstrap)

## Architecture

### Scene flow

`GameManager` is an autoload app shell that owns a `LevelRoot: Node` child. The active top-level screen is the single child of `LevelRoot` and is freed on every swap.

```
GameManager (autoload) → LevelRoot → one of:
  scenes/main_menu.tscn
  GameSession → scenes/levels/world_X_Y.tscn   (inherits scenes/level_base.tscn)
  scenes/game_over.tscn
```

`GameSession` exists only during a playthrough. It owns `GameState`, the `Campaign` cursor, and the active `LevelBase`. The player is re-spawned per level load, not persisted.

### Autoloads (3)

Registered in `project.godot` in this order:

- `GameManager`: owns app-level screen swaps (`main_menu`, `GameSession`, `game_over`) and exposes pass-through `State` / `CurrentLevel` properties for gameplay code.
- `MusicManager`: single `AudioStreamPlayer`. `Play(stream)` is idempotent by reference (re-playing the same stream is a no-op).
- `SfxManager`: pool of 10 `AudioStreamPlayer`s. Fire-and-forget; drops requests when pool exhausted.

`GameManager` decides top-level app transitions. `GameSession` decides level transitions inside a playthrough. Scenes report what happened via signals; they never advance themselves.

### Configuration

- `Config` (`Scripts/Config.cs`): plain static class containing hard-coded project paths such as main menu, game over, and campaign.
- Do not scatter `res://...` paths through gameplay code. Add shared paths to `Config`.

### Per-Level Parameters

- `LevelDefinition` (`Scripts/Resources/LevelDefinition.cs`): `[GlobalClass] Resource` with `Name`, `LevelScene`, `MusicTrack`, `TimeLimit`. One `.tres` per level under `resources/levels/`.
- `Campaign` (`Scripts/Resources/Campaign.cs`): ordered `LevelDefinition[]`. Single instance at `resources/campaign.tres`.

Important — no cycles in `.tscn`/`.tres`: `LevelDefinition.tres` references its `LevelScene`. The level `.tscn` does not reference the `.tres` back — `GameSession` calls `level.Initialize(def, State)` programmatically after instantiation.

### LevelBase and inherited level scenes

`scenes/level_base.tscn` is the template, with required children:

- `PlayerStart` (`Marker2D`) — required; `LevelBase` instantiates the player here
- `CleanupVolume` (`Area2D`) — broad mask, kills/frees anything that falls in
- `GoalTrigger` (`Area2D`) — emits `Reached` on player overlap

Each `scenes/levels/world_X_Y.tscn` inherits from `level_base.tscn` and adds level content.

`LevelBase` owns level-local setup only: play optional level music, spawn the player at `PlayerStart`, wire `GoalTrigger`, spawn the HUD, and re-emit `PlayerDied` / `LevelCompleted`. It does not own campaign progress or persistent run state.

### Combat interfaces

Defender decides its own reaction; attacker invokes the interface on the defender.

```
IStompable.OnStomped(PlayerController)
IFireballHittable.OnHitByFireball() → FireballReaction (Defeated | Blocked)
IStarHittable.OnHitByStar(PlayerController)
IBumpable.OnBumped(PlayerController)
```

### Reusable components

Child-node scripts under `Scripts/Components/`. Each references its owner via `[Export]` — never `GetParent()`.

- `Hitbox` (Area2D): universal damage volume; branches on star-invincible → stomp → damage.
- `Walker` (Node): gravity + horizontal walk + turn-at-wall + optional turn-at-cliff + optional bounce-on-landing.
- `Bumpable` (Node): sine half-arc bump animation for blocks; animates a target `Node2D` (the visual), not the collision body.
- `Lifetime` (Node): `QueueFree`s its parent after `Duration` seconds.

### Wiring rules

Three allowed coupling patterns:

1. Vertical ownership (parent ↔ child): call down, signal up. Child never reaches up.
2. Global services (autoloads): direct calls allowed. Any node may call `GameManager.Instance` / `MusicManager.Instance` / `SfxManager.Instance`.
3. Sibling interactions: direct calls via combat interfaces; `Hitbox` → `PlayerController.TakeDamage`; `KillVolume` → `PlayerController.KillPlayer`.

Pickups mutate `GameState` directly — `GameManager.Instance.State.AddScore(...)`. Don't route pickup score through signals.

`GameState` is owned by `GameSession`. Access it through `GameManager.Instance.State` from gameplay code.

### Entity authoring

One `.cs` + one `.tscn` per entity. No base classes for enemies / pickups / projectiles. Variants are `[Export]` enums on the leaf script.

- Enemies: root `CharacterBody2D` + visual + body shape + child `Hitbox: Area2D` + (optional) `Walker`.
- Static pickups (Coin, FireFlower): root `Area2D` + visual + shape.
- Dynamic pickups (Mushroom, OneUp, Starman): root `CharacterBody2D` + visual + body shape + (optional) `Walker` + child `PickupTrigger: Area2D`. The `PickupBody`/`PickupTrigger` layer split lets Mario walk through pickups while still triggering them.
- Blocks: root `StaticBody2D` + visual + shape + (optional) `Bumpable`.
- Projectiles: root `CharacterBody2D` or `Area2D` + visual + shape + child `HitArea: Area2D` + `Lifetime`. Spawned at runtime via `GameManager.Instance.CurrentLevel.AddChild(...)`.

### Player

`scenes/player.tscn` — `CharacterBody2D` with flat physics methods. No state machine, no drawer. Joins the `"player"` group in `_Ready` so AI-querying enemies can find it.

Power state is owned by `GameState.PowerState`. The player reads it on `_Ready` and writes through `GameManager.Instance.State.PowerState` on transitions.

Head-bump detection lives on the player: after `MoveAndSlide`, iterate `GetSlideCollisionCount()`; on collision normal `Y > 0.9`, dispatch `IBumpable.OnBumped`.

Fireballs are capped at `Constants.MaxFireballs = 2`.

## Physics layers (8, named in `project.godot`)

| # | Name |
|---|------|
| 1 | `Player` |
| 2 | `Enemy` |
| 3 | `PickupBody` |
| 4 | `Environment` |
| 5 | `Projectile` |
| 6 | `EnemyProjectile` |
| 7 | `PickupTrigger` |
| 8 | `LevelTrigger` |

Critical invariant: the Player body's mask does not include `PickupBody`. Mario walks through pickups while triggering them via `PickupTrigger`.

Layer flags live in the static `Layers` class (`Layers.Player`, etc.) — keep bit positions in sync with the 2D physics layer names in `project.godot`.

## Conventions

- Use `public partial class` for Godot C# scripts.
- Use `_Ready()`, `_Process(double delta)`, and `_PhysicsProcess(double delta)`. `delta` is `double`, not `float`.
- Gameplay constants live in `Scripts/Constants.cs`; mirror values from MonoGame's `Constants.cs` rather than re-tuning.
- `PascalCase.cs` for script filenames.
- `snake_case.tscn` for scenes.
- `PascalCase` for script directories.
- Use `StringName` for repeated keys (input actions, signal names).
- `Vector2` is a struct — can't assign to `.X`/`.Y` directly.
- Typed-Node `[Export]` fields are unreliable when set via `NodePath` in `.tscn`. Prefer `GetNode<T>("...")` in `_Ready()` for child-node references, or set the export through the inspector.
- All scripts use the single namespace `SuperMario`.
- Required scene wiring should fail loudly. Prefer `GetNode<T>()`, typed `PackedScene.Instantiate<T>()`, direct required exports, and direct singleton access over defensive null checks. Keep checks only for real gameplay/lifecycle state such as `_dead`, `_collected`, "is this body the player?", "is there an old node to free?", or optional data like `LevelDefinition.MusicTrack`.

## Forbidden

- `GetParent()`, `GetNode("../...")` — components reach their owner via `[Export]`.
- Base classes for enemies / pickups / projectiles — flat per-entity scripts implementing the combat interfaces they care about.
- EntityFactory-style registries — drag entity `.tscn`s into level scenes at edit time.
- Persistent player across levels — player is re-spawned by `LevelBase` on each load.
- Autoload-owned scene transitions other than `GameManager`.
- Cycles in `.tscn` ↔ `.tres` ext_resource references.

## Working Rules

- Avoid hand-editing generated Godot files under `.godot/`, `*.uid`, or `*.import`.
- Keep new code aligned with [PLAN.md](PLAN.md) instead of inventing parallel architecture.
- If the plan and implementation disagree, resolve the contradiction explicitly instead of silently picking one.
