# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

2D Super Mario Bros platformer in Godot 4.6 + C# (.NET 8 / .NET 9 Android). Ported from a working MonoGame/Nez project at `c:\dev\games-monogame\SuperMario` — mirror gameplay constants and behaviors from there rather than re-tuning. Visuals are placeholder `ColorRect` primitives.

## Build & Run

```bash
dotnet build supermario-cs.csproj      # compile C#
godot --headless --path . --quit       # validate project structure
godot --path .                         # open editor
```

If `godot` is not on PATH: `D:\Godot\Godot_v4.6.2-stable_mono_win64.exe`. Always run `dotnet build` before `godot --headless` — headless validates project structure, not C# syntax. No test framework; validation is build + manual playtest.

## Architecture

**One autoload: `GameInstance`.** Entry point and app-lifetime service locator. Access it via `GameServices.GetGameInstance()` or the globally imported `GetGameInstance()` helper; it does not expose a static `Instance` property. `boot.tscn` is an empty marker scene; the real flow is in `GameInstance.PostBoot`, which defers one frame after `_Ready`, reads `GetTree().CurrentScene`, and branches:

- **Path is `boot.tscn`** → `LoadMainMenu()` (normal launch).
- **A `LevelManager` and `OS.HasFeature("editor")`** → look up the scene's index in `Campaign.tres`, `UnloadCurrentScene()`, `StartGame(index)` (F6 skip-to-level workflow).
- **Anything else** → sandbox; services available, no session started.

Top-level screens (`MainMenuController`, `GameMode`, `GameOverController`) live under `GameInstance.LevelRoot`. `MusicManager` and `SfxManager` are spawned as `GameInstance` children (not autoloads); same `.Instance` API.

### Static accessors

| Accessor | Scope | Set in |
|---|---|---|
| `MusicManager.Instance`, `SfxManager.Instance` | App | `_Ready` |
| `GetGameMode()` | Session | `GameInstance.StartGame` / cleared on game over |
| `GameMode.TextSpawner` | Level/session UI | `GameMode.Start` |

### `GameEvents` — injected, not static

`Scripts/_Core/GameEvents.cs` is a plain C# class with **no static accessor**. Owned by `GameMode` as `private readonly GameEvents _events = new()` and injected down the spawn chain:

```
GameMode._events
   ↓ assigned to LevelManager.Events before AddChild
LevelManager.Events
   ↓ passed into Entity.Create(pos, events)
Entity._events
```

Emitters call `_events.EmitScoreEarned(...)`. `GameMode` subscribes once in `Start`. No interface-based discovery, no tree-walking event scanners.

`GameMode`'s own events (`SessionEnded`, `ScoreChanged`, `LivesChanged`, etc.) are HUD-facing, not entity-facing. HUD subscribes via `_hud.Bind(this)`.

### Marker-based entity spawning

Pickups and blocks that emit events are runtime-spawned from markers, not placed in level scenes directly. Each level scene has a `Markers` node wired to `LevelManager._markerRoot`. `LevelManager.SpawnMarkers` dispatches by C# pattern matching:

```csharp
case CoinMarker m:           AddChild(Coin.Create(m.GlobalPosition, Events));         break;
case QuestionBlockMarker m:  AddChild(QuestionBlock.Create(m.GlobalPosition, Events));break;
```

One marker class per entity type, each a minimal `Marker2D` subclass. Per-instance config goes on the marker as `[Export]` fields. Each emitter entity has a static `Create(Vector2 pos, GameEvents events)` factory that loads its scene from `Config`, instantiates, sets position and events, and returns. (`Coin` is the one exception — it builds its visual programmatically and has no `.tscn`.)

Entities without event emission (most enemies, decorations) are placed in the level scene at edit time.

### Combat — defender decides reaction

`IStompable`, `IFireballHittable`, `IStarHittable`, `IBumpable`. The attacker invokes the interface; the defender chooses the reaction. These are not event sources — they are direct sibling dispatch.

## Rules

### Allowed coupling

1. **Vertical ownership.** Parent calls down, child signals up. Components reach their owner via `[Export]`. Never `GetParent()` / `GetNode("../...")`.
2. **App services.** Direct static access to `MusicManager.Instance`, `SfxManager.Instance` remains allowed. `GameInstance` is available through `GetGameInstance()` for top-level lifecycle and service-locator access. `GameServices` also provides `GetGameMode()`, `GetGameEvents()`, `SpawnText(...)`, `PlaySfx(...)`, and `PlayMusic(...)`.
3. **Score/coin events.** Inject `GameEvents` via the `Create(pos, events)` factory. No static event bus, no interface scanner.
4. **Session service locator access.** Use `GetGameMode()` for runtime projectile/enemy spawn parents and one-up awards. Use `SpawnText(...)` for floating text where injection has not yet reached.
5. **Sibling interactions.** Direct calls via combat interfaces.

### Forbidden

- `GetParent()`, `GetNode("../...")` — use `[Export]`.
- Base classes for enemies / pickups / projectiles. Flat per-entity scripts.
- EntityFactory-style enum/string registries — `LevelManager.SpawnMarkers` is the single dispatch point.
- Persistent player across levels — re-spawned per level.
- Re-introducing `IScoreEventSource` / `ICoinEventSource` or tree-walking event scanners.
- New autoloads beyond `GameInstance`.
- Cycles in `.tscn` ↔ `.tres` ext_resource references.

### Required invariants

- The Player body's `CollisionMask` does **not** include `PickupBody`. Mario walks through pickups; triggering happens via `PickupTrigger`.
- `GameMode` is the sole writer to `SaveData`.
- A level scene must have `PlayerStart`, `GoalTrigger`, and `_markerRoot` exports wired — `LevelManager._Ready` throws otherwise.

## Conventions

- `public partial class` for all Godot C# scripts. Gameplay classes and the static service helper use namespace `SMB`.
- `delta` is `double` in `_Process` / `_PhysicsProcess`, not `float`.
- `Vector2` is a struct — assign via `new Vector2(x, Scale.Y)`, not `Scale.X = x`.
- File naming: `PascalCase.cs`, `snake_case.tscn`. Directories: `PascalCase`.
- `StringName` for repeated keys (input actions, signal names).
- Gameplay constants in `Scripts/_Core/Constants.cs`; mirror values from the MonoGame port rather than re-tuning.
- Layer bit positions in `Scripts/_Core/Layers.cs` must stay in sync with the named 2D physics layers in `project.godot`.
- **Required scene wiring should fail loudly.** Prefer typed exports and `PackedScene.Instantiate<T>()` over defensive null checks. Keep checks only for real gameplay/lifecycle state (`_dead`, `_collected`, "is this body the player?", optional resource fields).

### `node_paths` directive gotcha

Typed-Node `[Export]` fields require `node_paths=PackedStringArray("Field1", ...)` on the owning node's `[node ...]` line in the `.tscn`. The editor writes this when you wire a field through the inspector. Hand-editing only `Field = NodePath("...")` (without the `node_paths=` directive) leaves the typed reference **null at runtime**. When in doubt, wire through the inspector.

## Constraints

- `.claude/settings.json` denies file access outside this project directory.
- AGENTS.md is excluded per hook configuration.
