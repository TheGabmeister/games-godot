# Port Plan: MonoGame/Nez → Godot 4.6 C#

This document is the implementation specification for porting the working MonoGame project at `c:\dev\games-monogame\SuperMario` to this Godot repo. It is comprehensive enough to hand off without further design discussion. Open items at the bottom are explicitly flagged.

## Overview

Preserve from MonoGame: 3-manager pattern, scenes-report / GameManager-decides, combat interfaces, physics layer split, idempotent music, gameplay constants.

Replace: Tiled-driven `EntityFactory` registry → Godot-native scene composition (one `.tscn` per entity).

The existing Godot code (5 autoloads, EventBus, drawer pattern, persistent player, per-level scripts, state-machine player) is **not the target architecture**. Phase 1 strips it. Don't try to retrofit on top of it.

---

## What survives from MonoGame

- **3 managers → 3 autoloads**: `GameManager`, `MusicManager`, `SfxManager`. Nothing else is an autoload.
- **Scenes-report / GameManager-decides.** Scenes emit signals; `GameManager` decides the next scene. Scenes never advance themselves.
- **`GameState`**: `Score`, `Lives`, `PowerState`. Events: `ScoreChanged`, `LivesChanged`.
- **4 combat interfaces**: `IFireballHittable` (returns `FireballReaction`), `IStompable`, `IStarHittable`, `IBumpable`. Defender decides its own reaction; attacker decides its own reaction.
- **Two damage paths**: `Hitbox` (stomp-aware, calls `TakeDamage`) and `KillVolume` (instant `KillPlayer`).
- **Physics layer split**: `PickupBody` vs `PickupTrigger`. Mario walks **through** pickups while still triggering them. This is a deliberate invariant.
- **`MusicManager.Play(track)` no-op if same track already playing** — keeps level music continuous across same-level reload on death.
- **All gameplay constants**: gravity, jump force, walk speeds, bump distance/duration, score values, lifetimes, etc. Mirror values from [MonoGame Constants.cs](file:///c:/dev/games-monogame/SuperMario/Source/Constants.cs) into this project's `Scripts/Constants.cs`. Don't tune.

## What dies / changes shape

- **`EntityFactory` registry + colocated `static Spawn(Scene, TmxObject)`.** Replaced by one `.tscn` per entity. Per-instance tuning via `[Export]` fields edited in the inspector.
- **Tiled `.tmx`.** Levels are Godot `.tscn` files.
- **`EntityFactory.GetCenter` rotation math.** Godot `Transform2D` handles it natively.
- **Variant entities collapse.** `RedKoopaTroopa` + `GreenKoopaTroopa` → one `koopa_troopa.tscn` + `[Export] KoopaColor`. `LeftRightLift` + `UpDownLift` → `moving_platform.tscn` + `[Export] MovingPlatformAxis`.
- **`GameState` ownership.** Owned by `GameManager` autoload (`GameManager.Instance.State`). Not constructor-threaded — Godot's `PackedScene.Instantiate()` takes no args.
- **Player lifecycle.** Re-spawned per level load (not persisted). Matches MonoGame's clean-slate reload.
- **`CleanupVolume`.** Authored as a node placed at the bottom of each level; not auto-sized from map dimensions.
- **`Assets.cs` generator.** Not ported. Audio referenced as `AudioStream` exports on resources, or `res://` paths on autoload calls.
- **`PlayerDrawer` + `_Draw()` + state machine.** Deleted. Real sprites + flat physics methods replace it.

## Nez → Godot mapping

| Nez | Godot |
|---|---|
| `Core.Scene = new XScene()` | `GameManager` instantiates level `PackedScene`, swaps it under `LevelRoot` |
| `Scene` subclass | Level `.tscn` whose root is `Node2D` with `LevelBase` script |
| `Component` on `Entity` | Script on a node inside an entity `.tscn` |
| `GlobalManager` | Autoload |
| `BoxCollider` + `Mover` + `GravityBody` | `CharacterBody2D` + `CollisionShape2D` |
| `BoxCollider` (trigger) | `Area2D` + `CollisionShape2D` |
| `PrototypeSpriteRenderer` | `Sprite2D` / `AnimatedSprite2D` |
| `VirtualButton` / `VirtualIntegerAxis` | `Input.IsActionPressed("...")` (map in `project.godot`) |
| `SoundEffect` / `Song` | `AudioStreamPlayer` (both via `.ogg`) |
| `Nez.Tweens` | `Tween` via `CreateTween()` |
| Tiled object Class | `[Export]` enum on entity script |
| `EntityFactory.Spawn` registration | Drag entity `.tscn` into level scene at edit time |
| `Scene.FindComponentOfType<T>` | `GetTree().GetFirstNodeInGroup("...")` |

---

## File structure

```
supermario-cs/
├── PLAN.md, CLAUDE.md, project.godot, supermario-cs.csproj
├── Scripts/
│   ├── Constants.cs                       # layers + gameplay values
│   ├── Autoloads/
│   │   ├── GameManager.cs
│   │   ├── MusicManager.cs
│   │   └── SfxManager.cs
│   ├── Resources/
│   │   ├── LevelDefinition.cs
│   │   └── Campaign.cs
│   ├── Components/                        # reusable child-node scripts
│   │   ├── Hitbox.cs
│   │   ├── Walker.cs
│   │   ├── Bumpable.cs
│   │   └── Lifetime.cs
│   ├── Interfaces/
│   │   ├── IStompable.cs
│   │   ├── IFireballHittable.cs           # also FireballReaction enum
│   │   ├── IStarHittable.cs
│   │   └── IBumpable.cs
│   ├── Player/
│   │   ├── PlayerController.cs
│   │   ├── PlayerPowerState.cs            # enum
│   │   └── Blinker.cs                     # i-frame visual flicker
│   ├── Level/
│   │   ├── LevelBase.cs
│   │   ├── CleanupVolume.cs
│   │   ├── KillVolume.cs
│   │   └── GoalTrigger.cs
│   ├── Entities/                          # one file per entity type
│   │   ├── Platform.cs, MovingPlatform.cs
│   │   ├── BrickBlock.cs, QuestionBlock.cs, UsedBlock.cs
│   │   ├── Coin.cs, Mushroom.cs, FireFlower.cs, OneUp.cs, Starman.cs
│   │   ├── Goomba.cs, KoopaTroopa.cs, KoopaShell.cs, KoopaParatroopa.cs
│   │   ├── BuzzyBeetle.cs, Spiny.cs, PiranhaPlant.cs
│   │   ├── HammerBro.cs, Blooper.cs, BulletBillCannon.cs, Podoboo.cs
│   │   ├── Fireball.cs, Hammer.cs, BulletBill.cs
│   ├── Ui/
│   │   ├── Hud.cs, ScorePopup.cs
│   │   ├── MainMenuController.cs, GameOverController.cs
│   └── Enums/
│       ├── KoopaColor.cs, MovingPlatformAxis.cs
├── scenes/
│   ├── main_menu.tscn, game_over.tscn
│   ├── player.tscn, hud.tscn
│   ├── level_base.tscn                    # template; level scenes inherit
│   ├── levels/world_1_1.tscn, world_1_2.tscn, world_1_3.tscn
│   └── entities/<one .tscn per Scripts/Entities/*.cs>
├── resources/
│   ├── campaign.tres
│   └── levels/world_1_1.tres, world_1_2.tres, world_1_3.tres
├── art/                                   # sprite assets (sourced separately)
├── music/, sfx/                           # .ogg files
```

Everything under existing `Scripts/Autoloads/`, `Scripts/Config/`, `Scripts/Level/`, `Scripts/Player/`, `Scripts/Ui/`, `Scripts/Visual/`, plus `scenes/main.tscn` and `scenes/player.tscn`, is **deleted in Phase 1**.

---

## Constants

`Scripts/Constants.cs` mirrors `c:\dev\games-monogame\SuperMario\Source\Constants.cs` value-for-value plus layer flags:

```csharp
public static class Layers {
    public const uint Player          = 1u << 0;   // bit 0 → Godot layer 1
    public const uint Enemy           = 1u << 1;
    public const uint PickupBody      = 1u << 2;
    public const uint Environment     = 1u << 3;
    public const uint Projectile      = 1u << 4;
    public const uint EnemyProjectile = 1u << 5;
    public const uint PickupTrigger   = 1u << 6;
    public const uint LevelTrigger    = 1u << 7;
}

public static class Constants {
    public const float Gravity = 1200f;
    public const float JumpForce = -680f;
    public const float MaxFallSpeed = 600f;
    public const float PlayerSpeed = 280f;
    public const float StompBounceForce = -420f;
    public const float StompTopTolerance = 16f;
    public const float MovingPlatformDistance = 160f;
    public const float MovingPlatformSpeed = 80f;
    public const float BlockBumpDistance = 8f;
    public const float BlockBumpDuration = 0.18f;
    public const int   BrickBreakScore = 50;
    public const int   CoinValue = 200;
    public const int   MushroomScore = 1000;
    public const int   StarmanPickupScore = 1000;
    public const float StarmanSpeed = 220f;
    public const float StarmanBounceForce = -420f;
    public const float StarmanInvincibleDuration = 10f;
    public const float GoombaWalkSpeed = 80f;
    // ... etc — every value from MonoGame Constants.cs
    public const int   StartingLives = 3;
    public const int   MaxFireballs = 2;
    public const float PlayerInvulnDuration = 2f;
}
```

Layer numbers in `project.godot` must match the bit positions above. Set the named-layer slots in **2D Physics Layers** in Project Settings → Layer Names.

---

## Physics layers

| # | Name | Used by |
|---|---|---|
| 1 | `Player` | `PlayerController` body |
| 2 | `Enemy` | Enemy `CharacterBody2D` body + `Hitbox` Area2D |
| 3 | `PickupBody` | Dynamic pickup `CharacterBody2D` body |
| 4 | `Environment` | Terrain, platforms, blocks |
| 5 | `Projectile` | Player projectile body + `HitArea` Area2D |
| 6 | `EnemyProjectile` | Enemy projectile body + `HitArea` Area2D |
| 7 | `PickupTrigger` | Pickup trigger Area2D (static pickups: also the body) |
| 8 | `LevelTrigger` | `GoalTrigger`, `KillVolume`, `CleanupVolume` |

**Mask reference (what each thing detects):**

| Body / Area | `layer` | `mask` |
|---|---|---|
| Player body | `Player` | `Environment`, `PickupTrigger`, `LevelTrigger` |
| Enemy body | `Enemy` | `Environment` |
| Enemy `Hitbox` Area2D | `Enemy` | `Player` |
| Pickup body (dynamic) | `PickupBody` | `Environment` |
| Pickup trigger Area2D | `PickupTrigger` | `Player` |
| Coin (static) Area2D | `PickupTrigger` | `Player` |
| Player projectile body | `Projectile` | `Environment` |
| Player projectile `HitArea` | `Projectile` | `Enemy` |
| Enemy projectile body | `EnemyProjectile` | `Environment` |
| Enemy projectile `HitArea` | `EnemyProjectile` | `Player` |
| Terrain / `UsedBlock` (`StaticBody2D`) | `Environment` | — |
| `BrickBlock` / `QuestionBlock` body | `Environment` | — |
| `KillVolume` / `GoalTrigger` | `LevelTrigger` | `Player` |
| `CleanupVolume` | `LevelTrigger` | `Player`, `Enemy`, `PickupBody`, `Projectile`, `EnemyProjectile` |

**Critical invariant**: Player body's mask does **not** include `PickupBody`. This is what makes Mario walk through pickups while still triggering them via `PickupTrigger`.

---

## Wiring rules

Three allowed coupling patterns. Anything else is a smell.

1. **Vertical ownership (parent ↔ child): call down, signal up.** Parent instantiates child, holds reference, calls methods directly. Child emits signals; parent connects. Child never reaches up — `GetParent()`, `GetNode("../...")` are forbidden.
2. **Global services (autoloads): direct calls allowed.** Any node may call `GameManager.Instance`, `MusicManager.Instance`, `SfxManager.Instance` directly. Mutations to autoload-owned state propagate back via events on the autoload (`GameState.ScoreChanged` etc.) for observers like HUD.
3. **Sibling interactions: direct calls via interfaces.** Combat (`IFireballHittable`/`IStompable`/`IStarHittable`/`IBumpable`), `Hitbox` → `PlayerController.TakeDamage`, `KillVolume` → `PlayerController.KillPlayer`. No ownership relationship to respect.

**Concrete consequence — pickups mutate `GameState` directly**: Coin's `BodyEntered` calls `GameManager.Instance.State.AddScore(Points)`. Don't route pickup score through signals; the wiring cost at scale (~100 coins/level) isn't worth the abstract decoupling.

**Concrete consequence — components reference their owner via `[Export]`**, set in the inspector at scene-author time. Never `GetParent()`. The Hitbox/Walker/Bumpable scripts all follow this.

---

## Autoloads

Three autoloads, registered in `project.godot` in this order: `GameManager`, `MusicManager`, `SfxManager`.

### `GameManager`

Drives all scene transitions. Owns `GameState` and the campaign cursor.

```csharp
public partial class GameManager : Node {
    public static GameManager Instance { get; private set; }
    public GameState State { get; private set; }
    public LevelBase CurrentLevel { get; private set; }   // used by projectile spawners

    [Export] private PackedScene _mainMenuScene;
    [Export] private PackedScene _gameOverScene;

    private Campaign _campaign;
    private int _currentLevelIndex;

    public override void _Ready() {
        Instance = this;
        _campaign = GD.Load<Campaign>("res://resources/campaign.tres");
        LoadMainMenu();
    }

    public void LoadMainMenu() { /* swap to main_menu.tscn; subscribe StartPressed */ }
    public void StartGame()     { /* new GameState; index=0; LoadLevel(_campaign.Levels[0]) */ }
    public void LoadLevel(LevelDefinition def) { /* instantiate def.LevelScene, wire signals, AddChild under LevelRoot, set CurrentLevel */ }
    public void OnLevelCompleted(LevelDefinition def) { /* index++; next or game over */ }
    public void OnPlayerDied(LevelDefinition def)     { /* State.PowerState=Small, Lives--; if 0 → game over, else reload */ }
    private void LoadGameOver() { /* swap to game_over.tscn; subscribe Continue */ }
}
```

`LevelRoot` is a `Node` child of the autoload itself (or a top-level `Main` shell with a `LevelRoot` child — see Top-level scenes). The level scene is instantiated as its child.

### `MusicManager`

```csharp
public partial class MusicManager : Node {
    public static MusicManager Instance { get; private set; }
    private AudioStreamPlayer _player;
    private AudioStream _current;

    public override void _Ready() {
        Instance = this;
        _player = new AudioStreamPlayer { Bus = "Music" };
        AddChild(_player);
    }

    public void Play(AudioStream stream) {
        if (stream == _current && _player.Playing) return;   // idempotent
        _current = stream;
        _player.Stream = stream;
        _player.Play();
    }

    public void Stop() { _player.Stop(); _current = null; }
}
```

Idempotency is compared by reference (the `AudioStream` resource). LevelDefinition holds one `AudioStream` per track; same resource → idempotent.

### `SfxManager`

Fire-and-forget. Internally pools `AudioStreamPlayer` nodes (10 should be plenty) to allow overlapping SFX. Drops requests when all are busy.

```csharp
public partial class SfxManager : Node {
    public static SfxManager Instance { get; private set; }
    public void Play(AudioStream stream);
}
```

---

## Resources: `LevelDefinition` and `Campaign`

```csharp
[GlobalClass]
public partial class LevelDefinition : Resource {
    [Export] public string Name;                // "World 1-1"
    [Export] public PackedScene LevelScene;     // res://scenes/levels/world_1_1.tscn
    [Export] public AudioStream MusicTrack;
    [Export] public float TimeLimit = 400f;
}

[GlobalClass]
public partial class Campaign : Resource {
    [Export] public LevelDefinition[] Levels;
}
```

- One `world_X_Y.tres` per level under `resources/levels/`.
- `resources/campaign.tres` holds the ordered `LevelDefinition[]`.
- `LevelBase` exports its own `LevelDefinition` reference, set per-scene (the same `.tres` that `Campaign` references). Self-contained — `LevelBase` doesn't need anything injected at runtime.

Reordering levels = inspector edit on `campaign.tres`. No code changes.

---

## `GameState`

Plain C# class. Owned by `GameManager`. Not an autoload itself.

```csharp
public class GameState {
	public int Score { get; private set; }
	public int Lives { get; set; } = Constants.StartingLives;
	public PlayerPowerState PowerState { get; set; } = PlayerPowerState.Small;

	public event Action<int> ScoreChanged;
	public event Action<int> LivesChanged;

	public void AddScore(int points) { /* clamp + raise ScoreChanged */ }
}
```

Constructed in `GameManager.StartGame()`. Lives clamps at `MaxLives = 99` (mirror MonoGame if it has one; otherwise just don't clamp).

**Subscribers must unsubscribe in `_ExitTree`** — `GameState` outlives the level, so any per-level subscriber (HUD) leaks if it doesn't disconnect.

---

## Combat interfaces

```csharp
public interface IStompable     { void OnStomped(PlayerController p); }
public interface IStarHittable  { void OnHitByStar(PlayerController p); }
public interface IFireballHittable {
	FireballReaction OnHitByFireball();
}
public interface IBumpable      { void OnBumped(PlayerController p); }

public enum FireballReaction { Defeated, Blocked }
```

Implemented by individual entity scripts. Direct ports from MonoGame.

---

## Reusable components

Four child-node components, all in `Scripts/Components/`. Each one owns a focused responsibility and references its owner via `[Export]`.

### `Hitbox` (`Area2D + script`)

Universal "damage volume." Attaches as a child Area2D on enemies, hazards, anything that should damage the player on contact.

Behavior: on `BodyEntered` with the player, branches:
1. If `player.IsStarInvincible` → `IStarHittable.OnHitByStar` (if owner implements) and return.
2. Else if owner is `IStompable` and player is descending from above (`Velocity.Y > 0` and player Y < owner Y - `StompTopTolerance`) → `IStompable.OnStomped` and return.
3. Else → `player.TakeDamage()`.

Owner-interface set picks the variant. Hazards with no interfaces always damage (unless star-invincible).

### `Walker` (`Node + script`)

Gravity + horizontal walk + turn-at-wall + optional turn-at-cliff + optional bounce-on-land.

```csharp
public partial class Walker : Node {
	[Export] private CharacterBody2D _body;
	[Export] public float Speed = 80f;
	[Export] public bool TurnAtCliffs = false;
	[Export] public float BounceForce = 0f;  // 0 = no bounce (default); negative = upward bounce on landing
	public int Direction = -1;
	// _PhysicsProcess: apply gravity, set velocity from Speed*Direction, MoveAndSlide, flip on wall/cliff, bounce if grounded and BounceForce!=0
}
```

Used by enemies (Goomba, BuzzyBeetle, Spiny, KoopaTroopa), dynamic pickups (Mushroom, OneUp, Starman). Starman sets `BounceForce = Constants.StarmanBounceForce`.

### `Bumpable` (`Node + script`)

Sine half-arc visual bump animation for blocks. Animates a target `Node2D` (typically the block's Sprite2D), **not the collision body** — the bump is cosmetic.

```csharp
public partial class Bumpable : Node {
    [Export] private Node2D _visual;
    public void Bump();   // idempotent during animation
}
```

Duration = `Constants.BlockBumpDuration`, peak offset = `Constants.BlockBumpDistance`. Per-instance `_isBumping` flag prevents stacking.

### `Lifetime` (`Node + script`)

Auto-`QueueFree`s its parent after `Duration` seconds.

```csharp
public partial class Lifetime : Node {
    [Export] public float Duration = 3f;
    // _Ready: start a Timer or use a SceneTreeTimer; on timeout: GetParent().QueueFree()
}
```

Used by all three projectiles (Fireball, Hammer, BulletBill).

---

## Top-level scenes

Three top-level templates, instantiated by `GameManager`:

- `scenes/main_menu.tscn` — root: `Control`, script: `MainMenuController`. Emits `[Signal] StartPressed`. `GameManager` listens.
- `scenes/game_over.tscn` — root: `Control`, script: `GameOverController`. Emits `[Signal] Continue`. `GameManager` listens.
- `scenes/levels/world_X_Y.tscn` — root: `Node2D` inheriting from `level_base.tscn`.

There is **no `main.tscn` shell**. `project.godot` `run/main_scene` points to a one-time bootstrap scene (or `GameManager` autoload's `_Ready` immediately calls `LoadMainMenu()`). The level itself becomes a child of `GameManager` (under a `LevelRoot: Node` child added in `GameManager._Ready`). Same for menu and game-over scenes — one swappable child at a time.

---

## Level scene structure

Each level is **self-contained**. Root is a `Node2D` with `LevelBase` script.

`level_base.tscn` template (saved under `scenes/level_base.tscn`):

```
LevelBase (Node2D, script: LevelBase.cs)
├── PlayerStart (Marker2D)              # required — LevelBase asserts presence
├── CleanupVolume (Area2D, script)      # at bottom; LevelTrigger layer; broad mask
├── GoalTrigger (Area2D, script)        # placed by level designer at goal
└── (level-specific content added per scene: terrain, blocks, enemies, pickups, KillVolumes, PiranhaPlant pipes, …)
```

Each concrete level scene **inherits** from `level_base.tscn` (Godot's inherited-scene feature) and adds its own content. The `[Export] LevelDefinition _config` slot on the root is set to the matching `.tres`.

```csharp
public partial class LevelBase : Node2D {
    [Export] public LevelDefinition Config;
    [Export] private PackedScene _playerScene;       // res://scenes/player.tscn
    [Export] private PackedScene _hudScene;          // res://scenes/hud.tscn

    [Signal] public delegate void LevelCompletedEventHandler();
    [Signal] public delegate void PlayerDiedEventHandler();

    public override void _Ready() {
        MusicManager.Instance.Play(Config.MusicTrack);

        var start = GetNode<Marker2D>("PlayerStart");
        var player = _playerScene.Instantiate<PlayerController>();
        player.GlobalPosition = start.GlobalPosition;
        AddChild(player);
        player.Died += () => EmitSignal(SignalName.PlayerDied);

        var goal = GetNode<GoalTrigger>("GoalTrigger");
        goal.Reached += () => EmitSignal(SignalName.LevelCompleted);

        var hud = _hudScene.Instantiate<Hud>();
        hud.Bind(Config);   // HUD reads level name + time limit from Config
        AddChild(hud);
    }
}
```

`_playerScene` and `_hudScene` are set once on the `level_base.tscn` template; inherited level scenes inherit them.

**Why this split:**

- **`GameManager` doesn't spawn the player.** It owns scene swaps, not level internals. Reaching into a level to `AddChild` a player would violate call-down/signal-up.
- **Player isn't placed in the `.tscn` at edit time.** Reasons: (1) one source of player config — changes to `player.tscn` propagate automatically; (2) `PlayerStart` can later carry data (facing, intro animation) that a baked transform can't; (3) it's forgettable — every new level would have to remember to drop a Player node.
- **`PlayerStart` is required.** `LevelBase` asserts/throws in `_Ready` if missing.

---

## HUD

`scenes/hud.tscn`: `CanvasLayer` root, script `Hud.cs`. Children are `Label` nodes for `MARIO` (placeholder name), `SCORE`, `WORLD`, `TIME`, `LIVES`. Positioning per original Mario HUD (top of screen).

```csharp
public partial class Hud : CanvasLayer {
    [Export] private Label _scoreLabel, _worldLabel, _timeLabel, _livesLabel;
    private LevelDefinition _config;
    private float _timeRemaining;

    public void Bind(LevelDefinition config) {
        _config = config;
        _timeRemaining = config.TimeLimit;
        _worldLabel.Text = config.Name;
        OnScoreChanged(GameManager.Instance.State.Score);
        OnLivesChanged(GameManager.Instance.State.Lives);
        GameManager.Instance.State.ScoreChanged += OnScoreChanged;
        GameManager.Instance.State.LivesChanged += OnLivesChanged;
    }

    public override void _ExitTree() {
        GameManager.Instance.State.ScoreChanged -= OnScoreChanged;
        GameManager.Instance.State.LivesChanged -= OnLivesChanged;
    }

    public override void _Process(double delta) {
        _timeRemaining = Mathf.Max(0f, _timeRemaining - (float)delta);
        _timeLabel.Text = ((int)_timeRemaining).ToString();
        // time-out → kill player (Phase 9 polish; can be deferred)
    }
}
```

HUD owns the level timer for display. Time-out → kill the player (use `GetTree().GetFirstNodeInGroup("player")` and call `KillPlayer()`). Phase 9 polish; not required for earlier phases.

---

## Player

`scenes/player.tscn`:

```
Player (CharacterBody2D, script: PlayerController.cs)
├── Sprite2D (or AnimatedSprite2D)
├── CollisionShape2D                              # layer=Player, mask=Environment|PickupTrigger|LevelTrigger
├── Blinker (Node, script: Blinker.cs)            # [Export] _sprite
└── Camera2D                                      # follows player; limits set by level
```

Player joins the `"player"` group in `_Ready` so AI-querying enemies can find it via `GetTree().GetFirstNodeInGroup("player")`.

**Power states:**

```csharp
public enum PlayerPowerState { Small, Big, Fire }
```

Player reads `GameManager.Instance.State.PowerState` on spawn (`_Ready`) — re-spawn after death uses the post-death `Small` value `GameManager` sets.

**Public methods:**

```csharp
public partial class PlayerController : CharacterBody2D {
    public event Action Died;

    public PlayerPowerState State { get; private set; }
    public bool IsStarInvincible => _starTimer > 0f;
    public bool CanBreakBricks => State != PlayerPowerState.Small;

    public void ApplyMushroom();        // Small → Big; no-op if already Big/Fire
    public void ApplyFireFlower();      // any → Fire
    public void ApplyStarman();         // start invuln timer
    public void TakeDamage();           // Big/Fire → Small (+ invuln); Small → KillPlayer
    public void KillPlayer();           // emit Died; play animation; ignore further input

    public void NotifyFireballDestroyed();  // called by Fireball.Destroy to decrement counter
}
```

**Head-bump detection** (after `MoveAndSlide`):

```csharp
for (int i = 0; i < GetSlideCollisionCount(); i++) {
    var col = GetSlideCollision(i);
    if (col.GetNormal().Y > 0.9f && col.GetCollider() is IBumpable b) {
        b.OnBumped(this);
    }
}
```

**Fireball spawning**: player has `[Export] PackedScene _fireballScene`. On fire input (and `State == Fire` and `_activeFireballs < MaxFireballs`):

```csharp
var fb = _fireballScene.Instantiate<Fireball>();
fb.Init(MuzzlePosition, _facing, this);
GameManager.Instance.CurrentLevel.AddChild(fb);
_activeFireballs++;
```

`MuzzlePosition` is a `Vector2` computed from the player's position + facing offset (a `Marker2D` child works too).

**Invulnerability** after `TakeDamage`: `_invulnTimer = Constants.PlayerInvulnDuration`, `Blinker.Start()`, the Hitbox dispatch on enemies returns harmlessly when player has active invuln (Hitbox checks `player.IsInvulnerable` — add to Hitbox dispatch).

`Blinker` toggles `_sprite.Visible` at a high rate while invuln is active, off when done.

---

## Enemy structure

Enemies are the most component-heavy entity category. Build via child-node composition, **not inheritance**.

### Canonical scene (Goomba)

```
goomba.tscn (root: CharacterBody2D, script: Goomba.cs)
├── Sprite2D
├── CollisionShape2D                         # body, layer=Enemy mask=Environment
├── Hitbox (Area2D, script: Hitbox.cs)       # [Export] _owner = parent; layer=Enemy mask=Player
│   └── CollisionShape2D
└── Walker (Node, script: Walker.cs)         # [Export] _body = parent
```

### Goomba script (entire file)

```csharp
public partial class Goomba : CharacterBody2D,
	IFireballHittable, IStompable, IStarHittable
{
	public void OnStomped(PlayerController _) => QueueFree();
	public FireballReaction OnHitByFireball() { QueueFree(); return FireballReaction.Defeated; }
	public void OnHitByStar(PlayerController _) => QueueFree();
}
```

### Authoring rules

- No `Enemy` / `WalkingEnemy` base class. Each enemy is a flat `CharacterBody2D` script implementing the combat interfaces it cares about.
- Components reference their owner via `[Export]`, never `GetParent()`.
- Variants are `[Export]` enums on the leaf script. `KoopaTroopa.Color`, etc. Red vs Green = `Walker.TurnAtCliffs = false` on green's Walker (red doesn't walk off cliffs).
- One `.tscn` + one `.cs` per enemy type.

### Per-enemy interface set

| Enemy | `IStompable` | `IFireballHittable` | `IStarHittable` | Notes |
|---|:---:|:---:|:---:|---|
| Goomba | ✓ | ✓ | ✓ | flat |
| KoopaTroopa | ✓ | ✓ | ✓ | stomp → spawn `koopa_shell.tscn`, free self |
| KoopaShell | ✓ | — | ✓ | stomp → toggle moving / stationary |
| KoopaParatroopa | ✓ | ✓ | ✓ | stomp → spawn ground KoopaTroopa, free self |
| BuzzyBeetle | ✓ | — | ✓ | fireball-immune |
| Spiny | — | ✓ | ✓ | not stompable |
| PiranhaPlant | — | ✓ | ✓ | stationary; suppress emerge if player near |
| HammerBro | ✓ | ✓ | ✓ | shuffle + jump + throw |
| Blooper | ✓ | ✓ | ✓ | water-only chase |
| BulletBillCannon | — | — | — | structural — spawner, not a damageable enemy |
| BulletBill | — | ✓ | ✓ | projectile that's also enemy-like; stompable in original Mario — implement `IStompable` too |
| Podoboo | — | — | ✓ | lava arc; usually invulnerable to stomp/fireball |

### Detection rules

- **Attacker scans for defender.** Each attacker carries its own detection.
  - Player → enemy: enemy's `Hitbox` Area2D detects.
  - Fireball → enemy: fireball's `HitArea` scans `Enemy` layer.
  - Enemy projectile → player: projectile's `HitArea` detects.
- **Star-invincible hits go through enemy `Hitbox`**, not a separate attacker. `Hitbox` branches on `player.IsStarInvincible`.
- **AI position queries** use `GetTree().GetFirstNodeInGroup("player")`. Player joins `"player"` group in `_Ready`. Replaces MonoGame's `Scene.FindComponentOfType<PlayerController>()`.
- **Wake-up radius** (chase AI from distance): not needed for current roster. If added, pattern is a `DetectionRange` Area2D child.

### Timing gotcha

Child `_Ready` runs **before** parent `_Ready`. Since `LevelBase._Ready()` spawns the player, the player doesn't exist when entity `_Ready`s run. Enemies must look up the player **on demand** (per-frame `GetFirstNodeInGroup` — O(1), safe) or lazy-init on first use. Never cache the player in `_Ready`.

### Movement profiles

- `Walker` covers: Goomba, BuzzyBeetle, Spiny, KoopaTroopa.
- Per-enemy `_PhysicsProcess` covers: KoopaShell, KoopaParatroopa (flight), PiranhaPlant, HammerBro, Blooper, Podoboo.
- Add a new component (`Jumper`, `Swimmer`) only if a movement pattern repeats across ≥2 enemies. Don't preemptively extract.

### Exceptions

- **KoopaTroopa → shell.** On stomp, `QueueFree` self and spawn `koopa_shell.tscn` at current position. Two scenes, two scripts.
- **KoopaShell** is the kickable shell. Has its own `Hitbox` (layer=Enemy mask=Player), its own `Walker` (kicked = `Direction` set, fast Speed; stationary = `Speed = 0`).
- **Projectiles are not enemies** — see Projectile structure below.

---

## Block structure

Three block types — same scene shape, different reactions to a head-bump from below.

| Block | Reaction |
|---|---|
| `BrickBlock` | Small Mario → bump + SFX; Big/Fire Mario → destroy + score |
| `QuestionBlock` | First bump → bump + coin score + swap sprite to "used"; subsequent bumps → ignored |
| `UsedBlock` | None (no `IBumpable`) — pre-placeable terrain |

`QuestionBlock` only gives coins (mirror MonoGame). Mushrooms / Stars / 1-Ups are placed directly in levels, **not inside blocks**. `UsedBlock` is a separate placeable entity, not a runtime conversion from QuestionBlock — QuestionBlock changes its own sprite in place when emptied.

### Canonical scene (BrickBlock)

```
brick_block.tscn (root: StaticBody2D, script: BrickBlock.cs)
├── Sprite2D                                  # brick visual
├── CollisionShape2D                          # layer=Environment
└── Bumpable (Node, script: Bumpable.cs)      # [Export] _visual = Sprite2D
```

### BrickBlock script (entire file)

```csharp
public partial class BrickBlock : StaticBody2D, IBumpable {
    [Export] private Bumpable _bumpable;

    public void OnBumped(PlayerController player) {
        if (player.CanBreakBricks) {
            GameManager.Instance.State.AddScore(Constants.BrickBreakScore);
            SfxManager.Instance.Play(/* brick break SFX */);
            QueueFree();
            return;
        }
        _bumpable.Bump();
        SfxManager.Instance.Play(/* block hit SFX */);
    }
}
```

QuestionBlock: same structure + `[Export] Texture2D _usedTexture`, `[Export] Sprite2D _sprite`, `bool _used`. First bump: swap sprite to `_usedTexture`, add coin score, play SFX, run `_bumpable.Bump()`. Subsequent bumps: ignored.

UsedBlock: `StaticBody2D` + `Sprite2D` + `CollisionShape2D`. No script logic needed; a near-empty script is fine for type-naming.

### Detection: player owns it

Block-bump detection lives on the player. Iterate `GetSlideCollisionCount()` after `MoveAndSlide` and check normal direction (`Normal.Y > 0.9` → hit head). Dispatched directly to `IBumpable.OnBumped`.

**Consistency note**: this inverts the "attacker scans for defender" rule used for enemies. The general rule: **whoever holds the contextual data owns the detection**. Enemies hold stomp/star/damage dispatch logic; they own. Block-bumps only need player velocity/collision normal; player owns.

---

## Pickup structure

Five types splitting into two structural shapes.

### Static pickups (no body)

| Pickup | Effect |
|---|---|
| `Coin` | `GameManager.Instance.State.AddScore(200)` |

Scene:

```
coin.tscn (root: Area2D, script: Coin.cs)
├── Sprite2D
└── CollisionShape2D                  # layer=PickupTrigger, mask=Player
```

`Coin.cs`: connect `BodyEntered`, on player → `_collected` guard, add score, play SFX, optionally spawn `ScorePopup`, `QueueFree`.

### Dynamic pickups (with body)

| Pickup | Movement | Effect |
|---|---|---|
| `Mushroom` | Walk, no cliff-turn | `player.ApplyMushroom()` + score |
| `FireFlower` | Stationary | `player.ApplyFireFlower()` + score |
| `OneUp` | Walk like Mushroom | `GameState.Lives++` (no score) |
| `Starman` | Walk + bounce on landing | `player.ApplyStarman()` + score |

Scene (Mushroom):

```
mushroom.tscn (root: CharacterBody2D, script: Mushroom.cs)
├── Sprite2D
├── CollisionShape2D                    # body, layer=PickupBody, mask=Environment
├── Walker (Node)                       # [Export] _body=parent, Speed=80, TurnAtCliffs=false
└── PickupTrigger (Area2D)              # layer=PickupTrigger, mask=Player
    └── CollisionShape2D
```

FireFlower omits `Walker` (stationary). Starman uses `Walker` with `BounceForce = Constants.StarmanBounceForce`.

### Mushroom script (entire file)

```csharp
public partial class Mushroom : CharacterBody2D {
    [Export] private Area2D _pickupTrigger;
    private bool _collected;

    public override void _Ready() => _pickupTrigger.BodyEntered += OnPickedUp;

    private void OnPickedUp(Node2D body) {
        if (_collected || body is not PlayerController player) return;
        _collected = true;
        GameManager.Instance.State.AddScore(Constants.MushroomScore);
        SfxManager.Instance.Play(/* pickup SFX */);
        player.ApplyMushroom();
        QueueFree();
    }
}
```

Same shape per dynamic pickup; only the body of `OnPickedUp` differs.

No reusable `PickupTrigger` component — dispatch is per-pickup-type, so a generic wrapper would just be re-wiring.

### Authoring rules

- One `.tscn` + one `.cs` per pickup.
- Static: `Area2D` root. Dynamic: `CharacterBody2D` + child `Area2D` trigger + (optional) child `Walker`.
- `PickupBody` and `PickupTrigger` are distinct layers — preserves Mario-walks-through invariant.
- Effects: `GameManager.Instance.State.X` for pure state, `player.ApplyX()` for player state.

---

## Projectile structure

Three types — one player-fired, two enemy-fired. **None placed in the level editor**; all spawned at runtime by their spawner.

| Projectile | Spawner | Body layer | HitArea layer | HitArea mask |
|---|---|---|---|---|
| `Fireball` | `PlayerController` | `Projectile` | `Projectile` | `Enemy` |
| `Hammer` | `HammerBro` | `EnemyProjectile` | `EnemyProjectile` | `Player` |
| `BulletBill` | `BulletBillCannon` | `EnemyProjectile` | `EnemyProjectile` | `Player` |

### Canonical scene (Fireball)

```
fireball.tscn (root: CharacterBody2D, script: Fireball.cs)
├── Sprite2D
├── CollisionShape2D                          # body, mask=Environment
├── HitArea (Area2D)                          # mask = target layer (Enemy or Player)
│   └── CollisionShape2D
└── Lifetime (Node, script: Lifetime.cs)      # [Export] Duration = Constants.FireballLifetime
```

### Fireball script (interesting parts)

```csharp
public partial class Fireball : CharacterBody2D {
    [Export] private Area2D _hitArea;
    private PlayerController _owner;
    private int _facing;
    private bool _destroyed;

    public void Init(Vector2 pos, int facing, PlayerController owner) {
        GlobalPosition = pos; _facing = facing; _owner = owner;
    }

    public override void _Ready() => _hitArea.BodyEntered += OnHit;

    public override void _PhysicsProcess(double delta) {
        Velocity = new Vector2(_facing * Speed, Velocity.Y + Gravity * (float)delta);
        if (Velocity.Y > MaxFallSpeed) Velocity = new Vector2(Velocity.X, MaxFallSpeed);
        MoveAndSlide();
        for (int i = 0; i < GetSlideCollisionCount(); i++) {
            var col = GetSlideCollision(i);
            if (col.GetNormal().Y < -0.9f) Velocity = new Vector2(Velocity.X, BounceForce);
            else if (Mathf.Abs(col.GetNormal().X) > 0.9f) { Destroy(true); return; }
        }
    }

    private void OnHit(Node2D body) {
        if (_destroyed || body is not IFireballHittable t) return;
        switch (t.OnHitByFireball()) {
            case FireballReaction.Defeated: SfxManager.Instance.Play(/*hit enemy*/); Destroy(false); break;
            case FireballReaction.Blocked:  Destroy(true); break;
        }
    }

    private void Destroy(bool playHitSfx) {
        if (_destroyed) return;
        _destroyed = true;
        if (playHitSfx) SfxManager.Instance.Play(/*block hit*/);
        _owner?.NotifyFireballDestroyed();
        QueueFree();
    }

    public override void _ExitTree() {
        if (!_destroyed) { _destroyed = true; _owner?.NotifyFireballDestroyed(); }
    }
}
```

`Speed`, `Gravity`, `MaxFallSpeed`, `BounceForce` are file-local constants (mirror MonoGame's `Fireball.cs` values).

`Hammer` is simpler (single arc — initial up-velocity + gravity, no bounce). `BulletBill` is simplest (constant horizontal velocity, no gravity, no Lifetime termination needed beyond cleanup — but Lifetime is still useful for ones that fly offscreen).

### Spawning: parented to `GameManager.Instance.CurrentLevel`

Three rules:
1. Not on the player (player can die before projectile expires).
2. Not via `GetParent()` (forbidden).
3. Freed with the level (belongs in the level subtree).

Solution: `GameManager.Instance.CurrentLevel.AddChild(projectile)`. Same pattern from Player (fireball), HammerBro (hammer), BulletBillCannon (bullet bill).

### Owner back-reference (Fireball only)

Player caps `_activeFireballs` at `Constants.MaxFireballs = 2`. Fireball calls `_owner?.NotifyFireballDestroyed()` on destroy to decrement. `?.` guards player death before fireball expires; `_ExitTree` ensures the callback also fires when the level is freed (and the fireball with it) before destroy runs.

Hammer and BulletBill don't track counts — no back-reference needed.

### Authoring rules

- One `.tscn` + one `.cs` per projectile type.
- Root: `CharacterBody2D`. Child: `Sprite2D`, `CollisionShape2D`, `HitArea: Area2D` + its shape, `Lifetime`.
- Spawned via the spawner's `[Export] PackedScene` + `GameManager.Instance.CurrentLevel.AddChild(...)`.
- `Init(...)` method on the projectile sets position, direction, owner — called between `Instantiate` and `AddChild`.

---

## Full level lifecycle

```
GameManager._Ready()
  → load campaign.tres
  → LoadMainMenu()

[user presses Start]
  → MainMenuController emits StartPressed
  → GameManager.StartGame():
	   State = new GameState()
	   _currentLevelIndex = 0
	   LoadLevel(Campaign.Levels[0])

GameManager.LoadLevel(def):
  → free old child of LevelRoot (if any)
  → level = def.LevelScene.Instantiate<LevelBase>()
  → level.LevelCompleted += () => OnLevelCompleted(def)
  → level.PlayerDied     += () => OnPlayerDied(def)
  → LevelRoot.AddChild(level)
  → CurrentLevel = level

LevelBase._Ready():
  → MusicManager.Play(Config.MusicTrack)            // idempotent on same track
  → instantiate player at PlayerStart, AddChild
  → player.Died → emit PlayerDied
  → GoalTrigger.Reached → emit LevelCompleted
  → instantiate HUD, bind to Config + GameState, AddChild

[player walks into KillVolume / takes lethal damage]:
  → PlayerController emits Died
  → LevelBase emits PlayerDied
  → GameManager.OnPlayerDied(def):
	   State.PowerState = Small
	   State.Lives--
	   if Lives <= 0: LoadGameOver()
	   else: LoadLevel(def)                          // fresh level, fresh player
  → MusicManager.Play(def.MusicTrack) → no-op (same track)

[player touches GoalTrigger]:
  → GoalTrigger emits Reached
  → LevelBase emits LevelCompleted
  → GameManager.OnLevelCompleted(def):
	   _currentLevelIndex++
	   if index >= Levels.Length: LoadGameOver()
	   else: LoadLevel(Campaign.Levels[_currentLevelIndex])
```

The level scene is the **unit of teardown**. Freeing it cascades cleanup to player, HUD, enemies, pickups, projectiles, signal connections. No manual `QueueFree` of level internals.

---

## Visuals

Real sprites via `Sprite2D` / `AnimatedSprite2D`. Diverges from MonoGame's `PrototypeSpriteRenderer` (colored boxes). Sprite assets are **sourced separately** (see Open items). During early phases (1–4), placeholder `ColorRect` children are acceptable to unblock gameplay implementation; swap to real sprites in Phase 9.

Drop the existing `PlayerDrawer` / `_Draw()` pattern entirely.

---

## Migration phases

Each phase ends with `dotnet build` clean (0 warnings, 0 errors) **and** `godot --headless --path . --quit` clean **and** the listed manual validation.

### Phase 1 — Strip and skeleton

Delete: `Scripts/Autoloads/` (existing 5), `Scripts/Config/`, `Scripts/Level/`, `Scripts/Player/`, `Scripts/Ui/`, `Scripts/Visual/`, `scenes/main.tscn`, `scenes/player.tscn`. Keep `project.godot` (update autoload registrations), `icon.svg`, input map.

Create: `Scripts/Constants.cs` (layers + all gameplay constants), `Scripts/Autoloads/{GameManager,MusicManager,SfxManager}.cs` (stub implementations — Instance setter, no methods yet). Update `project.godot` autoload list. Set up 8 named physics layers in Project Settings.

Validation: build clean; headless validation clean; running the game shows a blank window without errors.

### Phase 2 — Resources + scene flow

Create: `Scripts/Resources/{LevelDefinition,Campaign}.cs`. Create three placeholder `.tres` files (one per level) with `Name` set; `LevelScene` can point to empty stub scenes. Create `resources/campaign.tres` with all three.

Create: empty `scenes/main_menu.tscn` (with a button that emits `StartPressed`), empty `scenes/game_over.tscn` (button emits `Continue`), empty `scenes/levels/world_X_Y.tscn` stubs.

Implement: `GameManager.LoadMainMenu` / `StartGame` / `LoadLevel` / `OnLevelCompleted` / `OnPlayerDied` / `LoadGameOver`. `GameState` class with Score/Lives/PowerState + events.

Validation: pressing Start in the main menu loads world 1-1's empty scene. From there, manually emitting `PlayerDied` reloads or game-overs at 3 deaths. Manually emitting `LevelCompleted` advances. HUD not yet present — verify scene swap by logging.

### Phase 3 — LevelBase + HUD + first entity

Create: `Scripts/Level/LevelBase.cs`, `scenes/level_base.tscn` (with `PlayerStart`, `CleanupVolume`, `GoalTrigger` placeholders). Each `world_X_Y.tscn` inherits from `level_base.tscn` and assigns its `Config`. Create `scenes/hud.tscn` + `Scripts/Ui/Hud.cs`.

Create: `Scripts/Components/Lifetime.cs` (used in Phase 8 but cheap to define now). `Scripts/Level/{GoalTrigger,KillVolume,CleanupVolume}.cs`. `Scripts/Entities/Platform.cs` + `scenes/entities/platform.tscn` (basic `StaticBody2D` + `Sprite2D` placeholder + collision).

Validation: each level loads via `GameManager`, music plays (idempotent), HUD shows level name + score 0 + lives 3 + timer counting. A test platform supports a placeholder rectangle to prove `Environment` layer works. Manually walking a stub through `GoalTrigger`/`KillVolume` triggers the expected signals.

### Phase 4 — Player

Create: `scenes/player.tscn`, `Scripts/Player/{PlayerController,PlayerPowerState,Blinker}.cs`. Wire `_playerScene` on `level_base.tscn`.

Player implements: input (move/jump/run/crouch/fire), gravity, ground detection, jump physics, power-state visuals (placeholder colored rects per state), `TakeDamage` / `KillPlayer` / `ApplyMushroom` / `ApplyFireFlower` / `ApplyStarman` / `NotifyFireballDestroyed` stubs, head-bump detection (forwards to `IBumpable.OnBumped` — no concrete bumpables yet), invuln timer with `Blinker`.

Player joins `"player"` group on `_Ready`. Player emits `Died` on `KillPlayer`. `LevelBase` re-emits `PlayerDied`.

Validation: player spawns at `PlayerStart`, walks/jumps, falls into `KillVolume` → dies → level reloads. Out of lives → game over. Camera follows.

### Phase 5 — Static world + blocks

Create: `Scripts/Interfaces/IBumpable.cs`. `Scripts/Components/Bumpable.cs`. `Scripts/Entities/{BrickBlock,QuestionBlock,UsedBlock,MovingPlatform}.cs` + matching `.tscn`s. `Scripts/Enums/MovingPlatformAxis.cs`. Wire player head-bump detection to dispatch `IBumpable.OnBumped`.

Validation: bump bricks (Small bumps, Big breaks), bump question blocks (give coin once, then inert), used blocks just sit there, moving platforms ride correctly with `AnimatableBody2D` semantics if needed.

### Phase 6 — Pickups

Create: `Scripts/Components/Walker.cs` (needed for dynamic pickups; also reusable for enemies in Phase 7). `Scripts/Entities/{Coin,Mushroom,FireFlower,OneUp,Starman}.cs` + `.tscn`s.

Confirm: `PickupBody` and `PickupTrigger` layer split — Mario walks through, still triggers. Test by placing a Mushroom on a platform and walking past/over it.

Validation: collect coin → score += 200. Pick up mushroom → Small → Big. Pick up FireFlower → Fire. Pick up 1-Up → Lives += 1. Pick up Starman → invuln timer running, enemy contact resolves harmlessly (won't be visible until Phase 7; verify via debug log).

### Phase 7 — Enemies (combat)

Create: `Scripts/Interfaces/{IStompable,IFireballHittable,IStarHittable}.cs`. `Scripts/Components/Hitbox.cs`. `Scripts/Enums/KoopaColor.cs`. Enemies: `Goomba`, `KoopaTroopa`, `KoopaShell`, `KoopaParatroopa`, `BuzzyBeetle`, `Spiny` + `.tscn`s.

Implement per-enemy interface combinations per the per-enemy interface set table. Star-invincibility now visibly works.

Validation: stomp Goomba → defeated; walk into → take damage; stomp BuzzyBeetle → defeated, fireball does nothing; stomp Spiny → take damage (not stompable); KoopaTroopa stomp → shell appears, kick shell → travels and defeats other enemies; star-invincible player defeats all on contact.

### Phase 8 — Projectile and ranged enemies

Implement player fireball spawning (Phase 4 had stubs). Create: `Scripts/Entities/{Fireball,Hammer,BulletBill,PiranhaPlant,HammerBro,Blooper,BulletBillCannon,Podoboo}.cs` + `.tscn`s. Confirm `GameManager.CurrentLevel` property is wired (should be from Phase 2 — verify here).

Validation: Fire Mario shoots fireballs; bouncing terrain physics correct; max 2 active fireballs; fireballs defeat hittable enemies / are blocked by others. PiranhaPlant suppresses when player is near its pipe. HammerBro throws hammers in arcs. BulletBillCannon fires periodic BulletBills.

### Phase 9 — Polish

- Real sprite assets swapped in (or kept as placeholders, depending on whether art is sourced).
- SFX wired comprehensively (jump, pickups, stomp, brick break, fireball, etc.).
- `ScorePopup` floating "+200" text on score events.
- Level-complete animation (flagpole slide).
- Death pause (~2s before reload).
- HUD timer time-out → kill player.
- Fade transitions between scenes (optional — `GameManager` already swaps cleanly without).

Validation: full World 1-1 → 1-2 → 1-3 playthrough completes the campaign with all systems functioning.

---

## Open items

These aren't blockers for implementation but are not specified by this plan:

1. **Sprite assets.** No sprite source is committed. Decisions: NES Mario rips, AI-generated, custom-drawn? Resolve before Phase 9 (or by the end of Phase 4 if placeholder rectangles become limiting).
2. **Audio assets.** Existing MonoGame project has all `.ogg` files in `c:\dev\games-monogame\SuperMario\Content\Music` and `\Sfx`. Copy these into `music/` and `sfx/` in this repo (OGG works in Godot for both — no WAV conversion needed). License/source unchanged.
3. **Time-out kills player.** Phase 9 polish; behavior is unspecified — display behavior (hurry-up music change at 100 remaining?) and exact time-out animation aren't planned here.
4. **Multi-coin brick block.** Original Mario has bricks that yield multiple coins on repeated bumps within a window. Not in MonoGame, not in this plan. If desired, extend `BrickBlock` with a coin-count export + timer.
5. **Power-up question blocks.** Original Mario: some `?` blocks contain mushrooms/flowers. MonoGame doesn't model this — power-ups are placed directly in levels. Plan mirrors MonoGame. If desired, extend `QuestionBlock` with `[Export] PackedScene Contents`.
6. **Pipes / underground warps.** Not in the current MonoGame entity set. Out of scope.

---

## Cheat sheet for the implementer

- **Constants**: mirror `c:\dev\games-monogame\SuperMario\Source\Constants.cs` value-for-value. Don't tune.
- **Reference enemy/block/pickup/projectile source files**: under `c:\dev\games-monogame\SuperMario\Source\Components\` — read the MonoGame version before implementing the Godot port. Many behaviors (e.g., Starman bounce + direction-flip-on-wall) are in there in detail.
- **Forbidden**: `GetParent()`, `GetNode("../...")`, base classes for enemies/pickups/projectiles, EntityFactory-style registries, persistent player across levels, autoload-owned scene transitions other than `GameManager`.
- **Required group memberships**: player joins `"player"` on `_Ready`. Nothing else uses groups in v1.
- **Allowed autoload access**: `GameManager.Instance`, `MusicManager.Instance`, `SfxManager.Instance` directly from any node.
- **All `.tscn` filenames are `snake_case.tscn`. All `.cs` filenames are `PascalCase.cs`.**
