# CLAUDE.md

Guidance for coding agents working in this repository.

## Project

2D Super Mario Bros platformer in Godot 4.6 + C# (.NET 8 / .NET 9 Android). Ported from a working MonoGame/Nez project at `c:\dev\games-monogame\SuperMario`; mirror gameplay constants and behaviors from there rather than re-tuning. Visuals are placeholder `ColorRect` primitives.

## Build & Validation

```bash
dotnet build supermario-cs.csproj      # compile C#
godot --headless --path . --quit       # validate project structure
godot --path .                         # open editor
```

If `godot` is not on PATH on Windows, use `D:\Godot\Godot_v4.6.2-stable_mono_win64.exe`. Always run `dotnet build` before `godot --headless`; headless validates project structure, not C# syntax. No automated tests; validation is build + manual playtest.

## Working Rules

- Respect user-stated constraints exactly. If the user rejects an approach, do not keep re-suggesting variants of it.
- Prefer inspector-wired references over hard-coded lookups. When inspector wiring is requested, use exported typed references or `NodePath`s; do not fall back to `GetNode<T>("ChildName")`.
- Edit `.tscn` files with care. Before changing exported properties or scene wiring by hand, inspect the current `.tscn`, explain the tradeoff, and prefer the smallest change that preserves the user's chosen wiring style.
- Suspect Godot editor/runtime cache issues before redesigning. If a cache issue is plausible, say so plainly and try rebuild/reload validation before changing code or scene wiring.
- Do not hand-edit generated files under `.godot/`, `*.uid`, or `*.import`.
- Score/coin gameplay state is handled by `GameMode` through narrow interfaces and code spawning. Do not reintroduce `GameEvents`, static event buses, event source interfaces, tree-walking event scanners, or no-op/null-object handlers for required score/coin dependencies.

## Architecture

**One autoload: `GameInstance`.** Entry point and app-lifetime service locator. Access it via `GameServices.GetGameInstance()` or the globally imported `GetGameInstance()` helper; it does not expose a static `Instance` property. `boot.tscn` is an empty marker scene; the real flow is in `GameInstance.PostBoot`, which defers one frame after `_Ready`, reads `GetTree().CurrentScene`, and branches:

- **Path is `boot.tscn`** -> `LoadMainMenu()` (normal launch).
- **A `LevelManager` and `OS.HasFeature("editor")`** -> look up the scene's index in `Campaign.tres`, `UnloadCurrentScene()`, `StartGame(index)` (F6 skip-to-level workflow).
- **Anything else** -> sandbox; services available, no session started.

Top-level screens (`MainMenuController`, `GameMode`, `GameOverController`) are spawned as `GameInstance` children. `MusicManager` and `SfxManager` are also spawned as `GameInstance` children, not autoloads.

### Service Access

| Accessor | Scope | Set in |
|---|---|---|
| `GetGameInstance()` | App | `GameInstance` autoload |
| `GetGameMode()` | Session | `GameInstance.StartGame` / cleared on game over |
| `GameMode.TextSpawner` | Level/session UI | `GameMode.Start` |

`Scripts/_Core/GameServices.cs` is a static facade globally imported by `Scripts/_Core/GlobalUsings.cs`. It provides `GetGameInstance()`, `GetGameMode()`, `SpawnText(...)`, `PlaySfx(...)`, and `PlayMusic(...)`. The returned `GameInstance`, `GameMode`, and `TextSpawner` objects are normal instances, not static singletons. `MusicManager` and `SfxManager` are not statics either; reach them through `GameInstance.Music` / `GameInstance.Sfx` (or, more commonly, via `PlayMusic(...)` / `PlaySfx(...)`).

### Score And Coin Interfaces

`GameMode` is the sole owner of live score, coin, lives, and related session state. `SaveData` is only updated when `GameMode.SaveGame()` copies the live state into the save payload. Score and coin collection use narrow capability interfaces:

- `IScoreAwarder.AwardScore(int points)`
- `ICoinCollector.CollectCoins(int coins)`

`GameMode` implements both interfaces. Runtime-spawned pickups and blocks receive only the capabilities they need through their static `Create(...)` methods:

```csharp
level.AddChild(Coin.Create(m.GlobalPosition, this, this));
level.AddChild(Mushroom.Create(m.GlobalPosition, this));
```

Dependencies are assigned inside `Create(...)`; do not expose separate public `Initialize(...)` methods for score/coin wiring unless the spawning model changes. These dependencies are required for correct gameplay. Do not use `?.`, no-op/null-object implementations, or silent fallbacks for missing score/coin handlers.

`GameMode`'s own events (`SessionEnded`, `ScoreChanged`, `LivesChanged`, etc.) are HUD-facing, not entity-facing. HUD subscribes via `_hud.Bind(this)`.

### Marker-Based Entity Spawning

Pickups and blocks are runtime-spawned from markers, not placed in level scenes directly. Each level scene has a `Markers` node wired to `LevelManager._markerRoot`. `LevelManager` only validates `PlayerStart`, `GoalTrigger`, `_markerRoot`, and exposes the marker children through `Markers`; it does not spawn gameplay objects and does not know about score/coin services.

`GameMode` owns marker interpretation and object spawning in `SpawnLevelObjects(LevelManager level)`:

```csharp
case CoinMarker m:
    level.AddChild(Coin.Create(m.GlobalPosition, this, this));
    break;
case QuestionBlockMarker m:
    level.AddChild(QuestionBlock.Create(m.GlobalPosition, this, this));
    break;
```

One marker class per entity type, each a minimal `Marker2D` subclass (extending `LabeledMarker` for editor visibility). Per-instance config goes on the marker as `[Export]` fields. Each runtime-spawned entity has a static `Create(...)` factory that loads its scene from `Config`, instantiates, assigns injected dependencies, sets position, and returns. `Coin` is the one exception: it builds its visual programmatically and has no `.tscn`.

Entities without event emission (most enemies, decorations) are placed in the level scene at edit time.

### Combat - Defender Decides Reaction

`IStompable`, `IFireballHittable`, `IStarHittable`, `IBumpable`. The attacker invokes the interface; the defender chooses the reaction. These are not event sources; they are direct sibling dispatch.

## Rules

### Allowed Coupling

1. **Vertical ownership.** Parent calls down, child signals up. Components reach their owner via `[Export]`. Never `GetParent()` / `GetNode("../...")`.
2. **App services.** `MusicManager` and `SfxManager` are owned by `GameInstance` and reached through `GameServices` (`PlayMusic(...)`, `PlaySfx(...)`) or `GetGameInstance().Music` / `GetGameInstance().Sfx`. They are not statics; do not add an `Instance` accessor back.
3. **Score/coin services.** `GameMode` implements `IScoreAwarder` and `ICoinCollector`. It passes itself into runtime-spawned entities through their `Create(...)` methods. Do not resolve score/coin handlers from `_Ready()`.
4. **Session service locator access.** Use `GetGameMode()` for runtime projectile/enemy spawn parents and one-up awards. Use `SpawnText(...)` for floating text where injection has not yet reached. Use `PlaySfx(...)` / `PlayMusic(...)` for audio.
5. **Sibling interactions.** Direct calls via combat interfaces.

### Forbidden

- `GetParent()`, `GetNode("../...")`; use `[Export]`.
- Base classes for enemies / pickups / projectiles. Flat per-entity scripts.
- EntityFactory-style enum/string registries; `GameMode.SpawnLevelObjects` is the explicit marker dispatch point.
- Persistent player across levels; re-spawned per level.
- Re-introducing `GameEvents`, `IScoreEventSource` / `ICoinEventSource`, or tree-walking event scanners.
- Re-adding `MusicManager.Instance` / `SfxManager.Instance` statics. Go through `GameInstance` or `GameServices`.
- New autoloads beyond `GameInstance`.
- Cycles in `.tscn` <-> `.tres` ext_resource references.

### Required Invariants

- The Player body's `CollisionMask` does **not** include `PickupBody`. Mario walks through pickups; triggering happens via `PickupTrigger`.
- `GameMode` is the sole owner of live session state and the owner of runtime object spawning from level markers. `SaveData` should only be updated through `GameMode.SaveGame()`.
- A level scene must have `PlayerStart`, `GoalTrigger`, and `_markerRoot` exports wired; `LevelScope._Ready` throws otherwise.

## Conventions

- `public partial class` for all Godot C# scripts. Gameplay classes use namespace `SMB`.
- `delta` is `double` in `_Process` / `_PhysicsProcess`, not `float`.
- `Vector2` is a struct; assign via `new Vector2(x, Scale.Y)`, not `Scale.X = x`.
- File naming: `PascalCase.cs`, `snake_case.tscn`. Directories: `PascalCase`.
- `StringName` for repeated keys (input actions, signal names).
- Collision bit positions in `Scripts/_Core/PhysicsLayers.cs` must stay in sync with the named 2D physics layers in `project.godot`.
- Shared score/life rules live in `Resources/GameRules.tres`; shared player tuning lives in `Resources/PlayerTuning.tres`; prefab-local tuning belongs on exported scene properties.
- **Required scene wiring should fail loudly.** Prefer typed exports and `PackedScene.Instantiate<T>()` over defensive null checks. Keep checks only for real gameplay/lifecycle state (`_dead`, `_collected`, "is this body the player?", optional resource fields).

### `node_paths` Directive Gotcha

Typed-Node `[Export]` fields require `node_paths=PackedStringArray("Field1", ...)` on the owning node's `[node ...]` line in the `.tscn`. The editor writes this when you wire a field through the inspector. Hand-editing only `Field = NodePath("...")` without the `node_paths=` directive leaves the typed reference **null at runtime**. When in doubt, wire through the inspector.

## Constraints

- `.claude/settings.json` denies file access outside this project directory.
