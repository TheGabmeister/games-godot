# Port Plan: MonoGame/Nez → Godot 4.6 C#

Port the working MonoGame project at `c:\dev\games-monogame\SuperMario` to this Godot repo, preserving its architecture (scenes-report / GameManager-decides, colocated `Spawn` registry, three combat interfaces, plain-C# `GameState`) rather than the autoload-heavy design currently sketched here.

The existing Godot code (5 autoloads, EventBus, drawer pattern, LevelConfig `.tres`) is **not the target architecture**. Most of it will be deleted. The plan below describes what replaces it.

## What the MonoGame project actually is (reference)

- 3 GlobalManagers (`MusicManager`, `SfxManager`, `GameManager`). Everything else flows from `GameManager`'s scene transitions.
- 3 scenes (`MainMenuScene`, `GameplayScene`, `GameOverScene`). Scenes **fire events**; `GameManager` **decides** the next scene. Scenes never advance themselves.
- `GameState` is a plain C# class (Score, Lives, PowerState) constructed in `GameManager.StartGame`, threaded into the gameplay scene + factory.
- `EntityFactory` is a thin Tiled-Class → `Spawn` registry (~70 lines). Each entity owns `public static void Spawn(Scene, TmxObject [, GameState])` on its own file.
- Combat dispatch via three interfaces: `IFireballHittable`, `IStompable`, `IStarHittable`. Enemy decides what happens to itself; attacker decides what happens to itself.
- Damage paths: `DamagePlayerTrigger` (stomp-aware, calls `TakeDamage`) and `KillVolume` (instant `KillPlayer`).
- Physics layer split: `PickupBody` vs `PickupTrigger` so Mario walks through pickups while still triggering them.

## Nez → Godot mapping

| Nez concept | Godot equivalent |
|---|---|
| `Core.Scene = new XScene()` | `GetTree().ChangeSceneToPacked(...)` into a persistent root, OR instance + `AddChild` into a `SceneRoot` |
| `Scene` subclass with `Initialize` / `OnStart` | `Node2D` script attached to a level `.tscn`, using `_Ready` |
| `Component` on `Entity` | `Node` script attached to a child node |
| `GlobalManager` | Autoload (`*res://...`) |
| `BoxCollider` + `Mover` + `GravityBody` | `CharacterBody2D` + `CollisionShape2D` (or `RigidBody2D` for pickups that need physics) |
| `BoxCollider` with `IsTrigger=true` | `Area2D` + `CollisionShape2D` |
| `PrototypeSpriteRenderer` (colored box) | `ColorRect` or `Polygon2D` child (keep procedural for now) |
| `VirtualButton` / `VirtualIntegerAxis` | `Input.IsActionPressed("jump")` etc. (input map already defined in `project.godot`) |
| `Content.LoadTiledMap(.tmx)` | **Open question** — see below |
| `SoundEffect` / `Song` | `AudioStreamPlayer` (music) / pooled `AudioStreamPlayer` (SFX) |
| Tweens (`Nez.Tweens`) | `Tween` via `CreateTween()` |
| `RenderLayers` | `CanvasLayer` + `z_index` |

## Target Godot architecture

### Autoloads (3, not 5)

Match the MonoGame manager set exactly:

- **GameManager** — owns `GameState`, `_currentLevelIndex`, `_campaign[]`. Drives all scene transitions. Listens to events from the current gameplay scene.
- **MusicManager** — `Play(path)` is a **no-op if same track already playing** (critical: keeps level music continuous across same-level reload on death).
- **SfxManager** — fire-and-forget `Play(path)`.

Delete: `EventBus`, `SceneManager`, `CameraEffects` autoloads. The first two collapse into `GameManager`. CameraEffects can come back later as a non-autoload helper if needed.

### Scenes

Three top-level scene templates (`.tscn`), each with a script:

- `scenes/main_menu.tscn` — emits a "Start" signal which `GameManager` listens for.
- `scenes/gameplay.tscn` — generic gameplay shell. Loaded once per level with a `LevelDefinition` injected. Emits `LevelCompleted` / `PlayerDied`. Spawns entities, HUD, player.
- `scenes/game_over.tscn` — emits `Continue` signal.

`GameManager` connects the signal each time it instantiates a scene, mirroring `scene.LevelCompleted += () => OnLevelCompleted(level)`.

Level data is **not** baked into a per-level `.tscn`. The existing `World11Level.cs` + per-level scene approach is dropped in favor of `Levels.cs`-style `LevelDefinition` records pointing at a `.tmx` map path + music path. One gameplay scene, many levels.

### `GameState`

Plain C# class. **Not an autoload.** Constructed in `GameManager.StartGame()`. Passed into the gameplay scene's `_Ready` (or via an exported setter called before `AddChild`) and into the entity factory. Same `ScoreChanged` / `LivesChanged` events.

### `EntityFactory` + colocated `Spawn`

One `EntityFactory` instance built per gameplay scene load:

```csharp
Register("Goomba", Goomba.Spawn);
Register("QuestionBlock", (s, o) => QuestionBlock.Spawn(s, o, _gameState));
```

Each entity script exposes `public static void Spawn(Node parent, TmxObject obj [, GameState gs])` and adds itself + colliders + visuals as child nodes under `parent`. Same "thin registry, fat Spawn" rule.

### Combat interfaces

Port `IFireballHittable` (returns `FireballReaction`), `IStompable`, `IStarHittable` verbatim. Detection switches from Nez collider-iteration to Godot `Area2D` signals (`area_entered`, `body_entered`), but the dispatch contract is identical.

### Physics layers

Godot supports 32 named layers. Map MonoGame's 8 layers 1:1, preserving the **PickupBody vs PickupTrigger** split so Mario walks through pickups. Document layer names in `project.godot` and mirror them as `const int` in a `Constants.cs`. Layer numbers will differ (Godot is 1-indexed) but names stay.

## Open decisions (discuss before coding)

1. **Level format: keep `.tmx` or switch to Godot `TileMap` + `.tscn`?**
   - Keep TMX: preserves the levels we already have in the MonoGame repo, lets us reuse the `EntityFactory` model as-is. Need a TMX parser (`TiledCS` NuGet, or a small custom loader for the object layer we actually use).
   - Switch to Godot TileMap: idiomatic, editor-integrated, but throws away existing levels and the "object Class → Spawn" registry becomes "PackedScene instance" — different model.
   - **Recommendation: keep `.tmx`**, port the levels by copy, build a minimal Tiled loader. Same architecture both projects.

2. **Visuals: ported sprites or keep procedural shapes?** MonoGame uses `PrototypeSpriteRenderer` (solid colored boxes — also procedural-ish). Easiest is to mirror with `ColorRect` children. Drop the existing `PlayerDrawer` / `_Draw()` pattern unless we want pixel-perfect custom rendering.

3. **Audio asset pipeline.** MonoGame has `Tools/generate_assets.py` → `Assets.cs`. Do we port the generator to Godot's `res://` paths, or hand-maintain a `GodotAssets.cs`? Generator is ~half a day; payoff scales with content churn.

4. **Tiled rotation math.** `EntityFactory.GetCenter` handles rotated objects (top-left → rotated center). Port it identically — `NezGuide.md` warns this is non-obvious.

5. **OGG/WAV asymmetry.** Godot loads OGG fine for both music and SFX (`AudioStreamOggVorbis`), so the WAV-conversion step from MonoGame goes away. We can keep OGG everywhere — simpler.

## Migration phases (rough)

1. **Strip and skeleton.** Delete current autoloads, level scripts, drawer/state-machine files. Add `GameManager` / `MusicManager` / `SfxManager` autoloads as stubs. Build `main_menu.tscn` → `gameplay.tscn` → `game_over.tscn` flow with empty content.
2. **`GameState` + `LevelDefinition` + campaign array.** Plumb through `GameManager.StartGame` → `GameplayScene._Ready`. HUD reads `GameState` events.
3. **Tiled loader + `EntityFactory` skeleton.** Load a `.tmx`, iterate the `entities` object layer, dispatch to no-op `Spawn` functions. Verify positions are correct (rotation math).
4. **Player.** `PlayerController` (CharacterBody2D), input, movement, gravity, power states, fireballs, invuln. No combat interfaces yet — just movement and `TakeDamage` / `KillPlayer` entry points.
5. **Static world.** `Platform`, `BrickBlock`, `QuestionBlock`, `UsedBlock`, `BlockBump`, `MovingPlatform`, `GoalTrigger`, `KillVolume`, `CleanupVolume`.
6. **Pickups.** `Coin`, `Mushroom`, `FireFlower`, `OneUp`, `Starman`. Validates the `PickupBody`/`PickupTrigger` layer split.
7. **Enemies (combat).** `Goomba`, `KoopaTroopa` (green/red), `KoopaParatroopa`, `BuzzyBeetle`, `Spiny`. Implement all three combat interfaces here.
8. **Projectile/ranged enemies.** `PiranhaPlant`, `HammerBro` (+ `Hammer`), `Blooper`, `BulletBillCannon` (+ `BulletBill`), `Podoboo`.
9. **Polish.** SFX wiring, score popups, level-complete animation, death pause, music continuity check on death.

Each phase ends with a `dotnet build` clean + `godot --headless --path . --quit` clean + the game runs through World 1-1.
