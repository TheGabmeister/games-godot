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
- New score/coin event code should use `GameEvents` injection. Do not reintroduce static event buses, event source interfaces, or tree-walking event scanners.

## Architecture

**One autoload: `GameInstance`.** Entry point and app-lifetime service locator. Access it via `GameServices.GetGameInstance()` or the globally imported `GetGameInstance()` helper; it does not expose a static `Instance` property. `boot.tscn` is an empty marker scene; the real flow is in `GameInstance.PostBoot`, which defers one frame after `_Ready`, reads `GetTree().CurrentScene`, and branches:

- **Path is `boot.tscn`** -> `LoadMainMenu()` (normal launch).
- **A `LevelManager` and `OS.HasFeature("editor")`** -> look up the scene's index in `Campaign.tres`, `UnloadCurrentScene()`, `StartGame(index)` (F6 skip-to-level workflow).
- **Anything else** -> sandbox; services available, no session started.

Top-level screens (`MainMenuController`, `GameMode`, `GameOverController`) live under `GameInstance.LevelRoot`. `MusicManager` and `SfxManager` are spawned as `GameInstance` children (not autoloads); same `.Instance` API.

### Service Access

| Accessor | Scope | Set in |
|---|---|---|
| `GetGameInstance()` | App | `GameInstance` autoload |
| `GetGameMode()` | Session | `GameInstance.StartGame` / cleared on game over |
| `GameMode.TextSpawner` | Level/session UI | `GameMode.Start` |

`Scripts/_Core/GameServices.cs` is a static facade globally imported by `Scripts/_Core/GlobalUsings.cs`. It provides `GetGameInstance()`, `GetGameMode()`, `GetGameEvents()`, `SpawnText(...)`, `PlaySfx(...)`, and `PlayMusic(...)`. The returned `GameInstance`, `GameMode`, `GameEvents`, and `TextSpawner` objects are normal instances, not static singletons. `MusicManager` and `SfxManager` are not statics either — reach them through `GameInstance.Music` / `GameInstance.Sfx` (or, more commonly, via `PlayMusic(...)` / `PlaySfx(...)`).

### `GameEvents` - Owned by GameMode, Fetched via `GameServices`

`Scripts/_Core/GameEvents.cs` is a plain C# class with no static accessor. Owned by `GameMode` as `private readonly GameEvents _events = new()` and exposed via `GameMode.Events` / `GameServices.GetGameEvents()`.

Emitters fetch and cache the reference in `_Ready()`:

```csharp
private GameEvents _events;

public override void _Ready()
{
    _events = GetGameEvents();
    ...
}
```

Then call `_events.EmitScoreEarned(...)` / `EmitCoinsCollected(...)`. `GameMode` subscribes once in `Start`. No interface-based discovery, no tree-walking event scanners. The reference is *not* passed through `Create(...)` factories — it is resolved per-entity at `_Ready` time, when a `GameMode` session is guaranteed to exist.

`GameMode`'s own events (`SessionEnded`, `ScoreChanged`, `LivesChanged`, etc.) are HUD-facing, not entity-facing. HUD subscribes via `_hud.Bind(this)`.

### Marker-Based Entity Spawning

Pickups and blocks that emit events are runtime-spawned from markers, not placed in level scenes directly. Each level scene has a `Markers` node wired to `LevelManager._markerRoot`. `LevelManager.SpawnMarkers` dispatches by C# pattern matching:

```csharp
case CoinMarker m:           AddChild(Coin.Create(m.GlobalPosition));          break;
case QuestionBlockMarker m:  AddChild(QuestionBlock.Create(m.GlobalPosition)); break;
```

One marker class per entity type, each a minimal `Marker2D` subclass (extending `LabeledMarker` for editor visibility). Per-instance config goes on the marker as `[Export]` fields. Each emitter entity has a static `Create(Vector2 pos)` factory that loads its scene from `Config`, instantiates, sets position, and returns. `Coin` is the one exception: it builds its visual programmatically and has no `.tscn`. App-services and `GameEvents` are reached through `GameServices` (`PlaySfx(...)`, `PlayMusic(...)`, `GetGameEvents()`), not through factory parameters.

Entities without event emission (most enemies, decorations) are placed in the level scene at edit time.

### Combat - Defender Decides Reaction

`IStompable`, `IFireballHittable`, `IStarHittable`, `IBumpable`. The attacker invokes the interface; the defender chooses the reaction. These are not event sources; they are direct sibling dispatch.

## Rules

### Allowed Coupling

1. **Vertical ownership.** Parent calls down, child signals up. Components reach their owner via `[Export]`. Never `GetParent()` / `GetNode("../...")`.
2. **App services.** `MusicManager` and `SfxManager` are owned by `GameInstance` and reached through `GameServices` (`PlayMusic(...)`, `PlaySfx(...)`) or `GetGameInstance().Music` / `GetGameInstance().Sfx`. They are not statics — do not add an `Instance` accessor back.
3. **Score/coin events.** Cache `GetGameEvents()` into a `_events` field during `_Ready()` and emit through it. Do not pass `GameEvents` through `Create(...)` factories, and do not re-introduce a static event-bus accessor.
4. **Session service locator access.** Use `GetGameMode()` for runtime projectile/enemy spawn parents and one-up awards. Use `SpawnText(...)` for floating text where injection has not yet reached. Use `PlaySfx(...)` / `PlayMusic(...)` for audio.
5. **Sibling interactions.** Direct calls via combat interfaces.

### Forbidden

- `GetParent()`, `GetNode("../...")`; use `[Export]`.
- Base classes for enemies / pickups / projectiles. Flat per-entity scripts.
- EntityFactory-style enum/string registries; `LevelManager.SpawnMarkers` is the single dispatch point.
- Persistent player across levels; re-spawned per level.
- Re-introducing `IScoreEventSource` / `ICoinEventSource` or tree-walking event scanners.
- Re-adding `MusicManager.Instance` / `SfxManager.Instance` statics. Go through `GameInstance` or `GameServices`.
- New autoloads beyond `GameInstance`.
- Cycles in `.tscn` <-> `.tres` ext_resource references.

### Required Invariants

- The Player body's `CollisionMask` does **not** include `PickupBody`. Mario walks through pickups; triggering happens via `PickupTrigger`.
- `GameMode` is the sole writer to `SaveData`.
- A level scene must have `PlayerStart`, `GoalTrigger`, and `_markerRoot` exports wired; `LevelManager._Ready` throws otherwise.

## Conventions

- `public partial class` for all Godot C# scripts. Gameplay classes and the static service helper use namespace `SMB`.
- `delta` is `double` in `_Process` / `_PhysicsProcess`, not `float`.
- `Vector2` is a struct; assign via `new Vector2(x, Scale.Y)`, not `Scale.X = x`.
- File naming: `PascalCase.cs`, `snake_case.tscn`. Directories: `PascalCase`.
- `StringName` for repeated keys (input actions, signal names).
- Gameplay constants in `Scripts/_Core/Constants.cs`; mirror values from the MonoGame port rather than re-tuning.
- Layer bit positions in `Scripts/_Core/Layers.cs` must stay in sync with the named 2D physics layers in `project.godot`.
- **Required scene wiring should fail loudly.** Prefer typed exports and `PackedScene.Instantiate<T>()` over defensive null checks. Keep checks only for real gameplay/lifecycle state (`_dead`, `_collected`, "is this body the player?", optional resource fields).

### `node_paths` Directive Gotcha

Typed-Node `[Export]` fields require `node_paths=PackedStringArray("Field1", ...)` on the owning node's `[node ...]` line in the `.tscn`. The editor writes this when you wire a field through the inspector. Hand-editing only `Field = NodePath("...")` without the `node_paths=` directive leaves the typed reference **null at runtime**. When in doubt, wire through the inspector.

## Constraints

- `.claude/settings.json` denies file access outside this project directory.
