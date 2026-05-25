# AGENTS.md

Guidance for coding agents working in this repository.

## Project Overview

A 2D Super Mario Bros inspired platformer built in Godot 4.6 with C#. Ported from a working MonoGame/Nez project at `c:\dev\games-monogame\SuperMario`; mirror gameplay constants and behaviors from there rather than re-tuning.

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

If `godot` is not on PATH, use the local Windows executable:

```powershell
D:\Godot\Godot_v4.6.2-stable_mono_win64.exe --headless --path . --quit
D:\Godot\Godot_v4.6.2-stable_mono_win64.exe --path .
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

`GameInstance` is an autoload app shell that owns a `LevelRoot: Node` child. The active top-level screen is the single child of `LevelRoot` and is freed on every swap.

```
GameInstance (autoload) → LevelRoot → one of:
  scenes/main_menu.tscn
  GameMode → scenes/levels/world_X_Y.tscn   (inherits scenes/level_base.tscn)
  scenes/game_over.tscn
```

`GameMode` exists only during a playthrough. It owns `SaveData`, the `Campaign` cursor, the HUD, session-scoped visual helpers such as `TextSpawner`, and the active `LevelManager`. The player is re-spawned per level load, not persisted.

### Autoloads (3)

Registered in `project.godot` in this order:

- `GameInstance`: owns app-level screen swaps (`main_menu`, `GameMode`, `game_over`). Lifecycle-only; gameplay entities do not consult `GameInstance.Instance`, they go through `GameMode.Instance` instead.
- `MusicManager`: single `AudioStreamPlayer`. `Play(stream)` is idempotent by reference (re-playing the same stream is a no-op).
- `SfxManager`: pool of 10 `AudioStreamPlayer`s. Fire-and-forget; drops requests when pool exhausted.

`GameInstance` decides top-level app transitions. `GameMode` decides level transitions inside a playthrough. Scenes report what happened via signals; they never advance themselves.

### Configuration

- `Config` (`Scripts/Config.cs`): plain static class containing hard-coded project paths such as main menu, game over, and campaign.
- Do not scatter `res://...` paths through gameplay code. Add shared paths to `Config`.

### Per-Level Parameters

- `LevelDefinition` (`Scripts/Resources/LevelDefinition.cs`): `[GlobalClass] Resource` with `Name`, `LevelScene`, `MusicTrack`, `TimeLimit`. One `.tres` per level under `resources/levels/`.
- `Campaign` (`Scripts/Resources/Campaign.cs`): ordered `LevelDefinition[]`. Single instance at `resources/campaign.tres`.

Important — no cycles in `.tscn`/`.tres`: `LevelDefinition.tres` references its `LevelScene`. The level `.tscn` does not reference the `.tres` back — `GameMode` reads the `LevelDefinition` itself and uses the instantiated level only as a holder of scene references.

### Save data

- `SaveData` (`Scripts/SaveData.cs`) is a serializable `Resource` data container with exported properties such as score, coins, lives, power state, current level name, and remaining time.
- `SaveData` is passive. It should not own gameplay rules, mutation helpers, or change events.
- `GameMode` is the sole writer to `SaveData` and owns the change events consumed by HUD and other session UI.

### LevelManager and inherited level scenes

`scenes/level_base.tscn` is the inherited-level template, with root script `LevelManager` and required children:

- `PlayerStart` (`Marker2D`) — required spawn location, exposed by `LevelManager` as an `[Export]`
- `CleanupVolume` (`Area2D`) — broad mask, kills/frees anything that falls in
- `GoalTrigger` (`Area2D`) — emits `Reached` on player overlap, exposed by `LevelManager` as an `[Export]`

Each `scenes/levels/world_X_Y.tscn` inherits from `level_base.tscn` and adds level content.

`LevelManager` validates required `[Export]` references (`PlayerStart`, `GoalTrigger`), owns level-local marker scanning/spawning, wires level entity event sources, and relays level events upward to `GameMode`. All session-scoped concerns (music, HUD, lives, scene transitions, save-data mutation, player spawn, goal wiring) live in `GameMode`.

`CoinMarker` (`Scripts/Markers/CoinMarker.cs`) is the current marker/factory prototype: inherited level scenes place `CoinMarker` nodes, and `LevelManager` creates runtime coins via `Coin.Create(marker.GlobalPosition)`.

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

Four allowed coupling patterns:

1. Vertical ownership (parent ↔ child): call down, signal up. Child never reaches up.
2. Global or session-scoped visual/audio services: direct calls are allowed for `MusicManager.Instance`, `SfxManager.Instance`, and `TextSpawner.Spawn(...)`. These services must not mutate gameplay state. `GameInstance.Instance` is reserved for top-level lifecycle (`StartGame`, `LoadMainMenu`, `LoadGameOver`) and is not consulted by gameplay entities.
3. Session-scoped gameplay events: gameplay entities announce state changes through local events/interfaces such as `IScoreEventSource` and `ICoinEventSource`; `LevelManager` wires and relays those events upward; `GameMode` owns the corresponding handlers and is the sole writer to `SaveData`.
4. Sibling interactions: direct calls via combat interfaces; `Hitbox` → `PlayerController.TakeDamage`; `KillVolume` → `PlayerController.KillPlayer`.

Pickups emit gameplay events and never mutate save data. For example, `Coin` emits `ScoreEarned` and `CoinCollected`; `LevelManager` relays them; `GameMode` updates `SaveData`. `TextSpawner` is a session-scoped visual service created as a child of `GameMode`, and pickups may call `TextSpawner.Spawn(...)` directly because it is visual-only.

`GameMode.Instance` is still available as the entity-facing session locator for current transitional code such as `OneUp` and runtime projectile/enemy spawn parents. Prefer local events/interfaces plus `LevelManager` wiring for new gameplay state changes. `CurrentLevel` is the parent for runtime-spawned gameplay nodes. Writes to `SaveData` go through `GameMode`.

### Entity authoring

Prefer one `.cs` + one `.tscn` per authored entity, with marker/factory exceptions only when the architecture explicitly calls for them. No base classes for enemies / pickups / projectiles. Variants are `[Export]` enums on the leaf script.

- Enemies: scripts under `Scripts/Enemies/`; root `CharacterBody2D` + visual + body shape + child `Hitbox: Area2D` + (optional) `Walker`.
- Static pickups: scripts under `Scripts/Pickups/`; root `Area2D` + visual + shape. `Coin` is currently spawned from `CoinMarker` via `Coin.Create(...)` rather than authored as `scenes/entities/coin.tscn`.
- Dynamic pickups (Mushroom, OneUp, Starman): root `CharacterBody2D` + visual + body shape + (optional) `Walker` + child `PickupTrigger: Area2D`. The `PickupBody`/`PickupTrigger` layer split lets Mario walk through pickups while still triggering them.
- Blocks/platforms/level objects: scripts under `Scripts/Level/`; root node shape follows the entity type, commonly `StaticBody2D` + visual + shape + (optional) `Bumpable`.
- Projectiles: scripts under `Scripts/Projectiles/`; root `CharacterBody2D` or `Area2D` + visual + shape + child `HitArea: Area2D` + `Lifetime`. Spawned at runtime under `GameMode.Instance.CurrentLevel`.

### Player

`scenes/player.tscn` — `CharacterBody2D` with flat physics methods. No state machine, no drawer. Joins the `"player"` group in `_Ready` so AI-querying enemies can find it.

Power state is persisted in `SaveData.PowerState`. `GameMode` initializes the player with the saved power state and listens to the player's `PowerStateChanged` event. The player does not read or write `SaveData` directly.

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
- Typed-node `[Export]` fields require the `node_paths=PackedStringArray("Field1", "Field2", ...)` directive on the owning node's `[node ...]` line in the `.tscn`. The editor adds this automatically when you wire the field through the inspector. Hand-editing only `Field = NodePath("...")` leaves the typed reference null at runtime.
- All scripts use the single namespace `SuperMario`.
- Required scene wiring should fail loudly. Prefer `GetNode<T>()`, typed `PackedScene.Instantiate<T>()`, direct required exports, and direct singleton access over defensive null checks. Keep checks only for real gameplay/lifecycle state such as `_dead`, `_collected`, "is this body the player?", "is there an old node to free?", or optional data like `LevelDefinition.MusicTrack`.

## Forbidden

- EntityFactory-style enum/string registries. Marker/static-factory spawning is allowed only for explicit level-managed patterns such as `CoinMarker` -> `Coin.Create(...)`.

- `GetParent()`, `GetNode("../...")` — components reach their owner via `[Export]`.
- Base classes for enemies / pickups / projectiles — flat per-entity scripts implementing the combat interfaces they care about.
- Persistent player across levels — player is re-spawned by `GameMode` on each load.
- Autoload-owned scene transitions other than `GameInstance`.
- Cycles in `.tscn` ↔ `.tres` ext_resource references.

## Working Rules

- Respect user-stated constraints exactly. If the user rejects an approach, do not keep re-suggesting variants of it.
- Do not recommend hard-coded node-name lookups such as `GetNode<T>("ChildName")` when the user has asked for inspector-wired references. In that case, use explicit exported references or exported `NodePath`s, and validate that required references are assigned.
- Be careful with Godot C# export and scene-serialization issues. Before changing `.tscn` exported properties by hand, inspect the current scene files, explain the tradeoff, and prefer the smallest change that preserves the user's chosen wiring style.
- If a Godot editor/runtime cache issue is plausible, say so plainly and try rebuild/reload validation before redesigning code or scene wiring.
- Avoid hand-editing generated Godot files under `.godot/`, `*.uid`, or `*.import`.
- Keep new code aligned with [PLAN.md](PLAN.md) instead of inventing parallel architecture.
- If the plan and implementation disagree, resolve the contradiction explicitly instead of silently picking one.
