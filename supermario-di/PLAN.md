# PLAN.md — Proper Dependency Injection Refactor

## Goal

Replace the current hybrid of service-locator + manual `Create(...)` factories with a single, consistent dependency-injection model. Every entity declares the capabilities it needs as interface dependencies; nothing reaches into a static facade or a global singleton at runtime.

**Out of scope:** changing gameplay behavior, tuning, visuals, or scene structure beyond what each phase explicitly calls out. The refactor is internal. Audio is currently un-wired on most entities; wiring it up is **a side effect of the refactor**, not a separate task.

## Reader Pre-Flight

Before starting, read these files in this order — they are the surfaces you will mutate or replace:

1. [CLAUDE.md](CLAUDE.md) — non-negotiable rules.
2. [Scripts/_Core/GameInstance.cs](Scripts/_Core/GameInstance.cs) — app-scope composition root.
3. [Scripts/_Core/GameMode.cs](Scripts/_Core/GameMode.cs) — session-scope composition root.
4. [Scripts/_Core/GameServices.cs](Scripts/_Core/GameServices.cs) — the locator being deleted.
5. [Scripts/_Core/GlobalUsings.cs](Scripts/_Core/GlobalUsings.cs) — one line that exposes the locator project-wide.
6. [Scripts/Pickups/Mushroom.cs](Scripts/Pickups/Mushroom.cs) — the reference entity for Phase 5.
7. [Scripts/_Core/SfxManager.cs](Scripts/_Core/SfxManager.cs), [Scripts/_Core/MusicManager.cs](Scripts/_Core/MusicManager.cs), [Scripts/UI/TextSpawner.cs](Scripts/UI/TextSpawner.cs) — implementations that will adopt the new interfaces.

Run after every phase: `dotnet build supermario-cs.csproj` then `godot --headless --path . --quit`. Playtest cadence is noted per phase.

## Glossary

- **Capability interface** — A narrow interface (typically one method) that names a single thing an entity is allowed to do to the wider game (`IScoreAwarder.AwardScore`, `ISfxPlayer.PlaySfx`). Lives in [Scripts/Interfaces/](Scripts/Interfaces/).
- **Slice record** — A `readonly record struct` per entity that bundles **only** the capability interfaces that entity uses. Example: `MushroomDependencies(IScoreAwarder, ITextSpawner, ISfxPlayer)`. The record is the entity's complete external surface.
- **Composition root** — The one place in the codebase that decides which concrete object fulfils each capability. There are two: `GameInstance` (app scope) and `GameMode` (session scope).
- **App scope** — Lifetime of `GameInstance` (the autoload). Services: `ISfxPlayer`, `IMusicPlayer`.
- **Session scope** — Lifetime of `GameMode` (one per game session, freed on game over). Services: `IScoreAwarder`, `ICoinCollector`, `IOneUpAwarder`, `ITextSpawner`.
- **Marker-spawned entity** — All gameplay entities. Instantiated at runtime by `GameMode.SpawnLevelObjects` from a marker. Receives dependencies through a `Create(pos, slice)` factory. There is no other entity-construction path.

## Guiding Principles

1. **Construction-time injection only.** Every gameplay entity is constructed by `Create(pos, slice)`. Dependencies arrive in the factory call; never resolved from inside `_Ready` or a signal handler.
2. **One construction path for all gameplay entities.** Pickups, blocks, projectiles, enemies, decorations — everything is marker-spawned at runtime by `GameMode.SpawnLevelObjects`. Level scenes contain only static geometry and markers. No edit-time enemy placements.
3. **Capability interfaces, not god objects.** Each entity sees the narrowest interface that lets it do its job (`IScoreAwarder`, not `GameMode`).
4. **Two well-defined scopes.** App (`GameInstance`) and session (`GameMode`). Level scope is implicit via scene-tree ownership.
5. **No service locator anywhere except the composition root.** `GameServices`, `GetGameInstance()`, `GetGameMode()`, `SpawnText()`, `PlaySfx()`, `PlayMusic()` all go away as call sites. The boot-time `GetGameInstance()` may survive as `internal` for the F6 path only.
6. **Inspector `[Export]` is unchanged.** DI replaces cross-cutting service access, not sibling/child scene wiring. Sound assets are per-entity `[Export] AudioStream` fields, not injected. Per-instance enemy config (Koopa color, facing, patrol bounds) is `[Export]` on the marker.
7. **Respect CLAUDE.md hard rules.** No new autoloads beyond `GameInstance`. No event bus. No static singletons. No EntityFactory enum/string/`Type`-keyed registry — typed per-entity factories + an explicit `switch` in `SpawnLevelObjects`.

## Target Architecture (End State)

```
GameInstance (autoload, app scope)
├── MusicManager   : IMusicPlayer
├── SfxManager     : ISfxPlayer
├── LevelRoot
│   ├── MainMenuController            (when on menu)
│   ├── GameOverController            (when on game over)
│   └── GameMode (session scope)      (when playing)
│       ├── implements IScoreAwarder, ICoinCollector, IOneUpAwarder
│       ├── holds: ISfxPlayer (from GameInstance)
│       ├── holds: IMusicPlayer (from GameInstance)
│       ├── TextSpawner : ITextSpawner    (child node)
│       ├── HUD                            (child node)
│       └── LevelManager                   (static geometry + Markers node only)
│           ├── PlayerController                              (spawned via _playerScene)
│           └── all gameplay entities (pickups, blocks, enemies, projectiles)
│               — constructed by GameMode.SpawnLevelObjects from markers via Create(pos, slice)
```

Every gameplay node receives only what it needs; nothing performs a tree walk or static lookup at runtime.

## Per-Entity Dependency Catalog

This table is the source of truth. Cross-reference it at every phase. Each entity's slice record contains exactly these fields, no more, no less.

| Entity | Spawn path | Slice record | Audio `[Export]` fields |
|---|---|---|---|
| `Coin` | marker | `IScoreAwarder, ICoinCollector, ITextSpawner, ISfxPlayer` | `PickupSound` |
| `Mushroom` | marker | `IScoreAwarder, ITextSpawner, ISfxPlayer` | `PickupSound`, `AppearSound` |
| `FireFlower` | marker | `IScoreAwarder, ITextSpawner, ISfxPlayer` | `PickupSound`, `AppearSound` |
| `Starman` | marker | `IScoreAwarder, ITextSpawner, ISfxPlayer` | `PickupSound`, `AppearSound` |
| `OneUp` | marker (or block drop) | `IOneUpAwarder, ITextSpawner, ISfxPlayer` | `PickupSound` |
| `BrickBlock` | marker | `IScoreAwarder, ISfxPlayer` | `BumpSound`, `BreakSound` |
| `QuestionBlock` | marker | `IScoreAwarder, ICoinCollector, ITextSpawner, ISfxPlayer` | `BumpSound`, `CoinSound` |
| `Fireball` | runtime (player event) | `IScoreAwarder, ISfxPlayer` | `WallHitSound`, `EnemyHitSound` |
| All enemies (`Goomba`, `KoopaTroopa`, `KoopaParatroopa`, `KoopaShell`, `BuzzyBeetle`, `Spiny`, `PiranhaPlant`, `Blooper`, `Podoboo`, `HammerBro`, `BulletBill`, `BulletBillCannon`) | marker | `EnemyDependencies(IScoreAwarder, ITextSpawner, ISfxPlayer)` | `StompSound`, `DeathSound` (per-entity, see Phase 8) |

`MusicManager` / `IMusicPlayer` is never injected into entities — only `GameMode` uses it, internally.

## Phases

Each phase is independently buildable. Commit after every phase. Manual playtest cadence is called out.

---

### Phase 1 — Add capability interfaces (build-only)

Create the following files under [Scripts/Interfaces/](Scripts/Interfaces/). Each file contains exactly one interface in the `SMB` namespace.

```csharp
// IOneUpAwarder.cs
public interface IOneUpAwarder { void AwardOneUp(); }

// ISfxPlayer.cs
public interface ISfxPlayer { void PlaySfx(AudioStream stream); }

// IMusicPlayer.cs
public interface IMusicPlayer { void PlayMusic(AudioStream stream); }

// ITextSpawner.cs
public interface ITextSpawner { void SpawnText(string text, Vector2 worldPosition); }
```

`IScoreAwarder` and `ICoinCollector` already exist.

**Validation:** `dotnet build` succeeds. Nothing consumes the new interfaces yet.

**Commit message:** `Add capability interfaces for DI refactor`

---

### Phase 2 — Wire implementations to the new interfaces (build-only)

Make existing implementations satisfy the interfaces. **Do not change any call site yet.**

1. [Scripts/_Core/SfxManager.cs](Scripts/_Core/SfxManager.cs)
   - Change class declaration to `public partial class SfxManager : Node, ISfxPlayer`.
   - Rename `public void Play(AudioStream stream)` → `public void PlaySfx(AudioStream stream)`. Update the **one** internal caller in [Scripts/_Core/GameServices.cs](Scripts/_Core/GameServices.cs) (the line `GetGameInstance().Sfx.Play(sound)`) to call `PlaySfx`. This keeps `GameServices` working temporarily.

2. [Scripts/_Core/MusicManager.cs](Scripts/_Core/MusicManager.cs)
   - Change class declaration to `public partial class MusicManager : Node, IMusicPlayer`.
   - Rename its `Play(AudioStream)` → `PlayMusic(AudioStream)`. Update the one caller in `GameServices`.

3. [Scripts/UI/TextSpawner.cs](Scripts/UI/TextSpawner.cs)
   - Change class declaration to `public partial class TextSpawner : Node2D, ITextSpawner`.
   - Existing `SpawnText(string, Vector2)` signature already matches the interface — no rename needed.

4. [Scripts/_Core/GameMode.cs](Scripts/_Core/GameMode.cs)
   - Add interfaces to the declaration: `public partial class GameMode : Node, IScoreAwarder, ICoinCollector, IOneUpAwarder`.
   - Add `public void AwardOneUp() => EmitOneUpAwarded();` (or rename `EmitOneUpAwarded` to `AwardOneUp` and remove the wrapper). The existing event-emit body remains unchanged.

**Validation:** `dotnet build` succeeds. Run the game; everything plays as before (the old locator paths still work because they call through the renamed methods).

**Commit message:** `Implement capability interfaces on existing service classes`

---

### Phase 3 — Composition root: pass `ISfxPlayer` and `IMusicPlayer` into `GameMode`

Until now `GameMode` reaches its audio via the static locator. Cut that cord.

1. [Scripts/_Core/GameMode.cs](Scripts/_Core/GameMode.cs)
   - Add private fields:
     ```csharp
     private ISfxPlayer _sfx;
     private IMusicPlayer _music;
     private ITextSpawner _textSpawner;
     ```
   - Add a public `Init` method called by `GameInstance` **before** `AddChild`:
     ```csharp
     public void Init(ISfxPlayer sfx, IMusicPlayer music)
     {
         _sfx = sfx;
         _music = music;
     }
     ```
   - In `Start(int)`, after the `TextSpawner` is instantiated, hold it as the interface:
     ```csharp
     TextSpawner = new TextSpawner { Name = "TextSpawner" };
     AddChild(TextSpawner);
     _textSpawner = TextSpawner;
     ```
   - Replace the existing `LoadCurrentLevel` line `if (def.MusicTrack != null) PlayMusic(def.MusicTrack);` with `if (def.MusicTrack != null) _music.PlayMusic(def.MusicTrack);`.

2. [Scripts/GameInstance.cs](Scripts/GameInstance.cs)
   - In `StartGame`, after `_session = new GameMode { Name = "GameMode" };` and before `SetActiveNode(_session)`:
     ```csharp
     _session.Init(Sfx, Music);
     ```
   - `Sfx` and `Music` are already typed as the concrete `SfxManager` / `MusicManager`. They satisfy `ISfxPlayer` / `IMusicPlayer` after Phase 2.

**Validation:** Build + playtest the menu → start game → first level. Music plays, no crash.

**Commit message:** `Inject audio services into GameMode via Init`

---

### Phase 4 — Define slice records (build-only)

Create one file per entity under [Scripts/Pickups/](Scripts/Pickups/), [Scripts/Level/](Scripts/Level/), [Scripts/Projectiles/](Scripts/Projectiles/), [Scripts/Enemies/](Scripts/Enemies/) — co-located with the entity. Use `readonly record struct` so they're stack-allocated and zero-allocation at the spawn site.

```csharp
// Scripts/Pickups/MushroomDependencies.cs
namespace SMB;
public readonly record struct MushroomDependencies(
    IScoreAwarder ScoreAwarder,
    ITextSpawner TextSpawner,
    ISfxPlayer SfxPlayer);
```

Create the following nine slice records, matching the catalog table above:

- `CoinDependencies`
- `MushroomDependencies`
- `FireFlowerDependencies`
- `StarmanDependencies`
- `OneUpDependencies`
- `BrickBlockDependencies`
- `QuestionBlockDependencies`
- `FireballDependencies`
- `EnemyDependencies` (in [Scripts/Enemies/](Scripts/Enemies/), shared by all enemies)

**Validation:** `dotnet build` succeeds. Nothing consumes them yet.

**Commit message:** `Define slice records for DI refactor`

---

### Phase 5 — Reference migration: `Mushroom` end-to-end

This is the template. Get it right; the rest are copies of this diff.

1. [Scripts/Pickups/Mushroom.cs](Scripts/Pickups/Mushroom.cs) — full file becomes:

```csharp
using Godot;

namespace SMB;

public partial class Mushroom : CharacterBody2D
{
    [Export] public Area2D PickupTrigger;
    [Export] public AudioStream PickupSound;

    private MushroomDependencies _deps;
    private bool _collected;

    public static Mushroom Create(Vector2 globalPosition, MushroomDependencies deps)
    {
        var scene = GD.Load<PackedScene>(Config.MushroomScenePath);
        var m = scene.Instantiate<Mushroom>();
        m.GlobalPosition = globalPosition;
        m._deps = deps;
        return m;
    }

    public override void _Ready()
    {
        PickupTrigger.BodyEntered += OnPickedUp;
    }

    private void OnPickedUp(Node2D body)
    {
        if (_collected || body is not PlayerController player) return;
        _collected = true;

        _deps.SfxPlayer.PlaySfx(PickupSound);
        _deps.ScoreAwarder.AwardScore(Constants.MushroomScore);
        _deps.TextSpawner.SpawnText(Constants.MushroomScore.ToString(), GlobalPosition);
        player.ApplyMushroom();
        QueueFree();
    }
}
```

Notes:
- The `[Export] AudioStream PickupSound` is **new** — wire it in the scene file in step 3.
- No `using static SMB.GameServices` line. The migrated entity has no global helpers in scope (you may leave the global-using directive in `GlobalUsings.cs` for now; Phase 11 removes it).
- Internal calls are `_deps.X.Method(...)` consistently.

2. [Scripts/_Core/GameMode.cs](Scripts/_Core/GameMode.cs), inside `SpawnLevelObjects`, update the `MushroomMarker` case:

```csharp
case MushroomMarker m:
    level.AddChild(Mushroom.Create(
        m.GlobalPosition,
        new MushroomDependencies(this, _textSpawner, _sfx)));
    break;
```

3. [Scenes/Pickups/mushroom.tscn](Scenes/Pickups/mushroom.tscn) (or wherever the scene lives — locate via `Config.MushroomScenePath`):
   - Open in the Godot editor. **Do not hand-edit the `.tscn`.**
   - With the root Mushroom node selected, the inspector now shows a `Pickup Sound` slot. Drag the existing powerup `.wav` resource into it.
   - Save the scene.
   - Confirm the `.tscn` now contains a `PickupSound = ExtResource(...)` line under the root node and that the root's `[node ...]` line includes the field in its `node_paths=` directive (or for `Resource`-typed exports, the inspector writes the `PickupSound = ...` line directly — no `node_paths` needed for `AudioStream`).

**Validation:**
- Build.
- Playtest 1-1. Walk into a mushroom. Expected: powerup sound plays, "1000" floats up, score increases by 1000, Mario grows.
- If any of those four behaviors broke, stop and fix before moving on. This is the gate that proves the pattern works.

**Commit message:** `Migrate Mushroom to slice-record DI (reference impl)`

---

### Phase 6 — Migrate remaining marker-spawned entities

Apply the Phase 5 template to each of the following. For each: update the entity's `Create(...)` signature to take the slice record; add `[Export] AudioStream` fields per the catalog; replace any locator calls (`SpawnText`, `PlaySfx`, `GetGameMode()`) with `_deps.X` calls; update the corresponding `case` in `GameMode.SpawnLevelObjects` to construct the slice record.

Migrate in this order (each is independently playtestable):

1. **`Coin`** — currently uses `SpawnText(...)`. Adds `ITextSpawner` and `ISfxPlayer`. Already takes `IScoreAwarder` + `ICoinCollector`.
2. **`BrickBlock`** — currently takes `IScoreAwarder` only. Adds `ISfxPlayer`. Bump/break sounds wire to the existing `Bumpable` component path and to the score-aware break path.
3. **`QuestionBlock`** — currently takes score+coin. Adds `ITextSpawner` (if it spawns text on coin payout) and `ISfxPlayer`. **Note:** if `QuestionBlock` spawns a `Mushroom` or `FireFlower` when bumped, it must also be able to construct **their** slice records. Easiest path: `QuestionBlock` receives the larger `QuestionBlockDependencies` whose composition lets it build the child slice records (see Phase 6.1 below). Alternatively: emit a `RequestSpawn(MarkerType, position)` event upward and let `GameMode` handle it. **Recommended:** the event-upward approach, because it keeps the slice record narrow and avoids one entity knowing how to construct another's dependencies.
4. **`Starman`** — adds the three audio + text + score deps.
5. **`FireFlower`** — same as `Starman`.
6. **`OneUp`** — replaces `GetGameMode().EmitOneUpAwarded()` with `_deps.OneUpAwarder.AwardOneUp()`. Adds `ITextSpawner` + `ISfxPlayer`.

**Phase 6.1 — Question/Brick block payouts (do this if step 3 above hit the spawn-child problem)**

Add a `BlockSpawnRequested` event on each block:

```csharp
public event Action<MarkerKind, Vector2> BlockSpawnRequested;
```

Where `MarkerKind` is a small enum (`Coin`, `Mushroom`, `FireFlower`, `Starman`, `OneUp`). `GameMode` subscribes when it spawns the block:

```csharp
case QuestionBlockMarker m:
    var qb = QuestionBlock.Create(m.GlobalPosition,
        new QuestionBlockDependencies(this, this, _textSpawner, _sfx),
        m.Contents);  // QuestionBlockMarker already exports what's inside
    qb.BlockSpawnRequested += OnBlockSpawnRequested;
    level.AddChild(qb);
    break;

private void OnBlockSpawnRequested(MarkerKind kind, Vector2 pos)
{
    Node spawned = kind switch
    {
        MarkerKind.Coin       => Coin.Create(pos, new CoinDependencies(this, this, _textSpawner, _sfx)),
        MarkerKind.Mushroom   => Mushroom.Create(pos, new MushroomDependencies(this, _textSpawner, _sfx)),
        MarkerKind.FireFlower => FireFlower.Create(pos, new FireFlowerDependencies(this, _textSpawner, _sfx)),
        MarkerKind.Starman    => Starman.Create(pos, new StarmanDependencies(this, _textSpawner, _sfx)),
        MarkerKind.OneUp      => OneUp.Create(pos, new OneUpDependencies(this, _textSpawner, _sfx)),
    };
    CurrentLevel.AddChild(spawned);
}
```

**Yes, `MarkerKind` is an enum. This is the one place a small enum is justified.** It's not a registry — it's a payload on a vertical event from block to parent. The dispatch is still an explicit `switch` in `GameMode`, not a runtime registry.

**Validation per sub-step:**
- After **Coin**: walk into coins → coin sound + "200" + score + coin counter increment.
- After **BrickBlock**: bump a brick as big Mario → bump sound + break + score; bump as small Mario → bump sound only.
- After **QuestionBlock**: bump a coin block → coin sound + "200" + score + coin counter. Bump a mushroom block → mushroom appears with sound. (Test only after Phase 6.1 if applicable.)
- After **Starman**, **FireFlower**, **OneUp**: their pickup behaviors with sound.

**Commit message (one per entity):** `Migrate <Entity> to slice-record DI`

---

### Phase 7 — Dispatch refactor: extract per-entity helpers

After Phase 6, every case in `SpawnLevelObjects` is a multi-line slice-record construction. Collapse the noise.

[Scripts/_Core/GameMode.cs](Scripts/_Core/GameMode.cs), `SpawnLevelObjects` becomes:

```csharp
private void SpawnLevelObjects(LevelManager level)
{
    foreach (var marker in level.Markers)
    {
        Node spawned = marker switch
        {
            CoinMarker m          => SpawnCoin(m),
            QuestionBlockMarker m => SpawnQuestionBlock(m),
            BrickBlockMarker m    => SpawnBrickBlock(m),
            MushroomMarker m      => SpawnMushroom(m),
            StarmanMarker m       => SpawnStarman(m),
            FireFlowerMarker m    => SpawnFireFlower(m),
            _ => throw new InvalidOperationException(
                     $"Unhandled marker type {marker.GetType().Name}")
        };
        level.AddChild(spawned);
    }
}

private Coin SpawnCoin(CoinMarker m) =>
    Coin.Create(m.GlobalPosition,
        new CoinDependencies(this, this, _textSpawner, _sfx));

private Mushroom SpawnMushroom(MushroomMarker m) =>
    Mushroom.Create(m.GlobalPosition,
        new MushroomDependencies(this, _textSpawner, _sfx));

// ...one expression-bodied helper per marker type.
```

Notes:
- The default `_` arm **throws**, not returns null. A forgotten case is a loud error, not a silent skip.
- If `QuestionBlock` returns a node with a subscription side-effect (per 6.1), the helper handles the subscription:
  ```csharp
  private QuestionBlock SpawnQuestionBlock(QuestionBlockMarker m)
  {
      var qb = QuestionBlock.Create(m.GlobalPosition,
          new QuestionBlockDependencies(this, this, _textSpawner, _sfx),
          m.Contents);
      qb.BlockSpawnRequested += OnBlockSpawnRequested;
      return qb;
  }
  ```

**Validation:** Playtest a full level. All marker-spawned entities behave as in Phase 6.

**Commit message:** `Extract per-entity dispatch helpers in SpawnLevelObjects`

---

### Phase 8 — Convert enemies to marker-spawning

Today, enemies are placed directly inside level `.tscn` files. After this phase, **every enemy is marker-spawned** like pickups and blocks — one uniform construction path across the codebase. Per-instance enemy config (Koopa color, facing direction, patrol bounds) moves from the enemy's own scene to `[Export]` fields on its marker.

This is the largest mechanical phase. It is also the most boring — each enemy follows the same template.

#### 8.1 — Create one marker class per enemy type

Under [Scripts/Markers/](Scripts/Markers/), create one file per enemy. Each marker is a minimal `LabeledMarker` subclass with the per-instance config it needs.

```csharp
// Scripts/Markers/GoombaMarker.cs
namespace SMB;
public partial class GoombaMarker : LabeledMarker { }

// Scripts/Markers/KoopaTroopaMarker.cs
namespace SMB;
public partial class KoopaTroopaMarker : LabeledMarker
{
    [Export] public KoopaColor Color = KoopaColor.Green;
}

// Scripts/Markers/BulletBillCannonMarker.cs
namespace SMB;
public partial class BulletBillCannonMarker : LabeledMarker
{
    [Export] public int Facing = -1;          // -1 left, 1 right
    [Export] public float FireInterval = 2.5f;
}

// ...one per enemy.
```

For each enemy, decide which fields are per-instance config and add them as `[Export]` on the marker. The rule: anything that varies between instances of the same enemy type lives on the marker; anything that is shared by every instance (textures, sounds, base speed) stays on the enemy's own scene.

Required markers (one each): `GoombaMarker`, `KoopaTroopaMarker`, `KoopaParatroopaMarker`, `BuzzyBeetleMarker`, `SpinyMarker`, `PiranhaPlantMarker`, `BlooperMarker`, `PodobooMarker`, `HammerBroMarker`, `BulletBillCannonMarker`. (`KoopaShell` is not authored in levels — it's spawned when a Koopa is stomped. No marker.) (`BulletBill` is not authored in levels — it's spawned by `BulletBillCannon`. No marker.)

#### 8.2 — Add a `Create(...)` factory to each enemy

For each enemy, replicate the Phase 5 / Phase 6 pattern. Worked example — [Scripts/Enemies/Goomba.cs](Scripts/Enemies/Goomba.cs):

```csharp
using Godot;

namespace SMB;

public partial class Goomba : CharacterBody2D, IStompable, IFireballHittable, IStarHittable
{
    [Export] public AudioStream StompSound;
    [Export] public AudioStream DeathSound;

    private EnemyDependencies _deps;

    public static Goomba Create(Vector2 globalPosition, EnemyDependencies deps)
    {
        var scene = GD.Load<PackedScene>(Config.GoombaScenePath);
        var g = scene.Instantiate<Goomba>();
        g.GlobalPosition = globalPosition;
        g._deps = deps;
        return g;
    }

    public void OnStomped(PlayerController _)
    {
        _deps.SfxPlayer.PlaySfx(StompSound);
        _deps.ScoreAwarder.AwardScore(Constants.GoombaStompScore);
        _deps.TextSpawner.SpawnText(Constants.GoombaStompScore.ToString(), GlobalPosition);
        QueueFree();
    }

    public FireballReaction OnHitByFireball()
    {
        _deps.SfxPlayer.PlaySfx(DeathSound);
        _deps.ScoreAwarder.AwardScore(Constants.GoombaFireballScore);
        _deps.TextSpawner.SpawnText(Constants.GoombaFireballScore.ToString(), GlobalPosition);
        QueueFree();
        return FireballReaction.Defeated;
    }

    public void OnHitByStar(PlayerController _)
    {
        _deps.SfxPlayer.PlaySfx(DeathSound);
        _deps.ScoreAwarder.AwardScore(Constants.GoombaStarScore);
        _deps.TextSpawner.SpawnText(Constants.GoombaStarScore.ToString(), GlobalPosition);
        QueueFree();
    }
}
```

For enemies with marker-driven config, `Create` takes additional parameters:

```csharp
public static KoopaTroopa Create(Vector2 globalPosition, KoopaColor color, EnemyDependencies deps)
{
    var scene = GD.Load<PackedScene>(Config.KoopaTroopaScenePath);
    var k = scene.Instantiate<KoopaTroopa>();
    k.GlobalPosition = globalPosition;
    k.SetColor(color);          // mutates the existing color export on the instance
    k._deps = deps;
    return k;
}
```

Add a scene path entry to [Scripts/_Core/Config.cs](Scripts/_Core/Config.cs) for every enemy scene that doesn't already have one.

Apply the template to every enemy class listed in the catalog.

#### 8.3 — Add dispatch cases for enemy markers

Extend the helper-based switch from Phase 7:

```csharp
private void SpawnLevelObjects(LevelManager level)
{
    foreach (var marker in level.Markers)
    {
        Node spawned = marker switch
        {
            // pickups + blocks (Phase 7)
            CoinMarker m              => SpawnCoin(m),
            QuestionBlockMarker m     => SpawnQuestionBlock(m),
            BrickBlockMarker m        => SpawnBrickBlock(m),
            MushroomMarker m          => SpawnMushroom(m),
            StarmanMarker m           => SpawnStarman(m),
            FireFlowerMarker m        => SpawnFireFlower(m),

            // enemies (Phase 8)
            GoombaMarker m            => SpawnGoomba(m),
            KoopaTroopaMarker m       => SpawnKoopaTroopa(m),
            KoopaParatroopaMarker m   => SpawnKoopaParatroopa(m),
            BuzzyBeetleMarker m       => SpawnBuzzyBeetle(m),
            SpinyMarker m             => SpawnSpiny(m),
            PiranhaPlantMarker m      => SpawnPiranhaPlant(m),
            BlooperMarker m           => SpawnBlooper(m),
            PodobooMarker m           => SpawnPodoboo(m),
            HammerBroMarker m         => SpawnHammerBro(m),
            BulletBillCannonMarker m  => SpawnBulletBillCannon(m),

            _ => throw new InvalidOperationException(
                     $"Unhandled marker type {marker.GetType().Name}")
        };
        level.AddChild(spawned);
    }
}

private Goomba SpawnGoomba(GoombaMarker m) =>
    Goomba.Create(m.GlobalPosition,
        new EnemyDependencies(this, _textSpawner, _sfx));

private KoopaTroopa SpawnKoopaTroopa(KoopaTroopaMarker m) =>
    KoopaTroopa.Create(m.GlobalPosition, m.Color,
        new EnemyDependencies(this, _textSpawner, _sfx));

// ...one helper per enemy marker type.
```

The helper for each marker pulls the marker's `[Export]` config and threads it into `Create(...)`.

#### 8.4 — Re-author level scenes

For every level `.tscn` under `Levels/` (or wherever level scenes live):

1. Open the level in the Godot editor.
2. For each enemy instance currently placed in the scene:
   - Note its position and any per-instance config (Koopa color, facing).
   - Delete the enemy node.
   - Under the level's `Markers` node, add an instance of the matching marker scene at the same position with the same config.
3. Save the level scene.

**Do this one level at a time and playtest after each.** A subtle position drift or missing config field is easy to miss in a bulk edit.

#### 8.5 — Audio wiring for enemy scenes

For each enemy scene (`goomba.tscn`, `koopa_troopa.tscn`, etc.), open in the editor and wire the new `[Export] AudioStream` slots to the appropriate `.wav` resources. Save through the editor; do not hand-edit.

**Validation per enemy (run during 8.4):** Playtest. Stomp / shoot fireball at / hit with star → correct sound, correct score popup, correct score increment, correct removal.

**Commit message (one per enemy):** `Marker-spawn <Enemy> with EnemyDependencies + sound`

---

### Phase 9 — `Fireball` and the projectile path

Fireball is spawned by `GameMode` in response to `PlayerController.FireballRequested`. Keep that event. The event payload doesn't change.

1. [Scripts/Projectiles/Fireball.cs](Scripts/Projectiles/Fireball.cs)
   - Add `[Export] public AudioStream WallHitSound; [Export] public AudioStream EnemyHitSound;`
   - Add private `FireballDependencies _deps`.
   - Extend `Init` to also take the slice record:
     ```csharp
     public void Init(Vector2 position, int facing, PlayerController owner, FireballDependencies deps)
     {
         GlobalPosition = position;
         _facing = facing;
         _owner = owner;
         _deps = deps;
         _velocity = new Vector2(_facing * Constants.FireballSpeed, 0f);
     }
     ```
   - In `Destroy(bool playHitSfx)`, play the appropriate sound when `playHitSfx == true`. Use `_deps.SfxPlayer.PlaySfx(WallHitSound)` for wall hits.
   - Where the fireball's hit defeats an enemy, the **enemy** plays its own `DeathSound` (already handled in Phase 8). The fireball plays `EnemyHitSound` from its own export if you want a layered SFX, otherwise leave that field empty and skip the call.

2. [Scripts/_Core/GameMode.cs](Scripts/_Core/GameMode.cs), `OnFireballRequested`:

```csharp
private void OnFireballRequested(Vector2 position, int facing, PlayerController owner)
{
    var fireball = _fireballScene.Instantiate<Fireball>();
    fireball.Init(position, facing, owner,
        new FireballDependencies(this, _sfx));
    CurrentLevel.AddChild(fireball);
}
```

3. Open [Scenes/Projectiles/fireball.tscn](Scenes/Projectiles/fireball.tscn) in the editor and wire `WallHitSound` / `EnemyHitSound`.

**Validation:** Grab fire flower, shoot fireballs at walls (wall sound), shoot fireballs at enemies (enemy death sound from enemy, plus optional fireball impact sound).

**Commit message:** `Wire Fireball through FireballDependencies`

---

### Phase 10 — Delete the service locator

By this point, no production code outside `GameInstance` / `GameMode` references `GameServices`. Confirm with a grep before deleting.

1. Grep checks (run these and expect zero hits in `Scripts/` outside `_Core/GameInstance.cs` and `_Core/GameMode.cs`):
   - `GetGameMode\(\)`
   - `GetGameInstance\(\)`
   - `\bSpawnText\(` (the static, not `_deps.TextSpawner.SpawnText`)
   - `\bPlaySfx\(` outside of an `_deps.SfxPlayer.PlaySfx` context
   - `\bPlayMusic\(` outside of an `_music.PlayMusic` context

2. [Scripts/_Core/GameServices.cs](Scripts/_Core/GameServices.cs)
   - Delete `GetGameMode()`, `SpawnText(...)`, `PlaySfx(...)`, `PlayMusic(...)`.
   - Keep `GetGameInstance()` but change it from `public` to `internal`. Add a comment naming the **single** legitimate caller: `GameInstance.PostBoot`'s F6 path. (Per CLAUDE.md, comments only when the why is non-obvious — this qualifies.)

3. [Scripts/_Core/GlobalUsings.cs](Scripts/_Core/GlobalUsings.cs)
   - Delete `global using static SMB.GameServices;`. The file may end up empty — if so, delete it and remove from `.csproj` includes if it's explicitly listed.

**Validation:** Build. The compiler **will fail** if anything was missed; that is the safety net. Fix each fail by adding the missing dependency to the appropriate slice record (rare at this point — Phases 5–9 should have caught everything). Playtest a full level afterward.

**Commit message:** `Delete GameServices locator`

---

### Phase 11 — Update CLAUDE.md

[CLAUDE.md](CLAUDE.md) needs several edits to reflect the new architecture. Apply all of these:

1. **Remove the `GameServices` table row** in "Service Access" and the paragraph naming `GetGameMode()` / `SpawnText(...)` / `PlaySfx(...)` / `PlayMusic(...)` as project-wide helpers. The "Session service locator access" bullet under "Allowed Coupling" goes away entirely.

2. **Remove the edit-time placement carve-out.** The sentence "Entities without event emission (most enemies, decorations) are placed in the level scene at edit time." under "Marker-Based Entity Spawning" is deleted. Replace with: "Every gameplay entity — pickups, blocks, enemies, decorations — is runtime-spawned by `GameMode.SpawnLevelObjects` from a marker. Level scenes contain only static geometry and the `Markers` node."

3. **Add a "Capability interfaces" subsection** listing every interface in [Scripts/Interfaces/](Scripts/Interfaces/) and which class implements it:
   - `IScoreAwarder`, `ICoinCollector`, `IOneUpAwarder` — implemented by `GameMode`
   - `ITextSpawner` — implemented by `TextSpawner`
   - `ISfxPlayer` — implemented by `SfxManager`
   - `IMusicPlayer` — implemented by `MusicManager`
   - `IStompable`, `IFireballHittable`, `IStarHittable`, `IBumpable` — combat interfaces, implemented by enemies/blocks (unchanged from today)

4. **Add a "Slice records" subsection** naming the convention: one `readonly record struct <Entity>Dependencies` per entity (or shared for enemies). Lives alongside the entity. The record is the entity's complete external surface.

5. **Update "Forbidden"** by:
   - Adding: "Re-introducing `GameServices` or any equivalent static facade for runtime gameplay code."
   - Adding: "Adding a global-using directive that exposes static gameplay helpers project-wide."
   - Adding: "Placing gameplay entities directly in level `.tscn` files. Every gameplay entity is marker-spawned."
   - The existing "Re-introducing GameEvents..." entry can drop the "tree-walking event scanners" clause if you want — there is no longer any tree walking anywhere in the codebase, so the phrasing is moot. Either keep it for emphasis or trim.

6. **Update "Required Invariants"** by adding: "Every entity receives its dependencies via `Create(pos, slice)` before `_Ready` runs. Never resolve dependencies from inside `_Ready` or a signal handler."

7. **Remove** the existing "Score And Coin Interfaces" paragraph beginning "Dependencies are assigned inside `Create(...)`; do not expose separate public `Initialize(...)` methods..." and replace with the broader rule above. The `Initialize(...)` prohibition is now redundant because there is exactly one construction path.

**Validation:** None — documentation change.

**Commit message:** `Update CLAUDE.md for unified DI architecture`

---

## Pitfalls & Gotchas

1. **`node_paths=` directive gotcha (already in CLAUDE.md).** Typed `[Export]` `Node` fields require the `node_paths=PackedStringArray("...")` directive on the owning `[node ...]` line. **`AudioStream` exports are `Resource` exports, not `Node` exports — they do not need the directive.** Wire through the inspector regardless.
2. **`SfxManager.Play` rename in Phase 2.** The static `GameServices.PlaySfx` still calls `Sfx.Play(sound)` before the rename. After renaming `SfxManager.Play` → `SfxManager.PlaySfx`, update the call in `GameServices.PlaySfx` in the same commit or the build breaks.
3. **`QuestionBlock` payload contents.** Phase 6.1's `MarkerKind` enum is the **only** acceptable use of an enum-style dispatch in this codebase. Do not be tempted to generalize it into a runtime registry.
4. **Most enemies have zero dependencies today.** Phase 8 adds them. The slice record `EnemyDependencies` is wider than what `Goomba` strictly needs — it's shared across all enemies so that ~12 enemy types don't each get their own near-identical record. This is a deliberate exception to "narrowest slice per entity": the cost of one shared enemy record is much lower than maintaining 12 nearly-identical ones.
5. **Slice records as `readonly record struct`.** Use `readonly record struct`, not `record class`. They are passed by value, no GC allocation, and immutable. If you change them to classes, you create allocations on every spawn.
6. **Editor F6 workflow still uses `GetGameInstance()`.** Phase 10 keeps this one locator call alive (as `internal`). Do not delete it.
7. **Lifetime: events crossing scope.** A pickup that subscribes to `GameMode.SessionEnded` must unsubscribe in `_ExitTree`. Today this isn't an issue because pickups don't subscribe; if you add such subscriptions during the refactor, audit them.
8. **Level scene re-authoring (Phase 8.4) is where regressions hide.** Positional drift, missing per-instance config (forgot to set Koopa color on the new marker), or dropping in the wrong marker type are easy mistakes. Playtest after every level edit, not after the whole batch.
9. **Per-enemy `[Export]` config that varies between instances goes on the marker, not the enemy scene.** Examples: `KoopaTroopa.Color`, `BulletBillCannon.Facing`, `HammerBro.ThrowInterval`. Examples of what stays on the enemy scene: textures, base movement speed, animation timings, collision shapes — anything shared by every instance of that enemy type.

## Validation Checklist (Final)

Run after Phase 11. All boxes must check.

- [ ] `dotnet build supermario-cs.csproj` — clean build.
- [ ] `godot --headless --path . --quit` — exits cleanly.
- [ ] Boot → main menu → start game → level 1 loads, music plays.
- [ ] Walk into a coin → coin sound + score popup + score increase + coin counter increase.
- [ ] Walk into a mushroom → mushroom sound + score popup + score increase + Mario grows.
- [ ] Bump a brick as small Mario → bump sound, brick intact.
- [ ] Bump a brick as big Mario → break sound + score popup + score increase + brick destroyed.
- [ ] Bump a question block → coin sound + score popup + score increase + block used.
- [ ] Bump a question block containing a power-up → block sound + power-up emerges with its appear sound.
- [ ] Walk into a fire flower as big Mario → power-up sound + Mario becomes fire Mario.
- [ ] Walk into a starman → starman sound + invincibility.
- [ ] Walk into a 1-Up → 1-up sound + lives counter increases.
- [ ] Stomp a Goomba → stomp sound + score popup + score increase + Goomba removed.
- [ ] Shoot fireball at Goomba → wall sound (if hit wall) or fireball impact + Goomba death sound + score popup + score increase.
- [ ] Stomp a Koopa → koopa shell sound + shell appears.
- [ ] All other enemies: visual disappearance and correct score behavior on stomp / fireball / star.
- [ ] Death → death sound + life lost + level reloads (or game over).
- [ ] Time runs out → kill player path triggers correctly.
- [ ] Reach goal → level completes, next level loads or game over fires.
- [ ] Grep: zero hits for `GetGameMode\(\)`, `GameServices\.`, or static `SpawnText\(\b` outside `GameInstance` / `GameMode`.

## Rough Effort Estimate

- Phase 1–4 (interfaces, impls, composition root, slice records — all build-only): half a day.
- Phase 5 (Mushroom reference): 1–2 hours including the first careful playtest.
- Phase 6 (six entities + QuestionBlock payouts): 1 day.
- Phase 7 (dispatch refactor): 1 hour.
- Phase 8 (~10 enemy markers + `Create` factories + level re-authoring + audio wiring): 1.5–2 days, dominated by level re-authoring. This is now the biggest phase.
- Phase 9 (Fireball): 1–2 hours.
- Phase 10 (delete locator): 30 minutes; should be a no-op if the prior phases were clean.
- Phase 11 (CLAUDE.md): 30 minutes.

**Total: 4–5 focused days**, reversible per phase.

## Decision Points (Locked)

These were settled before this plan was written. Do not re-litigate them mid-implementation:

1. **Slice records, not a single `SessionContext`.** Each entity's slice is its public contract.
2. **Hand-written composition root, no DI container.** No `Microsoft.Extensions.DependencyInjection`.
3. **`GameInstance` remains the one autoload.**
4. **Migration order is by entity (one entity at a time, fully migrated)**, not by capability (all `ITextSpawner` first, then all `ISfxPlayer`).
5. **`MarkerKind` enum is allowed in Phase 6.1 only**, as a payload on a block-to-parent event. Not a general pattern.
6. **`EnemyDependencies` is shared across all enemies**; per-enemy slice records would be over-engineering.
7. **Every gameplay entity is marker-spawned.** No edit-time placement of enemies, decorations, or anything that needs dependencies. Level scenes contain static geometry and markers only. This is the central architectural shift; CLAUDE.md is being updated in Phase 11 to enforce it.
