# PLAN.md — Data-Oriented Rewrite

A from-the-ground-up recreation of the Super Mario Bros clone using **struct
entities + systems (managers)** as the simulation source of truth, with Godot
demoted to a view / audio / UI layer.

> **Status:** design proposal. This plan *supersedes* large parts of the
> current `CLAUDE.md`. See [Relationship to current CLAUDE.md](#relationship-to-current-claudemd)
> for the exact rules that change. If adopted, `CLAUDE.md` must be rewritten in
> the same change set.

---

## 1. Decisions locked

| Decision | Choice | Consequence |
|---|---|---|
| DOD purity | **Hybrid: data source + view nodes** | Systems own SoA struct arrays as the single source of truth. Each visible entity gets a *thin* Godot view node (`Sprite2D`/`ColorRect`) synced from data each frame. Collision is **manual AABB vs a tile grid + a uniform-grid broadphase** — no `CharacterBody2D`, no per-body `MoveAndSlide`. |
| Rewrite scope | **Full ground-up** | App shell, scene flow, service access, and the event model are all replaced with data-oriented equivalents: a frame-stepped `World`, an entity-id allocator, component stores, an ordered system scheduler, and frame-buffered event/command queues. Only the Godot project config + .NET setup survive untouched. |

### Why this is the realistic shape in Godot

Godot nodes are heap objects, and `MoveAndSlide` / physics queries run **per
body** through the physics server — they cannot be batched. So the DOD win does
**not** come from making enemies "go faster"; it comes from (a) owning all sim
state in contiguous arrays we iterate ourselves, (b) doing collision against an
array-backed tile grid instead of the physics server, and (c) collapsing N
per-node `_PhysicsProcess` callbacks into **one** `World.Step`. Godot keeps
doing what it's genuinely good at: drawing sprites, playing audio, and UI.

---

## 2. Target architecture

```
                 ┌──────────────────────────────────────────────┐
                 │ Game (single Godot node, app entry)           │
                 │  - owns World                                 │
                 │  - fixed-timestep accumulator                 │
                 │  - AppState machine (Boot/Menu/Play/GameOver) │
                 └───────────────┬──────────────────────────────┘
                                 │ _PhysicsProcess(delta)
                                 ▼
         accumulator += delta; while (accumulator >= DT) World.Step(DT)
                                 │
                                 ▼
   ┌─────────────────────────── World ───────────────────────────┐
   │  EntityAllocator (generational ids, free list)               │
   │  Component stores (SoA arrays, indexed by entity index)      │
   │  ComponentMask[] (presence bitset per entity)                │
   │  EventBuffer (double-buffered struct events)                 │
   │  CommandBuffer (deferred structural changes)                 │
   │  TileGrid (level solids, array-backed)                       │
   └──────────────────────────────────────────────────────────────┘
                                 │ ordered system schedule (§5)
                                 ▼
                 ┌──────────────────────────────────────────────┐
                 │ ViewSyncSystem  +  ViewPool                    │
                 │  pushes interpolated Transform+Render into     │
                 │  pooled Sprite2D/ColorRect view nodes          │
                 └──────────────────────────────────────────────┘
   _Process(delta): alpha = accumulator / DT; ViewSync renders interpolated
```

**Data flow rules**

- Systems read/write component stores. They never call each other directly.
- Systems communicate **forward in the frame** by writing to stores, the
  `EventBuffer`, or the `CommandBuffer` — never by holding references.
- Structural changes (spawn / despawn / add-remove component) are **deferred**:
  systems push to the `CommandBuffer`; `World.Step` flushes it once, at the end,
  so no system mutates store membership mid-iteration.
- The sim is **fixed-step and deterministic**; rendering interpolates between
  the previous and current transform for smoothness independent of step rate.

---

## 3. Core building blocks

### Entity = generational handle

```csharp
public readonly struct Entity {
    public readonly int Index;        // slot into the SoA arrays
    public readonly uint Generation;  // bumped on despawn → detects stale handles
}
```

`EntityAllocator` keeps a free-list of indices and a `uint[] generation`. A
handle is valid only if `generation[Index] == handle.Generation`. Fixed
capacity (e.g. `MaxEntities = 4096`) — all stores are preallocated; no per-spawn
allocation in the hot path.

### Component stores (SoA)

The `World` holds **explicit named parallel arrays** sized to `MaxEntities`,
plus one presence bitset per entity:

```csharp
Transform[]  transform;   // Pos, PrevPos (PrevPos drives render interpolation)
Motion[]     motion;      // Vel
Body[]       body;        // HalfExtents, Layer, Mask, CollisionFlags
Walk[]       walk;        // Speed, Dir, TurnAtCliffs, BounceForce
Mob[]        mob;         // Kind, Phase, Timer  (AI state)
Vulnerability[] vuln;     // Stompable / FireballKillable / StarKillable / Bumpable
PlayerControl[] player;   // input bits, PowerState, coyote, invuln timer
Projectile[] projectile;  // Kind, OwnerDir, bounces
Pickup[]     pickup;      // Kind, ScoreValue, CoinValue
Block[]      block;       // Kind, Contents, HitsLeft, BumpTimer
Platform[]   platform;    // Axis, Range, Speed, Phase
Lifetime[]   lifetime;    // Remaining seconds
Render[]     render;      // ViewKind, Frame, FlipH, Tint, Visible
ulong[]      mask;        // which components each entity has (ComponentId bitflags)
```

> **Why explicit named arrays, not a generic `Store<T>` or archetypes?** For a
> Mario-scale world (hundreds of entities, ~15 component types) named SoA arrays
> are the simplest, most cache-friendly option and keep the code grep-able. No
> reflection, no registry, no archetype graph. If a component genuinely needs
> sparse storage later, swap that one array for a packed store behind the same
> accessor — the systems don't care.

### EventBuffer (replaces the static `Events` hub)

Gameplay facts become **struct events** appended to a per-frame queue, consumed
at a defined point in the schedule, then cleared. Double-buffered so producers
(early systems) and consumers (late systems) never race.

```csharp
enum GameEventKind { ScoreEarned, CoinPickedUp, PowerupPickedUp, OneUp,
                     PlayerDamaged, PlayerDied, EnemyDefeated, BlockBumped,
                     GoalReached, SfxCue, MusicCue }
struct GameEvent { GameEventKind Kind; int A; int B; Vector2 Pos; }
```

### CommandBuffer (deferred structural changes)

```csharp
enum CommandKind { Spawn, Despawn, SetPower }
struct Command { CommandKind Kind; SpawnKind Spawn; Vector2 Pos; Entity Target; int Arg; }
```

`Spawning.Apply(world, command)` writes the right component set for a
`SpawnKind` into a fresh entity (a `switch`, not a factory-class registry).

### TileGrid

`byte[] cells` + `int width, height` + `Vector2 cellSize` + world origin.
Collision queries are O(few-cells) AABB lookups, fully array-backed.

### ViewPool + ViewSyncSystem

A preallocated pool of view nodes per `ViewKind`. Each frame `ViewSyncSystem`
walks entities with a `Render` component, leases/updates a view node
(`Position` from interpolated transform, `Frame`, `FlipH`, `Visible`), and
returns views of despawned entities to the pool. **No gameplay logic in views.**

---

## 4. Fixed timestep + interpolation

```csharp
// Game._PhysicsProcess(double delta)
_accumulator += delta;
while (_accumulator >= FixedDt) { _world.Step(FixedDt); _accumulator -= FixedDt; }

// Game._Process(double delta)  — visual only
float alpha = (float)(_accumulator / FixedDt);
_viewSync.Render(_world, alpha);     // lerp(PrevPos, Pos, alpha)
```

`FixedDt = 1.0/60.0`. `Transform.PrevPos` is copied from `Pos` at the top of
each `Step` so rendering can interpolate.

---

## 5. System schedule (the scheduler)

`World.Step` is an **explicit ordered method body** — no reflection, no
priority registry. Order *is* the contract:

| # | System (manager) | Reads | Writes |
|---|---|---|---|
| 1 | `InputSystem` | Godot input | `PlayerControl.input` |
| 2 | `PlayerControlSystem` | `PlayerControl`, `Body.flags` | `Motion`, `PlayerControl.power/invuln` |
| 3 | `MobAISystem` | `Mob`, `Body.flags`, `TileGrid` | `Motion`, `Mob.phase/timer`, CommandBuffer (e.g. Hammer/BulletBill spawn) |
| 4 | `WalkSystem` | `Walk`, `Body.flags`, `TileGrid` | `Motion`, `Walk.Dir` (wall/cliff turn) |
| 5 | `GravityIntegrationSystem` | `Motion`, gravity fields | `Motion.Vel`, `Transform.Pos` |
| 6 | `TileCollisionSystem` | `Body`, `Transform`, `Motion`, `TileGrid` | `Transform.Pos`, `Motion.Vel`, `Body.flags` |
| 7 | `BroadphaseSystem` | `Body`, `Transform` | `CollisionPair[]` buffer |
| 8 | `CombatSystem` | pairs, `Vulnerability`, `Mob`, `PlayerControl` | EventBuffer, CommandBuffer (despawn/defeat/power) |
| 9 | `TriggerSystem` | pairs, `Pickup`, goal/kill/cleanup tags | EventBuffer, CommandBuffer |
| 10 | `BlockSystem` | pairs (player-head ↔ block), `Block` | `Block`, EventBuffer, CommandBuffer (spawn contents) |
| 11 | `LifetimeSystem` | `Lifetime` | CommandBuffer (despawn) |
| 12 | `CameraSystem` | player `Transform`, level bounds | camera transform |
| 13 | `ScoreSessionSystem` | EventBuffer | `SaveData` (score/coin/lives) — **sole writer** |
| 14 | `AudioCueSystem` | EventBuffer (`SfxCue`/`MusicCue`) | Godot audio players |
| 15 | `CommandBufferSystem` | CommandBuffer | structural changes (spawn/despawn) |
| — | swap EventBuffer, clear pairs | | |

`ViewSyncSystem` runs separately in `_Process` (render), not in `Step`.

---

## 6. Combat without interfaces

The current `IStompable` / `IFireballHittable` / `IStarHittable` / `IBumpable`
sibling dispatch becomes **data + a resolution switch**. `BroadphaseSystem`
emits `CollisionPair { Entity a, b; ContactSide side; }`. `CombatSystem`
resolves each pair by inspecting components:

- Player ↔ Mob, `side == Top` and `vuln.Stompable` → defeat mob (despawn /
  shell state), bounce player, emit `EnemyDefeated` + `ScoreEarned` + `SfxCue`.
- Player ↔ Mob, side != Top → if player invuln/star: defeat mob; else
  `PlayerDamaged` (power down or `PlayerDied`).
- Projectile(fireball) ↔ Mob with `vuln.FireballKillable` → defeat + despawn projectile.
- Star-player ↔ Mob with `vuln.StarKillable` → defeat.
- Shell(Koopa) ↔ Mob → defeat chained mob.

"Defender decides" is preserved as **the victim's `Vulnerability` flags plus its
`Mob.Kind`**, read at resolution time — not as virtual dispatch on an object.

---

## 7. Level authoring → data baking

Levels stop being scenes full of entity nodes. A level is **data**:

```csharp
public partial class LevelData : Resource {
    [Export] public byte[] Tiles;          // row-major solids
    [Export] public int Width, Height;
    [Export] public Vector2 CellSize;
    [Export] public Vector2 PlayerStart, GoalPos;
    [Export] public Rect2 Bounds;
    [Export] public SpawnEntry[] Spawns;    // { SpawnKind Kind; Vector2 Pos; }
}
```

**Authoring stays in the editor** to keep ergonomics: edit a `TileMap` for
solids and drop position `Marker2D`s (tagged by kind) in a `.tscn`. A
`LevelLoader` runs once at level load, reads the `TileMap` into `TileGrid` and
the markers into `Spawn` commands, then discards the authoring nodes. Optionally
add an editor `[Tool]` "bake" button that serializes to `LevelData.tres` for
zero-parse runtime loads.

> This is the cleanest reconciliation of "author visually" with "runtime is pure
> data." It is also a **direct reversal** of the current "no marker-based level
> spawning" rule — see §9.

---

## 8. App shell (full ground-up)

- **`Game`** — the single Godot autoload/entry node. Owns the `World`, the fixed
  step loop, the `ViewPool`, the audio players, and the `AppState` machine. It is
  **not** a service locator; systems get the data they need from the `World`
  passed into `Step`.
- **`AppState`** — a plain enum state machine (`Boot → MainMenu → Playing →
  GameOver → MainMenu`) stepped by `Game`. Each state decides which systems run
  and which UI is visible.
- **UI** (`Hud`, `MainMenu`, `GameOver`) stays as Godot `Control` nodes — UI is
  low-count and event-driven, not sim. The HUD reads a small projected snapshot
  (score/coins/lives/time) that `ScoreSessionSystem` publishes once per frame.
- **`SaveData` / `Campaign`** remain Godot `Resource`s (already data). Campaign
  progression drives which `LevelData` loads next.
- **Audio** — `AudioCueSystem` consumes `SfxCue` / `MusicCue` events and drives
  pooled `AudioStreamPlayer`s owned by `Game`.

---

## 9. Relationship to current CLAUDE.md

This rewrite **reverses or replaces** these current rules. Adopting the plan
means rewriting `CLAUDE.md` accordingly:

| Current rule | Status under this plan |
|---|---|
| Flat per-entity *node* scripts | **Replaced** — entities are ids; behavior lives in systems, data in struct stores. |
| No base classes for entities | **Honored in spirit** — no inheritance at all; structs + functions. |
| Combat via `IStompable`/etc. sibling interfaces | **Replaced** — data-driven `Vulnerability` + `CombatSystem` switch. |
| Static `Events` hub (`event Action` + `Emit…`) | **Replaced** — frame-buffered struct `EventBuffer`. |
| `GameServices` service locator (`GetGameInstance/GetGameMode`) | **Replaced** — `World`-owned data; no locator. |
| One autoload `GameInstance` | **Replaced by** one autoload `Game` (still exactly one). |
| Level entities placed as nodes; no markers/factories | **Reversed** — levels are data; spawns come from a baked spawn list / `SpawnKind` switch. |
| `GameMode` sole writer to `SaveData` | **Preserved as** `ScoreSessionSystem` being the sole `SaveData` writer. |
| `[Export]` vertical ownership, no `GetParent()` | **N/A** — almost no gameplay nodes remain; views are leaf-only. |

**Retained conventions:** `public partial class` for the few Godot nodes;
`SMB` namespace; `delta` is `double`; `Vector2` assigned whole; mirror tuning
constants from the MonoGame port rather than re-tuning; `dotnet build` before
`godot --headless`.

---

## 10. Directory layout

```
Scripts/
  Core/
    Game.cs              Entity.cs          World.cs
    Components.cs        ComponentId.cs     EventBuffer.cs
    CommandBuffer.cs     Spawning.cs        AppState.cs
    TileGrid.cs          CollisionPair.cs
  Systems/
    InputSystem.cs           PlayerControlSystem.cs   MobAISystem.cs
    WalkSystem.cs            GravityIntegrationSystem.cs
    TileCollisionSystem.cs   BroadphaseSystem.cs      CombatSystem.cs
    TriggerSystem.cs         BlockSystem.cs           LifetimeSystem.cs
    CameraSystem.cs          ScoreSessionSystem.cs    AudioCueSystem.cs
    ViewSyncSystem.cs
  View/
    ViewPool.cs          ViewKind.cs
  Data/
    LevelData.cs         LevelLoader.cs     Campaign.cs     SaveData.cs
  UI/
    Hud.cs               MainMenu.cs        GameOver.cs
Levels/                  authoring .tscn (TileMap + markers) and/or baked .tres
```

---

## 11. Build phases

Each phase ends with `dotnet build supermario-cs.csproj`,
`godot --headless --path . --quit`, and a manual playtest. Ship a playable build
at the end of every phase.

| Phase | Deliverable | Validation |
|---|---|---|
| **0 — Skeleton** | `Game` + `World` + fixed-step loop + `ViewPool`; one test entity moving with render interpolation. | One smooth-moving rect; one `World.Step`, zero gameplay nodes. |
| **1 — Player on tiles** | `TileGrid` + `LevelLoader`; `Input`/`PlayerControl`/`Gravity`/`TileCollision` systems; run + jump on a static level. | Movement/jump feel matches MonoGame constants. |
| **2 — Enemies + combat** | `Walk` + `MobAISystem` (Goomba, Koopa); `Broadphase`; `CombatSystem`; `EventBuffer`; `ScoreSessionSystem`; HUD. | Stomp/contact/score correct; one authoritative `SaveData` writer. |
| **3 — Pickups + blocks** | Pickup triggers; Question/Brick/Used blocks; power states; fireball projectile; star invuln. | Powerups, bumps, fireball kills, star all parity. |
| **4 — Full bestiary** | Piranha, Blooper, BulletBill + cannon, HammerBro + hammer, Podoboo, Spiny, Paratroopa, BuzzyBeetle; moving platforms. | Each enemy matches port behavior. |
| **5 — Shell + flow** | `AppState` machine, menus, game over, campaign progression, save/load; goal / kill / cleanup triggers; audio cues. | Full Boot→Menu→Play→GameOver→next-level loop. |
| **6 — Parity + perf** | Constant audit vs MonoGame port; perf pass (view churn, broadphase); delete all dead OO code; rewrite `CLAUDE.md`. | 60 fps; feature parity; docs match reality. |

---

## 12. Risks & open questions

- **Collision feel parity.** Manual swept-AABB must reproduce the MonoGame
  port's movement exactly. Lift its constants and resolution order verbatim;
  budget tuning time in Phase 1.
- **Deferred-structural ordering.** Spawning/despawning only at end-of-frame can
  surprise systems that expect immediate effect. Keep the flush point fixed and
  documented; never spawn mid-system.
- **View pool churn.** High-count short-lived effects (debris, coins) should use
  a dedicated SoA effect pool + batched draw rather than one view node each.
- **Determinism vs Godot input timing.** Sample input once per `Step`, not per
  `_Process`, to keep the sim frame-rate independent.
- **Editor ergonomics.** Removing entity nodes means level design happens via
  markers + a bake step; confirm this is acceptable before Phase 1, or invest in
  a small `[Tool]` authoring aid.
- **PhysicsServer2D escape hatch.** SMB has no slopes, so array-backed AABB is
  sufficient; keep `PhysicsServer2D` shape queries as a fallback only if an odd
  case needs it.

## 13. Definition of done

- Feature parity with the current build: all enemies, pickups, blocks, levels,
  campaign progression, save/load, audio.
- A single fixed-step `World.Step` drives the entire simulation; **no gameplay
  behavior in any Godot node** — nodes are views, UI, or audio only.
- All gameplay state lives in struct component stores; `ScoreSessionSystem` is
  the sole `SaveData` writer.
- Stable 60 fps on the target devices (desktop + .NET 9 Android).
- `CLAUDE.md` rewritten to describe this architecture.
