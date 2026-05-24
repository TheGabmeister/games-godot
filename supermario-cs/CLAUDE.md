# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

A 2D Super Mario Bros inspired platformer built in **Godot 4.6 with C#**. Ported from a working MonoGame/Nez project at `c:\dev\games-monogame\SuperMario` — mirror gameplay constants and behaviors from there rather than re-tuning.

Visuals are currently placeholder `ColorRect` primitives. Real sprite art is not yet sourced.

## Build & Run

```bash
# Build C# project
dotnet build supermario-cs.csproj

# Validate Godot project loads without errors
godot --headless --path . --quit

# Open in Godot editor (then F5 to run)
godot --path .
```

No test framework is configured. Validation is `dotnet build` + manual playtest in the editor. Always run `dotnet build` before `godot --headless` — the headless launch validates project structure, not C# syntax.

## Project Configuration

- **Engine:** Godot 4.6, Forward Plus renderer
- **SDK:** Godot.NET.Sdk 4.6.2, targeting .NET 8.0 (.NET 9.0 for Android)
- **Root namespace:** `SuperMario`
- **Viewport:** 512x448 px, window 1024x896 (2x scale, `canvas_items` stretch)
- **Main scene:** `res://scenes/boot.tscn` (one-shot bootstrap — `GameManager` autoload swaps top-level screens under its `LevelRoot` child)

## Architecture

### Scene flow

`GameManager` is an autoload app shell that owns a `LevelRoot: Node` child. The active top-level screen (main menu / game session / game over) is the single child of `LevelRoot` and is freed on every swap.

```
GameManager (autoload) → LevelRoot → one of:
  scenes/main_menu.tscn
  GameSession → scenes/levels/world_X_Y.tscn   (inherits scenes/level_base.tscn)
  scenes/game_over.tscn
```

`GameSession` exists only during a playthrough. It owns `GameState`, campaign progress, and the active level. The player is **re-spawned per level load**, not persisted. Matches MonoGame's clean-slate reload.

### Autoloads (3, in this order)

| Autoload | Responsibility |
|----------|----------------|
| **GameManager** | App shell. Swaps top-level screens (`main_menu`, `GameSession`, `game_over`) under `LevelRoot`. Lifecycle-only — gameplay entities do **not** consult `GameManager.Instance`; they go through `GameSession.Current` instead. |
| **MusicManager** | Single `AudioStreamPlayer`. `Play(stream)` is **idempotent by reference** — re-playing the same `AudioStream` is a no-op so same-level reloads don't restart music. |
| **SfxManager** | Pool of 10 `AudioStreamPlayer`s. Fire-and-forget; drops requests when pool exhausted. |

**Dependency direction is one-way.** Scenes report what happened (signals); `GameManager` decides top-level app transitions, and `GameSession` decides level transitions inside a playthrough.

### Configuration

`Scripts/Config.cs` is a plain static class containing hard-coded project paths such as main menu, game over, and campaign. Do not scatter `res://...` paths through gameplay code; add shared paths to `Config`.

### Per-Level Parameters

`Scripts/Resources/LevelDefinition.cs` is a `[GlobalClass] Resource` exporting `Name`, `LevelScene`, `MusicTrack`, `TimeLimit`. One `.tres` per level under `resources/levels/`.

`Scripts/Resources/Campaign.cs` holds the ordered `LevelDefinition[]`. `resources/campaign.tres` is the single instance; `GameSession` loads it from `Config.CampaignPath` when a run starts.

**Important — no cycles in `.tscn`/`.tres`:** `LevelDefinition.tres` references its `LevelScene` (PackedScene). The level `.tscn` does **not** reference the `.tres` back — `GameSession` reads the `LevelDefinition` itself (name, time limit, music) and uses the instantiated level only as a holder of scene references. This avoids a circular ext_resource parse error on import.

### `LevelBase` and inherited level scenes

`scenes/level_base.tscn` is the template, with required children:

- `PlayerStart` (`Marker2D`) — spawn location, exposed by `LevelBase` as an `[Export]`
- `CleanupVolume` (`Area2D`) — broad mask, kills/frees anything that falls in
- `GoalTrigger` (`Area2D`) — emits `Reached` on player overlap, exposed by `LevelBase` as an `[Export]`

Each `scenes/levels/world_X_Y.tscn` inherits from `level_base.tscn` and adds level content (terrain, blocks, enemies, pickups). `LevelBase` itself has **no behavior** — it is a passive holder of `[Export]` references (`PlayerStart`, `GoalTrigger`) so `GameSession` can spawn the player and wire the goal without reaching into the scene by node-name. All session-scoped concerns (music, HUD, lives, scene transitions, player spawn, goal wiring) live in `GameSession`.

### Combat interfaces

Defender decides its own reaction; attacker invokes the interface on the defender.

```csharp
IStompable.OnStomped(PlayerController)
IFireballHittable.OnHitByFireball() → FireballReaction (Defeated | Blocked)
IStarHittable.OnHitByStar(PlayerController)
IBumpable.OnBumped(PlayerController)
```

### Reusable components

Child-node scripts under `Scripts/Components/`. Each references its owner via `[Export]` — never `GetParent()`.

| Component | Purpose |
|-----------|---------|
| `Hitbox` (Area2D) | Universal damage volume. Branches on `IsStarInvincible` → `IStarHittable`; then `IStompable` if player is descending from above; else `player.TakeDamage()`. |
| `Walker` (Node) | Gravity + horizontal walk + turn-at-wall + optional turn-at-cliff + optional bounce-on-landing. Drives Goomba, BuzzyBeetle, Spiny, KoopaTroopa, Mushroom, OneUp, Starman. |
| `Bumpable` (Node) | Sine half-arc bump animation for blocks. Animates a target `Node2D` (the Sprite/Visual), not the collision body. |
| `Lifetime` (Node) | `QueueFree`s its parent after `Duration` seconds. Used by all three projectiles. |

### Wiring rules

Four allowed coupling patterns. Anything else is a smell.

1. **Vertical ownership (parent ↔ child): call down, signal up.** Parent instantiates child, holds reference, calls methods directly. Child emits signals; parent connects. Child never reaches up — `GetParent()`, `GetNode("../...")` are forbidden.
2. **Global services (autoloads): direct calls allowed.** Any node may call `MusicManager.Instance`, `SfxManager.Instance` directly. `GameManager.Instance` is reserved for top-level lifecycle (`StartGame`, `LoadMainMenu`, `LoadGameOver`) and is not consulted by gameplay entities.
3. **Session-scoped event bus: `GameSession.Current.Events`.** Gameplay entities (pickups, blocks, the player) announce facts ("I was collected for N points at position P", "player power state is now Fire") by emitting on `GameEvents`; `GameSession` is the sole subscriber that mutates `GameState`. Entities never call `State.X` setters directly.
4. **Sibling interactions: direct calls via interfaces.** Combat (`IFireballHittable`/`IStompable`/`IStarHittable`/`IBumpable`), `Hitbox` → `PlayerController.TakeDamage`, `KillVolume` → `PlayerController.KillPlayer`.

**Concrete consequence — pickups emit events, never mutate state.** Coin's `BodyEntered` calls `GameSession.Current.Events.EmitScoreEarnedAt(points, GlobalPosition)`. `GameEvents` also emits `ScoreEarned` for state updates; `TextPopupSpawner` listens to `ScoreEarnedAt` and spawns the floating text. Pickups don't know about `GameState`, text popups, or score values beyond their own constant.

**Concrete consequence — `GameSession.Current` is the entity-facing locator.** Static accessor set in `_EnterTree`/cleared in `_ExitTree`. Exposes `Events` (the bus), `State` (reads only — writes go through `Events`), and `CurrentLevel` (parent for runtime-spawned children like projectiles). Lifetime is session-scoped: null between sessions, non-null whenever any gameplay entity is alive.

**Concrete consequence — components reference their owner via `[Export]`** set in the inspector at scene-author time. Never `GetParent()`.

### Entity authoring

One `.cs` + one `.tscn` per entity type. No base classes for enemies / pickups / projectiles. Variants are `[Export]` enums on the leaf script (e.g. `KoopaColor`, `MovingPlatformAxis`).

- **Enemies:** root `CharacterBody2D` + `Visual` + body `CollisionShape2D` + child `Hitbox: Area2D` + (optional) `Walker`.
- **Static pickups (Coin, FireFlower):** root `Area2D` + visual + shape.
- **Dynamic pickups (Mushroom, OneUp, Starman):** root `CharacterBody2D` + visual + body shape + (optional) `Walker` + child `PickupTrigger: Area2D`. The `PickupBody`/`PickupTrigger` layer split lets Mario walk through pickups while still triggering them.
- **Blocks (Brick, Question, Used):** root `StaticBody2D` + `Visual` + shape + (optional) `Bumpable`.
- **Projectiles (Fireball, Hammer, BulletBill):** root `CharacterBody2D` or `Area2D` + visual + shape + child `HitArea: Area2D` + `Lifetime`. Spawned at runtime by their spawner via `GameSession.Current.CurrentLevel.AddChild(...)`.

### Player

`scenes/player.tscn` — `CharacterBody2D` with flat physics methods. **No state machine, no drawer.** Joins the `"player"` group in `_Ready` so AI-querying enemies can find it via `GetTree().GetFirstNodeInGroup("player")`.

Power state is owned by `GameState.PowerState`. The player reads it on `_Ready` (via `GameSession.Current.State.PowerState`) and writes through by emitting `GameSession.Current.Events.EmitPlayerPowerStateChanged(newState)` on transitions; `GameSession` is the sole writer to `GameState`.

Head-bump detection: after `MoveAndSlide`, iterate `GetSlideCollisionCount()`; on a collision with normal `Y > 0.9`, if the collider implements `IBumpable`, dispatch `OnBumped(this)`. (The general rule: whoever holds the contextual data owns the detection. Block-bumps need the player's velocity / collision normal, so the player owns them.)

Fireballs are capped at `Constants.MaxFireballs = 2`. Spawned ones decrement the counter via `NotifyFireballDestroyed()` in `Destroy` and `_ExitTree`.

## Physics layers (8, named in `project.godot`)

| # | Name | Used by |
|---|------|---------|
| 1 | `Player` | `PlayerController` body |
| 2 | `Enemy` | Enemy `CharacterBody2D` body + `Hitbox` Area2D |
| 3 | `PickupBody` | Dynamic pickup `CharacterBody2D` body |
| 4 | `Environment` | Terrain, platforms, blocks |
| 5 | `Projectile` | Player projectile body + `HitArea` Area2D |
| 6 | `EnemyProjectile` | Enemy projectile body + `HitArea` Area2D |
| 7 | `PickupTrigger` | Pickup trigger Area2D (static pickups: also the body) |
| 8 | `LevelTrigger` | `GoalTrigger`, `KillVolume`, `CleanupVolume` |

**Critical invariant:** the Player body's mask does **not** include `PickupBody`. Mario walks through pickups while triggering them via `PickupTrigger`.

## C# / Godot conventions

- Classes use `public partial class` (required by Godot source generators)
- Lifecycle methods: `_Ready()`, `_Process(double delta)`, `_PhysicsProcess(double delta)` — `delta` is `double` in Godot C#, not `float`
- Gameplay constants live in `Scripts/Constants.cs` as `const` fields in `PascalCase`; mirror values from `c:\dev\games-monogame\SuperMario\Source\Constants.cs` rather than re-tuning
- Layer flags live in the static `Layers` class (`Layers.Player`, etc.) — keep bit positions in sync with the 2D physics layer names in `project.godot`
- File naming: `PascalCase.cs` for scripts (e.g., `PlayerController.cs`), `snake_case.tscn` for scenes
- Directory naming: `PascalCase` for script directories (e.g., `Scripts/Player/`)
- Use `StringName` for frequently-used keys (input actions, signal names, registry keys)
- `Vector2` is a struct — can't assign to `.X`/`.Y` directly; use `new Vector2(x, Scale.Y)` pattern
- Typed-Node `[Export]` fields require the `node_paths=PackedStringArray("Field1", "Field2", ...)` directive on the owning node's `[node ...]` line in the `.tscn`. The editor adds this automatically when you wire the field via the inspector. Hand-editing the `.tscn` with only `Field = NodePath("...")` (no `node_paths=`) leaves the field as a raw `NodePath` and the typed reference stays null at runtime. Working examples: [scenes/level_base.tscn](scenes/level_base.tscn) (`PlayerStart`, `GoalTrigger`), [scenes/hud.tscn](scenes/hud.tscn) (the four `Label` fields). When in doubt, set the export through the editor inspector so Godot writes the directive correctly.
- All scripts use the single namespace `SuperMario`.
- Required scene wiring should fail loudly. Prefer `GetNode<T>()`, typed `PackedScene.Instantiate<T>()`, direct required exports, and direct singleton access over defensive null checks. Keep checks only for real gameplay/lifecycle state such as `_dead`, `_collected`, "is this body the player?", "is there an old node to free?", or optional data like `LevelDefinition.MusicTrack`.

## Forbidden

- `GetParent()`, `GetNode("../...")` — components reach their owner via `[Export]`
- Base classes for enemies / pickups / projectiles — flat per-entity scripts implementing the combat interfaces they care about
- EntityFactory-style registries — drag entity `.tscn`s into level scenes at edit time
- Persistent player across levels — player is re-spawned by `GameSession` on each load
- Autoload-owned scene transitions other than `GameManager`
- Cycles in `.tscn` ↔ `.tres` ext_resource references

## Constraints

- The `.claude/settings.json` denies access to files outside this project directory
- AGENTS.md is excluded per hook configuration
