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
- Score/coin gameplay state is handled by `GameMode` through struct events on `Bus<T>`. Do not reintroduce score/coin service interfaces, marker-based runtime spawning, or no-op/null-object handlers for required gameplay events.

## Architecture

**One autoload: `GameInstance`.** Entry point and app-lifetime service locator. Access it via `GameServices.GetGameInstance()` or the globally imported `GetGameInstance()` helper; it does not expose a static `Instance` property. `boot.tscn` is an empty marker scene; the real flow is in `GameInstance.PostBoot`, which defers one frame after `_Ready`, reads `GetTree().CurrentScene`, and branches:

- **Path is `boot.tscn`** -> `LoadMainMenu()` (normal launch).
- **A `LevelManager` and `OS.HasFeature("editor")`** -> look up the scene's index in `Campaign.tres`, `UnloadCurrentScene()`, `StartGame(index)` (F6 skip-to-level workflow).
- **Anything else** -> sandbox; services available, no session started.

Top-level screens (`MainMenuController`, `GameMode`, `GameOverController`) live under `GameInstance.LevelRoot`. `MusicManager` and `SfxManager` are spawned as `GameInstance` children, not autoloads.

### Service Access

| Accessor | Scope | Set in |
|---|---|---|
| `GetGameInstance()` | App | `GameInstance` autoload |
| `GetGameMode()` | Session | `GameInstance.StartGame` / cleared on game over |
| `GameMode.TextSpawner` | Level/session UI | `GameMode.Start` |

`Scripts/_Core/GameServices.cs` is a static facade globally imported by `Scripts/_Core/GlobalUsings.cs`. It provides `GetGameInstance()`, `GetGameMode()`, and `PlayMusic(...)`. The returned `GameInstance` and `GameMode` objects are normal instances, not static singletons. `MusicManager` and `SfxManager` are not statics either; music is reached through `GameInstance.Music` / `PlayMusic(...)`, while one-shot SFX goes through `Bus<EV_SfxPlay>`.

### Event Bus

`Scripts/_Core/EventBus` contains the static generic event bus. Events are structs implementing `IEvent`, named with the `EV_` prefix, and raised with:

```csharp
Bus<EV_ScoreEarned>.Emit(new EV_ScoreEarned { value = points });
```

Subscribers use `_Ready()` / `_ExitTree()` or session start/exit pairs:

```csharp
Bus<EV_TextSpawn>.Sub(OnTextSpawn);
Bus<EV_TextSpawn>.Unsub(OnTextSpawn);
```

`GameMode` is the sole writer to score, coin, lives, and other `SaveData` state. Pickups and blocks emit events such as `EV_ScoreEarned`, `EV_Pickup_Coin`, `EV_Pickup_Mushroom`, `EV_Pickup_Starman`, and `EV_Pickup_OneUp`; `GameMode` subscribes and applies the state changes.

`GameMode`'s own events (`SessionEnded`, `ScoreChanged`, `LivesChanged`, etc.) are HUD-facing, not entity-facing. HUD subscribes via `_hud.Bind(this)`.

### Level Entity Placement

Pickups, blocks, enemies, and decorations are placed directly in level scenes in the editor. Do not add marker classes or `Create(...)` factories for level entities. `LevelManager` validates only required scene anchors such as `PlayerStart` and `GoalTrigger`; it does not expose marker children or spawn placed gameplay objects.

### Combat - Defender Decides Reaction

`IStompable`, `IFireballHittable`, `IStarHittable`, `IBumpable`. The attacker invokes the interface; the defender chooses the reaction. These are not event sources; they are direct sibling dispatch.

## Rules

### Allowed Coupling

1. **Vertical ownership.** Parent calls down, child signals up. Components reach their owner via `[Export]`. Never `GetParent()` / `GetNode("../...")`.
2. **App services.** `MusicManager` and `SfxManager` are owned by `GameInstance`. Music may use `PlayMusic(...)`; SFX should emit `EV_SfxPlay`. They are not statics; do not add an `Instance` accessor back.
3. **Gameplay events.** Pickups and blocks emit struct events for score, coin, lives, text, and pickup effects. `GameMode`, `TextSpawner`, and `SfxManager` subscribe at their lifecycle boundaries.
4. **Session service locator access.** Use `GetGameMode()` for runtime projectile/enemy spawn parents when a direct owner is required.
5. **Sibling interactions.** Direct calls via combat interfaces.

### Forbidden

- `GetParent()`, `GetNode("../...")`; use `[Export]`.
- Base classes for enemies / pickups / projectiles. Flat per-entity scripts.
- EntityFactory-style enum/string registries and marker-based level entity spawning.
- Persistent player across levels; re-spawned per level.
- Re-introducing score/coin service interfaces, marker classes, or tree-walking event scanners.
- Re-adding `MusicManager.Instance` / `SfxManager.Instance` statics. Go through `GameInstance` or `GameServices`.
- New autoloads beyond `GameInstance`.
- Cycles in `.tscn` <-> `.tres` ext_resource references.

### Required Invariants

- The Player body's `CollisionMask` does **not** include `PickupBody`. Mario walks through pickups; triggering happens via `PickupTrigger`.
- `GameMode` is the sole writer to `SaveData`; gameplay entities request state changes by emitting events.
- A level scene must have `PlayerStart` and `GoalTrigger` exports wired; `LevelManager._Ready` throws otherwise.

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
