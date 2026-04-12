# SPEC.md - Super Mario Bros (Godot 4.6 / C#)

## 0. Purpose

This document defines the target design for a 2D Super Mario Bros inspired game built in Godot 4.6 with C#.

Project pillars:
- Primitive-shape visuals only. No spritesheets or texture-based characters.
- Tight, readable platforming that feels close to classic SMB.
- Modern polish through particles, glow, screen shake, transitions, and clean architecture.
- Audio-ready structure even if placeholder or empty assets are used at first.

Out of scope for v1:
- Online play
- Save files
- Level editor tooling
- Sprite art pipelines
- Mobile-specific controls

---

## 1. Project Configuration

### 1.1 Display

| Setting | Value |
|---------|-------|
| Viewport | 512 x 448 |
| Window | 1024 x 896 |
| Scale | 2x default window scale |
| Stretch mode | `canvas_items` |
| Stretch aspect | `keep` |
| Tile grid | 16 x 16 px |

This gives 32 x 28 visible tiles, which preserves the feel of the original 256 x 224 NES framing while giving a slightly larger modern workspace.

### 1.2 Renderer

Use `Forward Plus`.

Reason:
- Needed for `WorldEnvironment` glow/bloom on the 2D canvas.
- Performance cost is acceptable for this scope.
- The game is small enough that post-processing quality is more valuable than renderer simplicity.

### 1.3 Physics

The current project enables `Jolt Physics` for 3D. That does not affect 2D gameplay. All gameplay in this project is 2D and should rely on Godot's normal 2D physics.

No physics setting change is required for v1.

### 1.4 Input Map

Custom actions to define:

| Action | Keyboard | Gamepad |
|--------|----------|---------|
| `move_left` | `A`, Left Arrow | D-pad Left, Left Stick Left |
| `move_right` | `D`, Right Arrow | D-pad Right, Left Stick Right |
| `jump` | Space, `W`, Up Arrow | South button (`A` on Xbox, `Cross` on PlayStation) |
| `run` | Left Shift, `J` | West button (`X` on Xbox, `Square` on PlayStation) |
| `crouch` | `S`, Down Arrow | D-pad Down, Left Stick Down |
| `pause` | Escape, `P` | Start/Menu |

Notes:
- Do not remove Godot's default `ui_*` actions unless they conflict with menus.
- Fireball shooting uses `run` on `just_pressed`, so holding run to sprint still works.

### 1.5 Main Scene

Set `res://scenes/main.tscn` as the main scene once the real project structure exists.

`main.tscn` responsibilities:
- Own the top-level gameplay shell (see §4.1 for full hierarchy)
- Host persistent nodes: Player, HUD, WorldEnvironment, overlay layers
- Load the title screen first

---

## 2. Repository Layout

Target layout:

```text
res://
  scenes/
    main.tscn
    ui/
      title_screen.tscn
      hud.tscn
      game_over.tscn
      pause_menu.tscn
      level_complete.tscn
      level_intro.tscn
    levels/
      world_1_1.tscn
    player/
      player.tscn
    enemies/
      goomba.tscn
      koopa.tscn
      koopa_shell.tscn
      piranha_plant.tscn
    objects/
      brick_block.tscn
      question_block.tscn
      hidden_block.tscn
      coin.tscn
      mushroom.tscn
      fire_flower.tscn
      starman.tscn
      fireball.tscn
      flagpole.tscn
      pipe.tscn
      castle.tscn
    effects/
      coin_pop.tscn
      brick_break.tscn
      stomp_effect.tscn
      death_effect.tscn
      power_up_effect.tscn
      score_popup.tscn
      firework.tscn

  Scripts/
    Autoloads/
      EventBus.cs
      GameManager.cs
      AudioManager.cs
      SceneManager.cs
      CameraEffects.cs
    Player/
      PlayerController.cs
      PlayerDrawer.cs
      StateMachine.cs
      PlayerStates/
        PlayerState.cs
        IdleState.cs
        RunState.cs
        JumpState.cs
        FallState.cs
        CrouchState.cs
        DeathState.cs
        GrowState.cs
        ShrinkState.cs
        PipeEnterState.cs
        FlagpoleState.cs
    Enemies/
      EnemyBase.cs
      Goomba.cs
      Koopa.cs
      KoopaShell.cs
      PiranhaPlant.cs
    Objects/
      BrickBlock.cs
      QuestionBlock.cs
      HiddenBlock.cs
      Coin.cs
      PowerUpBase.cs
      Mushroom.cs
      FireFlower.cs
      Starman.cs
      Fireball.cs
      Flagpole.cs
      Pipe.cs
      Castle.cs
    Ui/
      Hud.cs
      TitleScreen.cs
      GameOver.cs
      PauseMenu.cs
      LevelComplete.cs
      LevelIntro.cs
    Level/
      LevelBase.cs
      EnemySpawner.cs
      KillZone.cs
      ParallaxController.cs
    Config/
      LevelConfig.cs
      PlayerMovementConfig.cs
      CameraConfig.cs
      EnemyConfig.cs
      BlockBumpConfig.cs
      ItemConfig.cs
      LevelTimingConfig.cs
      EffectsConfig.cs

  shaders/
    glow_pulse.gdshader
    star_power.gdshader
    background_gradient.gdshader
    damage_flash.gdshader
    outline.gdshader

  audio/
    music/
    sfx/

  resources/
    color_palette.tres
    default_bus_layout.tres
    hud_label_settings.tres
    config/
      level_1_1.tres
      level_1_2.tres
      player_movement_default.tres
      camera_default.tres
```

Notes:
- `NewScript.cs` is a temporary placeholder and should be removed or replaced once the real scene structure is created.
- Generated files under `.godot/`, `*.uid`, and `*.import` should not be hand-edited.

---

## 3. Autoloads

Register these singletons in `project.godot`:

```text
EventBus      = "*res://Scripts/Autoloads/EventBus.cs"
GameManager   = "*res://Scripts/Autoloads/GameManager.cs"
AudioManager  = "*res://Scripts/Autoloads/AudioManager.cs"
SceneManager  = "*res://Scripts/Autoloads/SceneManager.cs"
CameraEffects = "*res://Scripts/Autoloads/CameraEffects.cs"
```

All autoloads should inherit from `Node`.

### 3.1 EventBus

Central signal hub for cross-system communication. Systems should prefer signals over hard references when the interaction is not local and obvious.

Required signals:

```csharp
// Player
[Signal] public delegate void PlayerDiedEventHandler();
[Signal] public delegate void PlayerRespawnedEventHandler();
[Signal] public delegate void PlayerPoweredUpEventHandler(StringName powerUpType);
[Signal] public delegate void PlayerPowerStateChangedEventHandler(int oldState, int newState);
[Signal] public delegate void PlayerDamagedEventHandler();
[Signal] public delegate void PlayerStarPowerStartedEventHandler();
[Signal] public delegate void PlayerStarPowerEndedEventHandler();

// Scoring and HUD
[Signal] public delegate void CoinCollectedEventHandler(Vector2 position);
[Signal] public delegate void ScoreAwardedEventHandler(int points, Vector2 position);
[Signal] public delegate void ScoreChangedEventHandler(int newScore);
[Signal] public delegate void LivesChangedEventHandler(int newLives);
[Signal] public delegate void CoinsChangedEventHandler(int newCoinCount);
[Signal] public delegate void TimeTickEventHandler(int timeRemaining);
[Signal] public delegate void OneUpEarnedEventHandler();

// Level
[Signal] public delegate void LevelStartedEventHandler(int world, int level);
[Signal] public delegate void LevelCompletedEventHandler();
[Signal] public delegate void FlagpoleReachedEventHandler(float heightRatio);

// Enemies
[Signal] public delegate void EnemyStompedEventHandler(Vector2 position);
[Signal] public delegate void EnemyKilledEventHandler(Vector2 position, StringName enemyType);
[Signal] public delegate void ComboStompEventHandler(int count, Vector2 position);

// Blocks and items
[Signal] public delegate void BlockBumpedEventHandler(Vector2 position);
[Signal] public delegate void BlockBrokenEventHandler(Vector2 position);
[Signal] public delegate void ItemSpawnedEventHandler(StringName itemType, Vector2 position);

// Game state
[Signal] public delegate void GamePausedEventHandler();
[Signal] public delegate void GameResumedEventHandler();
[Signal] public delegate void GameOverEventHandler();
```

### 3.2 GameManager

Tracks persistent game state across scene loads.

State fields:
- `Score: int = 0`
- `Coins: int = 0`
- `Lives: int = 3`
- `TimeRemaining: float = 400.0f`
- `CurrentWorld: int = 1`
- `CurrentLevel: int = 1`
- `CurrentPowerState: PowerState = PowerState.Small`
- `CurrentGameState: GameState = GameState.Title`

Enums:

```csharp
public enum PowerState { Small, Big, Fire }
public enum GameState { Title, Playing, Paused, GameOver, LevelComplete, Transitioning }
```

State flow:

```text
Title -> Playing
Playing <-> Paused
Playing -> LevelComplete -> Transitioning -> Playing
Playing -> GameOver
GameOver -> Title
```

Responsibilities:
- Score, coin, and life tracking
- Coin-to-1UP conversion every 100 coins
- Countdown timer while in `Playing`
- Death and respawn orchestration
- Time bonus payout at level end (`TimeRemaining * 50`)
- Resetting per-run state on new game start

Timer lifecycle:
- `TimeRemaining` resets to the level's `LevelConfig.TimeLimit` (see §11.0)
  at the start of **every level**, not just on new game. The reset happens
  when `SceneManager` reads the loaded level's config, before `LevelStarted`
  fires.
- Timer pauses during `Paused`, death animation, grow/shrink animation,
  and the `LevelComplete` bonus tally.
- Reaching zero triggers player death (same as falling into a pit).

Add these helper methods:
- `public void StartNewGame()`
- `public void StartLevel(LevelConfig config)` — called by SceneManager on level load; resets `TimeRemaining` to `config.TimeLimit`, updates `CurrentWorld`/`CurrentLevel`, emits `LevelStarted`
- `public void AddScore(int points, Vector2 position = default)`
- `public void AddCoin(Vector2 position = default)`
- `public void LoseLife()`
- `public void SetPowerState(PowerState state)`
- `public void SetGameState(GameState state)`

### 3.3 AudioManager

This should work even before real assets are added.

Bus layout target:

```text
Master
  Music
  SFX
    Player
    Enemies
    Items
  UI
```

Registry pattern:

```csharp
private Dictionary<StringName, string> _sfxRegistry = new()
{
    { "jump", "" },
    { "jump_big", "" },
    { "stomp", "" },
    { "coin", "" },
    { "block_bump", "" },
    { "block_break", "" },
    { "powerup", "" },
    { "powerdown", "" },
    { "fireball", "" },
    { "kick", "" },
    { "pipe", "" },
    { "1up", "" },
    { "death", "" },
    { "flagpole", "" },
    { "game_over", "" },
    { "stage_clear", "" },
    { "warning", "" },
};

private Dictionary<StringName, string> _musicRegistry = new()
{
    { "overworld", "" },
    { "underground", "" },
    { "star", "" },
    { "hurry", "" },
};
```

Rules:
- Empty paths should safely no-op.
- Use two `AudioStreamPlayer` nodes for music crossfades.
- Use pooled `AudioStreamPlayer` and `AudioStreamPlayer2D` nodes for concurrent SFX.

Recommended pool sizes:
- 10 non-positional SFX players
- 6 positional SFX players

Key methods:
- `public void PlaySfx(StringName soundName, Vector2 position = default)`
- `public void PlayMusic(StringName musicName)`
- `public void StopMusic()`
- `public void SetMusicDucked(bool enabled)`

### 3.4 SceneManager

Handles scene transitions and common overlays.

Responsibilities:
- Fade-out, load, fade-in
- Reload current gameplay scene
- Show level intro overlay
- Avoid duplicate transitions while one is already running

Transition shell:
- `CanvasLayer` at a high layer
- Full-screen `ColorRect`
- Optional centered text label for world/level intro

Key methods:
- `public void ChangeScene(string path)`
- `public void ReloadCurrentScene()`
- `public void ShowLevelIntro(int world, int level, int lives)`

### 3.5 CameraEffects

Controls temporary effects on the active `Camera2D`.

Methods:
- `public void Shake(float intensity, float duration)`
- `public void FreezeFrame(float duration)`

Recommended shake presets:

| Event | Intensity | Duration |
|-------|-----------|----------|
| Enemy stomp | 2.0 | 0.10s |
| Brick break | 4.0 | 0.15s |
| Player death | 6.0 | 0.30s |

Implementation note:
- `FreezeFrame()` should be very short and must not break timers or long tweens. Use a tiny `Engine.TimeScale` dip or a controlled local pause rather than freezing the whole app indiscriminately.

---

## 4. Core Scenes

### 4.1 Main Scene

`main.tscn` is the persistent shell. It is never unloaded. Level scenes
are loaded into `SceneRoot` and swapped by `SceneManager`.

Suggested hierarchy:

```text
Main (Node)
  SceneRoot (Node)           [level scenes load here]
  Player (CharacterBody2D)   [persistent, repositioned on level load]
  HUD (CanvasLayer)          [persistent across levels]
  OverlayRoot (CanvasLayer)  [transition fades, level intro]
  WorldEnvironment           [persistent, levels can override env settings]
  DebugRoot (Node)           [optional]
```

Ownership rules:
- **Player** lives under `Main`, not inside the level scene. On level load,
  `SceneManager` moves the player to the level's `PlayerSpawn` marker.
  On death/respawn, the player is repositioned without re-instantiation.
- **HUD** lives in a `CanvasLayer` under `Main`. It reads from `GameManager`
  signals and is never torn down during gameplay.
- **WorldEnvironment** lives under `Main` for consistent bloom/glow. A level
  may override environment settings (e.g., underground palette) via a
  script that adjusts the shared `WorldEnvironment` on load and restores
  defaults on unload.
- **Level scenes** contain only level-specific content: terrain, blocks,
  enemies, pipes, spawn markers, kill zones, camera bounds, and
  decorations.

### 4.2 Level Scene Contract

Every gameplay level scene should:
- inherit the same broad structure
- export a `LevelConfig` resource on the root node (see §11.0)
- expose a `PlayerSpawn` marker (`Marker2D`) for player positioning
- define camera bounds
- contain a `KillZone`

### 4.3 UI Scenes

Required UI scenes:
- `title_screen.tscn`
- `hud.tscn`
- `pause_menu.tscn`
- `game_over.tscn`
- `level_intro.tscn`
- `level_complete.tscn`

---

## 5. Visual Style

All visuals use primitive shapes and code-driven drawing:
- `Polygon2D`
- `Line2D`
- `DrawRect()`
- `DrawCircle()`
- `DrawPolygon()`
- `ColorRect`

Rules:
- No sprite textures for characters or gameplay objects
- Keep geometry aligned to the 16 px grid
- Favor bold silhouettes and high contrast over tiny detail

### 5.1 Color Palette

Place these in a static class `P` (short for Palette) so they can be referenced concisely throughout the codebase (e.g., `P.CoinGold`).

```csharp
public static class P
{
// Sky / Background
public static readonly Color SkyBlue        = new Color(0.35f, 0.65f, 0.95f);
public static readonly Color SkyUnderground = new Color(0.05f, 0.05f, 0.08f);
public static readonly Color CloudWhite     = new Color(0.95f, 0.95f, 0.98f);

// Ground / Terrain
public static readonly Color GroundBrown    = new Color(0.55f, 0.35f, 0.15f);
public static readonly Color GroundGreen    = new Color(0.25f, 0.65f, 0.25f);
public static readonly Color BrickRed       = new Color(0.72f, 0.30f, 0.18f);
public static readonly Color BrickDark      = new Color(0.55f, 0.22f, 0.12f);

// Mario
public static readonly Color MarioRed       = new Color(0.90f, 0.15f, 0.15f);
public static readonly Color MarioSkin      = new Color(0.95f, 0.75f, 0.55f);
public static readonly Color MarioBlue      = new Color(0.20f, 0.30f, 0.75f);
public static readonly Color MarioFireWhite = new Color(0.95f, 0.95f, 0.95f);

// Enemies
public static readonly Color GoombaBrown    = new Color(0.55f, 0.30f, 0.15f);
public static readonly Color GoombaDark     = new Color(0.35f, 0.18f, 0.08f);
public static readonly Color KoopaGreen     = new Color(0.20f, 0.70f, 0.25f);
public static readonly Color KoopaShell     = new Color(0.15f, 0.55f, 0.20f);
public static readonly Color PiranhaGreen   = new Color(0.15f, 0.60f, 0.15f);
public static readonly Color PiranhaRed     = new Color(0.80f, 0.15f, 0.12f);

// Objects
public static readonly Color PipeGreen      = new Color(0.18f, 0.60f, 0.22f);
public static readonly Color PipeGreenLight = new Color(0.28f, 0.72f, 0.32f);
public static readonly Color QuestionYellow = new Color(0.95f, 0.80f, 0.20f);
public static readonly Color QuestionDark   = new Color(0.70f, 0.55f, 0.10f);
public static readonly Color CoinGold       = new Color(1.00f, 0.85f, 0.20f);
public static readonly Color CoinShine      = new Color(1.00f, 0.95f, 0.60f);
public static readonly Color BlockBrown     = new Color(0.50f, 0.35f, 0.20f);
public static readonly Color StarYellow     = new Color(1.00f, 0.90f, 0.15f);
public static readonly Color FireOrange     = new Color(1.00f, 0.55f, 0.10f);
public static readonly Color FireRed        = new Color(1.00f, 0.25f, 0.10f);
public static readonly Color MushroomRed    = new Color(0.90f, 0.15f, 0.15f);
public static readonly Color MushroomCream  = new Color(0.95f, 0.90f, 0.80f);
}
```

### 5.2 Character and Object Rendering

All main characters should render through a dedicated `Node2D` drawer child using `_Draw()`. That keeps gameplay logic separate from visual construction and makes palette swaps easier.

Mario:
- Small Mario footprint: 16 x 16
- Big Mario footprint: 16 x 32
- Draw facing right by default
- Flip via parent `Visuals.Scale` (set `X` to `-1` or `1`)
- Fire form swaps the red/white palette while keeping the same silhouette

Goomba:
- 16 x 16 footprint
- Rounded trapezoid body
- Foot rectangles alternate for walk animation
- Death squish uses scale or vertex squash

Koopa:
- 16 x 24 footprint
- Oval shell plus simple head/feet shapes

Pipe:
- Width 32
- Height varies by level
- Use a lighter highlight stripe and darker opening shadow

Question block:
- 16 x 16
- Animated "?" or procedural glyph
- Distinct empty state after use

Ground tiles:
- Only terrain uses `TileMapLayer`
- Use simple generated or single-color tile assets as a base
- Interactive blocks remain scene instances, not tiles

### 5.3 Shaders and Effects

Required shaders:
- `glow_pulse.gdshader`
- `star_power.gdshader`
- `background_gradient.gdshader`
- `damage_flash.gdshader`
- `outline.gdshader`

Effect requirements:
- Coins, question blocks, fire, and star effects should benefit from bloom
- Damage flash should be short and readable
- Outline shader is optional per object if plain geometry is already readable

Required particle beats:
- Coin collection pop
- Brick break fragments
- Enemy stomp puff
- Fireball hit burst
- Power-up pickup ring
- End-of-level fireworks

World environment:
- Enable subtle bloom only
- Avoid overblown glow that obscures silhouettes

---

## 6. Player Controller

Player root type: `CharacterBody2D`

### 6.1 Scene Hierarchy

```text
Player (CharacterBody2D)
  CollisionShape2D
  Visuals (Node2D)
    PlayerDrawer (Node2D)
  StateMachine (Node)
    IdleState
    RunState
    JumpState
    FallState
    CrouchState
    DeathState
    GrowState
    ShrinkState
    PipeEnterState
    FlagpoleState
  AnimationPlayer
  CoyoteTimer
  JumpBufferTimer
  InvincibilityTimer
  StarTimer
  FireballCooldown
  Camera2D
  StompDetector (Area2D)
  Hurtbox (Area2D)
```

### 6.2 Physics Constants

```csharp
public const float WalkSpeed       = 130.0f;
public const float RunSpeed        = 210.0f;
public const float Acceleration    = 800.0f;
public const float Deceleration    = 1200.0f;
public const float AirAcceleration = 600.0f;
public const float TurnAcceleration = 1600.0f;
public const float JumpVelocity    = -330.0f;
public const float JumpReleaseMult = 0.5f;
public const float Gravity         = 900.0f;
public const float FastFallGravity = 1400.0f;
public const float MaxFallSpeed    = 500.0f;
public const float CoyoteTime      = 0.08f;
public const float JumpBufferTime  = 0.10f;
```

### 6.3 Core Mechanics

Required movement behavior:
- Variable-height jump
- Ground acceleration and braking
- Reduced air control
- Running speed increase while holding `run`
- Skid turn when reversing direction at speed
- Coyote time
- Jump buffer

Required crouch behavior:
- Only Big and Fire Mario may crouch
- Crouch collision height matches 1 tile height
- If there is not enough overhead clearance, standing back up is blocked
- Small Mario ignores crouch for collision changes

Facing:
- `Visuals.Scale = new Vector2(-1, Visuals.Scale.Y)` when moving left
- `Visuals.Scale = new Vector2(1, Visuals.Scale.Y)` when moving right

### 6.4 State Machine

`StateMachine.cs` should:
- hold `CurrentState: PlayerState`
- delegate input/frame/physics to the active state
- provide `public void TransitionTo(StringName stateName)`

Base state:

```csharp
public partial class PlayerState : Node
{
    public CharacterBody2D Player { get; set; }

    public virtual void Enter() { }
    public virtual void Exit() { }
    public virtual void ProcessInput(InputEvent @event) { }
    public virtual void ProcessFrame(double delta) { }
    public virtual void ProcessPhysics(double delta) { }
}
```

State flow:

```text
Idle -> Run, Jump, Fall, Crouch
Run -> Idle, Jump, Fall
Jump -> Fall
Fall -> Idle, Run, Jump
Crouch -> Idle
Any -> Death
Any -> Grow
Any -> Shrink
Any -> PipeEnter
Any -> Flagpole
```

Pause rule for grow/shrink:
- Freeze active gameplay while the transformation animation runs
- Do not hard-freeze nodes that must continue processing transition/UI-safe logic

### 6.5 Camera

`Camera2D` should be a child of the player.

Rules:
- Horizontal follow only for World 1-1
- Fixed Y position per level
- No backtracking once the player advances
- Slight forward look-ahead based on facing direction
- Gentle smoothing only, not floaty movement

---

## 7. Power-Ups and Damage

```csharp
public enum PowerState { Small, Big, Fire }
```

Authority: `GameManager.CurrentPowerState` is the single source of truth.

- **On spawn / respawn:** the player reads `GameManager.CurrentPowerState`
  in `_Ready()` and sets its collision shape and drawer accordingly.
- **On power-up or damage:** the player's state machine (GrowState,
  ShrinkState) calls `GameManager.SetPowerState()` which updates the
  field, emits `PlayerPowerStateChanged`, and the player reacts to the
  new state. The player never stores its own shadow copy.
- **On death:** `GameManager` resets `CurrentPowerState` to `Small` as
  part of `LoseLife()`, before the respawn cycle begins.
- **On new game:** `StartNewGame()` resets to `Small`.

Rules:
- Small + Mushroom -> Big
- Small + Fire Flower -> Big
- Big + Fire Flower -> Fire
- Big or Fire + damage -> Small
- Small + damage -> death
- Any state + Star -> temporary invincibility

Collision shape:
- Small Mario body: approximately `Vector2(12, 16)`
- Big Mario body: approximately `Vector2(12, 30)`
- Resize while keeping feet planted on the ground

Invincibility rules:
- Damage recovery blink lasts 2.0 seconds
- Star power lasts 10.0 seconds
- Star power kills enemies on body contact

Fireball rules:
- Fire Mario can spawn at most 2 player-owned fireballs at once
- Fireball shoots on `run` `just_pressed`
- Fireball travels horizontally, bounces lightly on ground, and dies on wall/enemy impact

---

## 8. Enemies

### 8.1 Enemy Base

Enemy root type: `CharacterBody2D`

Shared properties:
- `Speed`
- `Gravity = 900.0f`
- `Direction = -1.0f`

Shared behavior:
- Apply gravity
- Move with `MoveAndSlide()`
- Reverse on wall collision
- Optional floor-edge detection for walkers via `RayCast2D` or manual floor probe
- Clean up once permanently off-screen or in a pit

Enemy-vs-enemy behavior:
- Enemies do not physically collide with other enemies
- Layer 3 should not mask itself

### 8.2 Goomba

- Walk speed: 40 px/s
- Reverses on walls and edges
- Stomp: flatten, disable collision, free after delay, award 100 points
- Non-stomp death: flip and fall, award 200 points

### 8.3 Koopa Troopa

- Walk speed: 35 px/s
- Stomp: replace with shell scene, award 100 points
- Non-stomp death: flip and fall, award 200 points

### 8.4 Koopa Shell

States:
- `Idle`
- `Moving`

Rules:
- Idle shell can be kicked into motion
- Moving shell travels at 300 px/s
- Moving shell kills enemies it hits
- Player may stomp a moving shell to stop it
- Side contact from a moving shell damages player

Combo rewards:
- 500
- 800
- 1000
- 2000
- 5000
- 8000
- 1-UP

### 8.5 Piranha Plant

- Tween-based vertical emerge/retract motion
- Does not emerge while the player is standing close to the pipe
- Not stompable
- Vulnerable to fireballs and star contact

### 8.6 Pipe Warp

Pipes may optionally define a warp destination. Because a pipe can target
a location in the same scene (intra-level shortcut) or a different scene
entirely (World 1-2 underground, bonus room), a raw `NodePath` is not
sufficient — it only resolves within the current scene tree. Instead, use
a destination descriptor:

```csharp
/// <summary>
/// If empty, the pipe is non-warp decoration.
/// If set, this is the scene path to load (e.g. "res://scenes/levels/world_1_2.tscn").
/// For same-scene warps, set to the current scene's own path.
/// </summary>
[Export] public string WarpScenePath = "";

/// <summary>
/// Name of the Marker2D at the destination that the player emerges from.
/// Must exist as a child of a Pipe node in the target scene.
/// </summary>
[Export] public string WarpSpawnMarker = "";
```

A warp is valid only when both fields are non-empty and the target scene
contains a `Marker2D` with a matching name.

For same-scene warps, `SceneManager` skips the scene load and just
repositions the player at the target marker after the fade.

Entry rules:
- Player must be on top of the pipe
- Player must hold `crouch`
- Warp only triggers when both `WarpScenePath` and `WarpSpawnMarker` are set

Warp sequence:
1. Enter `PipeEnterState`
2. Disable normal input
3. Tween player down into pipe
4. Play pipe SFX
5. Fade transition
6. If `WarpScenePath` differs from the current scene, load the target scene
   via `SceneManager`; otherwise reposition within the same scene
7. Place player at the `Marker2D` matching `WarpSpawnMarker`
8. Tween player out of the destination pipe
9. Return control

**Z-ordering during the tween**

While sliding into a pipe, Mario must render *behind* the pipe rim (so the
rim visually occludes his head as he descends) but still in front of the
background and terrain. Conversely, while emerging from the destination pipe
he must start hidden behind the rim and end in front of it. The rule:

- The pipe scene's root uses a fixed `ZIndex` (e.g., `5`) that sits above
  terrain and background but below the player's normal `ZIndex` (e.g., `10`).
- On entering `PipeEnterState`, the player's `ZIndex` is dropped to a value
  *below* the pipe's (e.g., `0`) for the duration of the slide-in tween.
- After the fade transition and reposition at the target pipe, the player
  stays at the lowered `ZIndex` during the slide-out tween, then restores
  to its normal `ZIndex` when control returns.
- The pipe's `ZAsRelative = false` so its `ZIndex` is absolute and not
  affected by parent containers.

`PipeEnterState.Enter()` caches the player's previous `ZIndex`, lowers it,
and `PipeEnterState.Exit()` restores the cached value. Do not mutate
`ZIndex` from the pipe script itself — the state owns that lifecycle so
early exits (e.g., death during warp, if that's ever possible) can't leave
the player stuck behind geometry.

**Collision during the tween**

Mario's `CharacterBody2D` is a physics body, and leaving it live during the
tween would fight the pipe's own collision shape: `MoveAndSlide()` would
depenetrate him out of the pipe sideways, and gravity would keep pulling him
against the pipe top. The tween must drive position directly with no physics
interference.

Handling:

- On `PipeEnterState.Enter()`, set the player's `CollisionShape2D.Disabled`
  via `SetDeferred("disabled", true)`. Do **not** toggle
  `CollisionLayer`/`CollisionMask` — disabling the shape is cleaner and
  reverses cleanly on exit.
- Zero `Velocity` and stop calling `ApplyGravity()` / `MoveAndSlide()`
  from the state's `ProcessPhysics()`. The state should only advance the
  tween and otherwise do nothing physics-related.
- Position is driven by a `Tween` on the player's `GlobalPosition` (or by
  `Tween`-interpolated `Velocity = Vector2.Zero` plus manual `Position`
  assignment — pick one and stick to it; don't mix).
- On `PipeEnterState.Exit()`, re-enable the collision shape via
  `SetDeferred("disabled", false)` and restore normal state flow. The
  deferred re-enable avoids a one-frame overlap at the exit pipe if the
  emerge tween ends with Mario's collision shape still touching the pipe's
  rim collision.
- The pipe itself keeps its solid collision on layer 1 throughout — only the
  player's collision is toggled. Other entities (enemies, shells, items) are
  unaffected and continue to collide with pipes normally.

Together these two rules mean the pipe warp sequence is "player becomes a
visual-only puppet tweened by the state, then snaps back to a normal physics
body when the state exits." This keeps the existing player controller
untouched — no special cases inside `PlayerController.cs`.

---

## 9. Blocks and Interactables

### 9.1 Question Block

Root type: `StaticBody2D`

Default content:

```csharp
[Export] public StringName Contents = "coin";
```

Allowed content values:
- `"coin"`
- `"mushroom"`
- `"fire_flower"`
- `"star"`
- `"1up_mushroom"`

Behavior on hit from below:
1. Play bump animation
2. Spawn contents above block (for the `"coin"` case, spawn the coin pop
   effect defined in §9.3 and award the coin immediately — no physical
   pickable coin is spawned)
3. Switch to empty appearance
4. Damage or kill enemies standing on top
5. Emit relevant EventBus signals

Context-sensitive behavior:
- If content is mushroom and player is already Big or Fire, spawn a Fire Flower instead

### 9.2 Brick Block

Root type: `StaticBody2D`

Optional export:

```csharp
[Export] public int CoinCount = 0;
```

Rules:
- Small Mario can bump but not break
- Big and Fire Mario can break standard bricks
- Multi-coin bricks pay out one coin per hit, then become empty
- Each payout spawns the coin pop effect from §9.3 and awards a coin
  immediately (same visual-only behavior as a coin question block)
- Enemy standing on top can be popped or killed on impact

### 9.3 Coin Pop Effect

Scene: `scenes/effects/coin_pop.tscn`. Visual-only effect spawned when a
coin question block (§9.1) or multi-coin brick (§9.2) is bumped. The coin
reward itself is awarded on the same frame via `GameManager.AddCoin()` —
the player never needs to touch the popping coin to collect it.

Scheduled for Phase 6 (Effects and Polish). Until then, coin blocks award
their coin silently on bump; this is a known gap, not a bug.

Root type: `Node2D` (no physics body, no `Area2D` — purely visual).

Spawn:
- Spawn position: the block's top edge, i.e. `block.GlobalPosition + new Vector2(0, -16)`.
- Spawned as a child of the level's effects container (or any ancestor
  above the blocks in draw order), not as a child of the block — the block
  may change visuals or be destroyed (multi-coin brick hitting zero) before
  the effect finishes.

Motion:
- Initial velocity: `new Vector2(0, -280.0f)` (roughly matched to Mario's
  small-jump velocity so the arc reads as "popping out").
- Constant gravity: `900.0f` px/s² (same value the player uses — consistent
  arc feel across the whole game).
- No horizontal velocity, no air resistance.
- The effect frees itself when either (a) its total lifetime exceeds
  `0.5 s`, or (b) its `y` velocity has become positive *and* it has
  returned past its spawn `y` — whichever comes first. In practice the
  lifetime cap triggers first; the position check is a safety net in case
  the numbers are later tuned.

Visual:
- Procedural `_Draw()` matching the regular in-world coin (`P.CoinGold`
  fill, `P.CoinShine` highlight, 1 px dark border) — the player must be
  able to read it as "a coin" instantly.
- Spin animation: oscillate horizontal draw scale over time
  (`Scale = new Vector2(Mathf.Cos(t * Mathf.Tau * 6.0f), Scale.Y)`) so the coin appears to flip at ~6 Hz,
  showing its thin profile twice per rotation. Do not use a full 3D
  rotation — flat horizontal scaling reads correctly at this resolution
  and is cheaper.
- In the last `0.1 s` of lifetime, fade `Modulate` alpha from `1.0` to `0.0`.
- `ZIndex` above blocks but below HUD (a value of `5` works with the
  z-layering established in §8.6).

Scoring feedback:
- `GameManager.AddCoin()` already emits `CoinCollected` and awards 200
  points on bump. The score popup ("200") is driven by that event in the
  existing scoring flow and does not need to be re-spawned by this effect.
- The coin pop effect itself emits no EventBus signals — it is pure
  visual.

Bloom:
- The coin pop benefits from the bloom pipeline per §5.3. No additional
  shader work is required; using the `P.CoinGold` / `P.CoinShine` colors
  is sufficient once WorldEnvironment bloom is active.

Audio:
- None from this effect. The coin SFX is triggered by `CoinCollected` on
  the bump frame (same as ground-coin pickup), not by the pop itself.

Non-rules (things this effect does NOT do):
- It is not collectible. The player walking through it has no effect.
- It does not interact with enemies, other coins, or terrain.
- It does not count toward the 1-UP threshold a second time — that coin
  was already counted at spawn.
- It does not spawn from ground-pickup coins (those fade on collection via
  their own logic).

### 9.4 Hidden Block

Root type: `StaticBody2D`

Purpose:
- Support classic hidden coin or 1-UP placements
- Stay invisible until hit from below

Scene hierarchy:

```text
HiddenBlock (StaticBody2D)
  CollisionShape2D          [disabled until revealed]
  HitSensor (Area2D)        [always active — detects upward head contact]
    CollisionShape2D
```

The `StaticBody2D` collision starts **disabled** so the player passes
through freely. A separate `Area2D` (`HitSensor`) occupies the same tile
space and stays active. Detection works as follows:

- `HitSensor` is on layer `Terrain` (layer 1) and masks `PlayerHitbox`
  (layer 4).
- When the player's head bump checker enters `HitSensor` **and** the
  player's `Velocity.Y < 0` (moving upward), the block triggers.
- On trigger: enable the `StaticBody2D` collision shape, reveal the block
  visuals, spawn contents, disable the `HitSensor` (no longer needed).

Rules:
- Initially has no visible geometry and solid collision is disabled
- The `Area2D` sensor allows the player to pass through while still detecting upward head contact
- On that first head-strike, the block reveals, enables solid collision, and triggers its contents (coin or 1-UP)
- After reveal, behaves like an empty brown block (solid, inert)

### 9.5 Flagpole

Root type: `Area2D` plus visual pole geometry

Rules:
- Trigger only once
- Capture height determines bonus points
- Player enters `FlagpoleState`
- Slide down, touch ground, walk toward castle, then finish level

### 9.6 Castle

Purely decorative for v1, except for level-end walk target and fireworks anchor point.

---

## 10. Collision Layers

| Layer | Name | Used By |
|-------|------|---------|
| 1 | Terrain | TileMap terrain, blocks, pipes |
| 2 | Player | Player `CharacterBody2D` |
| 3 | Enemies | Enemy `CharacterBody2D` |
| 4 | PlayerHitbox | Player `Area2D` hurtbox/stomp helper |
| 5 | EnemyHitbox | Enemy `Area2D` hitboxes |
| 6 | Items | Coins and power-ups |
| 7 | Fireballs | Player fireballs |
| 8 | KoopaShell | Moving shell |
| 9 | KillZone | Pit death area |
| 10 | Interactable | Flagpole, pipe warp trigger, similar overlap-only targets |

Character body mask rules:
- Player body masks `Terrain`
- Enemy body masks `Terrain`
- Item bodies mask `Terrain` if they use physics bodies
- Fireball body masks `Terrain`
- Shell body masks `Terrain`

Area overlap mask rules:
- Player hitbox masks `EnemyHitbox`, `Items`, `KillZone`, `Interactable`
- Enemy hitbox masks `PlayerHitbox`, `Fireballs`, `KoopaShell`
- KillZone masks `Player` and `Enemies`

Implementation note:
- Avoid relying on one giant overlap area for all player logic. Use small, purpose-driven shapes such as a head bump checker and stomp detector where helpful.

---

## 11. Level System

### 11.0 LevelConfig Resource

Each level scene declares its identity via an exported `LevelConfig`
resource. This is how per-level parameters reach the rest of the game
without hardcoding values in GameManager or SceneManager.

```csharp
public partial class LevelConfig : Resource
{
    [ExportGroup("Identity")]
    [Export] public int World = 1;
    [Export] public int Level = 1;

    [ExportGroup("Timer")]
    [Export] public float TimeLimit = 400.0f;

    [ExportGroup("Music")]
    [Export] public StringName MusicTrack = "overworld";
    /// <summary>Track to play when timer drops below 100. Empty = use hurry variant of MusicTrack.</summary>
    [Export] public StringName HurryMusicTrack = "";

    [ExportGroup("Environment")]
    /// <summary>If set, overrides the default sky color on WorldEnvironment at load.</summary>
    [Export] public Color? SkyColorOverride;
    /// <summary>If true, uses the underground palette and disables bloom.</summary>
    [Export] public bool IsUnderground = false;
}
```

The level scene's root script holds the export:

```csharp
[Export] public LevelConfig Config;
```

On level load, `SceneManager` reads the config from the loaded level and
forwards it:

- `GameManager` receives `Config.TimeLimit` and resets `TimeRemaining`
  to that value (not a hardcoded `400.0f`).
- `GameManager` receives `Config.World` / `Config.Level` and emits
  `LevelStarted(world, level)`.
- `AudioManager` receives `Config.MusicTrack` and begins playback.
- `WorldEnvironment` is adjusted if `Config.IsUnderground` or
  `Config.SkyColorOverride` is set, and restored to defaults on unload.

One `.tres` per level lives under `resources/config/` (e.g.,
`level_1_1.tres`, `level_1_2.tres`). Tuning time limits or swapping music
requires only a `.tres` edit in the inspector — no code changes.

### 11.1 Level Scene Structure

Suggested gameplay hierarchy:

```text
Level_1_1 (Node2D)            [script exports LevelConfig]
  Background (Node2D)
    SkyGradient (ColorRect)
    ParallaxClouds (Node2D or Parallax2D)
    ParallaxHills (Node2D or Parallax2D)
  TileMapLayer_Ground
  Blocks
  Pipes
  Coins
  Enemies
    EnemySpawner
  Interactables
    Flagpole
    Castle
  KillZone
  LevelBounds
  SpawnMarkers
    PlayerSpawn (Marker2D)
```

Note: Player, HUD, and WorldEnvironment are **not** in the level scene —
they live under `Main` (see §4.1). The level only provides `PlayerSpawn`
so the shell knows where to position the player on load.

### 11.2 TileMap

Use `TileMapLayer` only for static terrain.

Tile requirements:
- `ground_top`
- `ground_fill`

Interactive blocks are scene instances, not terrain tiles.

### 11.3 Enemy Spawner

Rules:
- Enemies begin hidden and with processing disabled
- Activate once the camera approaches within a fixed X threshold
- Never respawn once defeated or cleaned up
- Clean up enemies that permanently leave the play space

Recommended activation distance:
- 320 px from the camera's right edge

### 11.4 Level Bounds

Rules:
- Prevent backtracking to the left once the camera has advanced
- Prevent camera overshoot beyond level width
- Kill zone sits below all playable geometry

---

## 12. World 1-1 Layout

World 1-1 target:
- Approximate width: 3392 px
- Tile width: 212 tiles
- Playable height: 14 tiles
- Ground baseline: rows 12 and 13

Layout draft:

```text
Section 1 (X 0-50) - Start
  Flat ground
  Player spawn at tile (3, 11)
  Single coin question block at (16, 8)
  Five-block row at X 20-24, Y 8
  High coin block at (22, 4)
  One Goomba at (22, 11)
  Two Goombas at (40-41, 11)

Section 2 (X 50-90) - Pipes
  Pipe height 2 at (56, 10)
  Pipe height 3 at (64, 9)
  Pipe height 4 at (72, 8)
  Warp pipe height 4 at (80, 8)

Section 3 (X 90-130) - Gaps and Koopa
  Pit from X 91-92
  Block row near X 100, Y 8
  One hidden star block in this section
  Koopa at (106, 11)
  Pit from X 112-114

Section 4 (X 130-170) - Block Structures
  Floating rows at Y 4 and Y 8
  Two platform Goombas
  Multi-coin brick at (148, 8)
  Pit from X 158-160

Section 5 (X 170-200) - Staircases
  Stair up at X 178-181
  Gap between staircases
  Stair down at X 184-187
  Two Goombas at (192-193, 11)

Section 6 (X 200-212) - Finish
  Final staircase at X 198-205
  Flagpole at X 206
  Castle at X 208-211
```

Decoration rhythm:
- Hills roughly every 48 tiles
- Clouds at upper rows 2-3
- Bushes near ground breaks

---

## 13. Scoring and HUD

### 13.1 Scoring

| Event | Points |
|-------|--------|
| Coin | 200 |
| Stomp Goomba/Koopa | 100 |
| Fireball kill | 200 |
| Brick break | 50 |
| Mushroom / Fire Flower / Star pickup | 1000 |
| Consecutive stomps | 100, 200, 400, 500, 800, 1000, 2000, 4000, 5000, 8000, 1-UP |
| Shell combo kills | 500, 800, 1000, 2000, 5000, 8000, 1-UP |
| Flagpole bonus | 100-5000 |
| Time bonus | `TimeRemaining * 50` |

Score popup:
- Spawn at award position
- Rise about 20 px
- Fade over about 0.5 seconds

### 13.2 HUD

Suggested hierarchy:

```text
HUD (CanvasLayer)
  MarginContainer
    HBoxContainer
      MarioBox
      CoinBox
      WorldBox
      TimeBox
```

Displayed values:
- Score, padded to 6 digits
- Coin count
- Current world/level
- Time remaining

Style:
- White text
- 1 px black shadow via `LabelSettings`
- Timer turns red and pulses below 100
- Coin icon should visually match the in-game procedural coin

---

## 14. Game Flow

Flow:

```text
main.tscn
  -> Title Screen
  -> Level Intro
  -> Gameplay
     -> Death -> Retry or Game Over
     -> Flagpole -> Level Complete -> Next Level
     -> Pause -> Resume
  -> Game Over
  -> Title Screen
```

Title screen:
- Show game title
- Show blinking "PRESS START"
- Accept keyboard or gamepad start input

Level intro:
- Black background
- Show `WORLD 1-1`
- Show remaining lives
- Last about 2.5 seconds

Pause:
- Freeze gameplay
- Keep pause menu interactive

Game over:
- Show for about 3 seconds
- Return to title

---

## 15. Implementation Phases

Every phase ends with a **Testing & verification** block. Treat these as the
gates you must clear before moving on — catching a bug in the phase that
introduced it is an order of magnitude cheaper than catching it after three
more systems have been layered on top. If a check fails, fix it before starting
the next phase rather than adding it to a backlog.

Two validation tools are used throughout:

- `godot --headless --path . --quit` — catches parse errors, broken autoload
  wiring, missing `res://` paths, and malformed scene files. Fast enough to run
  after any edit. Run `dotnet build` first to catch C# compile errors — the
  headless launch only validates the Godot project structure, not C# syntax.
- `godot --path .` — runs the game windowed for manual gameplay checks. Use
  the Godot editor's remote scene tree and debugger when something looks wrong
  at runtime.

### Phase 1 - Foundation

- Create repo folders and scene/script skeletons
- Configure project display and input
- Add autoloads
- Implement transition shell and game state shell

**Testing & verification:**

- Headless: `godot --headless --path . --quit` exits with code 0 and prints no
  script errors or missing-resource warnings.
- Manual: launch the game — the main scene loads, autoloads are instantiated
  (temporarily `GD.Print()` from each `_Ready()` to confirm), input actions
  respond in the Input Map tester, and `SceneManager.ChangeScene()` plays a
  visible fade when called from a debug key.
- Bug watchlist:
  - Autoload order matters: `EventBus` must load before `GameManager` or
    signal connections will fail. Verify via the print order.
  - Typos in the `res://` paths for autoload scripts silently disable the
    autoload — check `GameManager` is non-null from any scene.
  - `project.godot` edits: a single malformed line breaks project loading
    entirely. If headless exits nonzero, revert the last `project.godot` edit.

### Phase 2 - Player

- Build `player.tscn`
- Implement controller movement
- Add state machine
- Draw small and big Mario
- Validate movement on flat ground

**Testing & verification:**

- Headless: project loads clean after adding the state machine and all state
  scripts (a missing base class reference in any state script breaks the whole
  player scene).
- Manual gameplay:
  - Walk, run (hold run key), and stop — decelerate smoothly without sliding
    forever.
  - Skid turnaround: run one way, press opposite — Mario should decelerate
    quickly and turn around without snapping direction instantly.
  - Jump: tapped jump is short, held jump is tall — variable height works.
  - Coyote time: walk off a ledge and press jump ~1 frame late — should still
    jump. Jump buffer: press jump ~1 frame before landing — should jump on
    landing.
  - Crouch (as Big Mario): hold down — collision shape shrinks, drawing
    matches. Releasing crouch under a low ceiling must not let Mario stand
    (ceiling clearance check).
  - `_Draw()` walk cycle animates while running and freezes on idle.
- Bug watchlist:
  - State machine leaks: transitions not calling `Exit()` cause lingering
    behavior (e.g., run animation stuck during jump). Add temporary state
    prints if any state feels sticky.
  - Collision shape not resized on power change → Mario gets stuck in ceilings
    or falls through floors after a grow/shrink.
  - `IsOnFloor()` flickering on slopes: if jumping feels inconsistent after
    landing, check `MoveAndSlide()` is called every physics frame.

### Phase 3 - Level Basics

- Build `world_1_1.tscn`
- Add terrain tilemap
- Add camera, bounds, and kill zone
- Add parallax/background layers
- Add HUD

**Testing & verification:**

- Headless: level scene loads, `TerrainTileSet` is generated without errors,
  no missing texture warnings (procedural only, so any texture warning points
  to an accidental asset reference).
- Manual gameplay:
  - Walk the full length of the level — no gaps in terrain, no falling through
    the ground, no invisible walls.
  - Camera follows the player with look-ahead; camera does not scroll left
    once it has advanced (`LimitLeft` ratchet).
  - Parallax: clouds, hills, and bushes drift at different speeds than the
    foreground as the camera moves. They should not snap or tear as the
    camera starts moving (verifies the lazy camera lookup in `_Process()`).
  - Kill zone: fall into a pit — player dies and respawns or triggers game
    over flow.
  - HUD: score, coins, world, timer, and lives display. Timer decrements once
    per second.
- Bug watchlist:
  - Parallax reading `camera.GlobalPosition` instead of
    `GetScreenCenterPosition()` causes visible jitter when the camera
    smooths or offsets.
  - Kill zone on the wrong collision layer silently never fires.
  - TileMapLayer collision not enabled → player walks through the ground.
  - HUD Label uses a default theme font that blurs at low res; confirm pixel
    font or `LabelSettings` with integer scaling.

### Phase 4 - Blocks and Items

- Question blocks
- Brick blocks
- Hidden blocks
- Coins
- Mushroom and Fire Flower
- Power-state transitions

**Testing & verification:**

- Headless: all block and item scenes load; no missing resource paths.
- Manual gameplay:
  - Question block: jump into it from below — bump animation plays, contents
    spawn above, block turns empty brown. Repeated hits do nothing.
  - Brick block as Small Mario: bumps without breaking. As Big Mario: shatters
    and awards points.
  - Multi-coin brick: yields its configured coin count across successive
    bumps, then becomes empty.
  - Hidden block: run underneath without hitting it — invisible, no collision
    (player is not stopped mid-air). Jump into the tile from below — block
    reveals, becomes solid, spawns contents. Walking or falling into it from
    the side or above does nothing.
  - Mushroom: Small → Big. Collision shape expands without clipping into
    ground, power state is applied, score +1000. The grow *animation*
    itself (flicker/pause/effect ring) is Phase 6 work — at this phase the
    transition is allowed to be instantaneous.
  - Fire Flower (already Big): Big → Fire, palette changes (instantaneous
    in Phase 4; animated in Phase 6).
  - Fire Flower taken while Small: still upgrades to Big (spec rule).
  - Coin pickup: score +200, coin count +1, `CoinsChanged` HUD update. 100
    coins grants a 1-UP.
- Bug watchlist:
  - Any new interactable block that forgets `BumpFromBelow()` will be hit
    but do nothing — player's `CheckCeilingBumps()` silently skips it.
  - Block bump via `Area2D.BodyEntered` is unreliable on touching contact
    (see `CLAUDE.md`). Use the slide-collision pattern for solid blocks.
  - Hidden block: deep head penetration (more than 8 px in a single frame)
    can flip depenetration direction on reveal, popping Mario up through the
    block. Watch for any velocity tuning that pushes per-frame motion past
    that threshold.
  - Mushroom falling into pits before the player can reach it: items should
    ride terrain and reverse at walls.
  - Power-down during intangibility frames must not re-trigger damage.

### Phase 5 - Enemies

- Enemy base
- Goomba
- Koopa
- Koopa shell
- Stomp and damage logic
- Enemy activation/cleanup

**Testing & verification:**

- Headless: all enemy scenes load; enemy base class is
  referenced correctly by Goomba/Koopa.
- Manual gameplay:
  - Goomba: walks, reverses at walls and ledges (if that rule applies),
    stomped → dies with squash animation and awards points.
  - Koopa: stomped once → shell state, stomped again (or kicked) → moving
    shell. Moving shell kills other enemies on contact and can bounce off
    walls. Combo chain kills escalate points (100/200/400/...).
  - Walking into an enemy from the side damages Mario. Small Mario dies, Big
    Mario shrinks.
  - Enemies off-screen do not process physics (activation gate). Walk back
    and forth past an enemy — CPU profile should not ramp with distance.
  - Falling into a pit destroys the enemy cleanly.
- Bug watchlist:
  - Stomp detection vs. side-hit depends on layer masks and vertical
    velocity. If Mario dies when stomping, the stomp `Area2D` is on the
    wrong layer or the hurtbox is firing first.
  - Enemies spawning inside terrain due to off-grid placement.
  - Shell collision with the player who just kicked it: shell must ignore
    the player for a few frames post-kick or Mario dies from his own kick.
  - Enemy `QueueFree()` during a signal emission can crash — use
    `CallDeferred(MethodName.QueueFree)`.

### Phase 6 - Effects, Polish, and Tunables Refactor

Phase 6 is split into two concerns: visual polish (particles, shaders, shake)
and a one-time infrastructure refactor that migrates gameplay tunables from
scattered `const` declarations into Godot `Resource` files (`.tres`). The
refactor lands here, not earlier and not later, for three reasons:

1. By the end of Phase 5 every core system exists — player, level, blocks,
   items, enemies — so we know exactly which categories of config are needed.
   Migrating earlier risks building resources for systems that don't exist yet.
2. Phases 7-10 involve heavy tuning (flagpole scoring, timer curves, starman
   duration, enemy balance, level flow, full-level polish). Having tunables
   editable from the Godot inspector before entering those phases is a
   compounding time saver.
3. Polish work in the rest of Phase 6 (shake decay, flash duration, particle
   counts, trail spacing) is itself tuning — the new resources cover these
   knobs immediately.

**Goal:** no gameplay behavior changes. This is a pure infrastructure refactor.
Every value in every migrated resource must match the previous `const` exactly
on the first commit. Tuning happens after the refactor is verified.

#### 6.1 Tunables Refactor

- Create `Scripts/Config/` directory for `Resource` subclass scripts.
- Create `resources/config/` directory for saved `.tres` instances.
- Migrate in this order (stop if you run out of time — later items are lower
  priority):

  1. **`PlayerMovementConfig`** — all constants currently in
     `PlayerController.cs` (walk/run speed, acceleration, jump velocity,
     gravity, fast fall, coyote time, jump buffer, release multiplier, small
     and big collision sizes). Also absorb the `1.12` high-speed jump boost
     magic number from `JumpState.cs`.
  2. **`CameraConfig`** — look-ahead distance, look-ahead lerp speed, smoothing
     speed, and the no-backtrack offset (`-256.0`) currently inlined in
     `PlayerController.cs`.
  3. **`EnemyConfig` (one resource per enemy type)** — patrol speed, stomp
     reward, contact damage type, activation range. Start with Goomba and
     Koopa; Piranha Plant can be added in Phase 7 when it lands.
  4. **`BlockBumpConfig`** — bump amplitude (`-4.0`), bump duration (`0.15`),
     and the shared visual offsets used by question/brick/hidden blocks.
     Single shared resource — all three block scripts reference it.
  5. **`ItemConfig`** — mushroom emerge speed, fall speed, wall-reverse rule,
     fire flower pulse rate.
  6. **`LevelTimingConfig`** — level intro duration (~2.5 s), game over hold
     (~3 s), fade duration, flagpole slide speed.
  7. **`EffectsConfig`** (do this alongside the polish work below) — screen
     shake decay rate, damage flash duration, score popup rise speed, motion
     trail spacing.

- Pattern per resource (see `CLAUDE.md` conventions):
  ```csharp
  // Scripts/Config/PlayerMovementConfig.cs
  public partial class PlayerMovementConfig : Resource
  {
      [Export] public float WalkSpeed = 130.0f;
      [Export] public float RunSpeed = 210.0f;
      // ... one [Export] per tunable, with the current const value as the default
  }
  ```
  Scripts that consume the resource declare a strongly typed export
  (`[Export] public PlayerMovementConfig Movement;`) — C# provides full
  type safety without any extra loading step.
- Keep one canonical `.tres` per config under `resources/config/` (e.g.,
  `player_movement_default.tres`). Variants (forgiving, debug, low-gravity)
  can be added later by duplicating the `.tres` — no code changes required.
- Scripts that currently use the constants should hold an `[Export] public PlayerMovementConfig Config`
  assigned in their scene and read `Config.WalkSpeed` instead of
  `WalkSpeed`. The old `const` declarations are deleted, not left as
  fallbacks.
- `ProjectSettings` is reserved for truly global flags (difficulty, debug
  toggles) and is **not** used for gameplay tunables. No god `Settings.cs`.

#### 6.2 Visual Polish

- Particles
- Glow shader
- Damage flash
- Screen shake
- Score popups
- Motion trails
- Grow / shrink animation (`GrowState`, `ShrinkState`) with the gameplay
  pause rule from §6.4 of the player-states spec, plus the
  `power_up_effect.tscn` pickup ring and the `coin_pop.tscn` effect deferred
  from §9.3. Phase 4 intentionally ships these as instantaneous transitions;
  Phase 6 is where they become animated.

**Testing & verification:**

- Headless: project loads clean after the refactor. Every migrated scene must
  still open — a missing `[Export]` assignment or a broken resource path
  in a config script will surface here.
- Refactor regression checks (run *before* tuning any values):
  - Movement feel is byte-identical to pre-refactor. The fastest way to
    verify: record a short gameplay clip before starting the refactor
    (standing jump height, running jump distance to a known landmark, skid
    distance from full run) and re-measure after. Any difference means a
    value was transcribed wrong.
  - Every block, enemy, and item scene in the level still references a valid
    config resource. Open `world_1_1.tscn` in the editor — any node with a
    missing resource shows a yellow warning triangle.
  - Reassigning a config `.tres` in the inspector and re-running the game
    picks up the new values without a code edit. This is the whole point of
    the migration — if it doesn't work, the `[Export]` wiring is wrong.
  - Duplicate a `.tres` to `player_movement_forgiving.tres`, bump
    `CoyoteTime` to `0.20`, assign it to the player, and confirm the
    forgiveness window feels longer. Then revert.
- Visual polish manual gameplay:
  - Bloom/glow visible on bright sprites against darker backgrounds;
    WorldEnvironment is set and Forward Plus renderer is active.
  - Damage flash plays on hit and does not persist after intangibility ends.
  - Screen shake triggers on brick-break, enemy stomp chain, and power-up
    loss — decay returns the camera precisely to its tracked position (no
    drift).
  - Score popups spawn at event positions and rise/fade consistently.
  - Motion trails draw while running at top speed and cleanly disappear when
    slowing down.
  - Particles do not accumulate forever — confirm they free themselves after
    their lifetime.
  - Grow animation: grab a mushroom as Small Mario — gameplay freezes, the
    drawer flickers between Small and Big for roughly 0.8 seconds, the
    `power_up_effect.tscn` pickup ring spawns at Mario's position, then
    gameplay resumes with Mario in the Big form. `GrowState` is entered via
    `Any -> Grow` from the state machine.
  - Shrink animation: take damage as Big Mario — gameplay freezes, the
    drawer flickers between Big and Small, then resumes with Mario in the
    Small form and intangibility active. `ShrinkState` is entered via
    `Any -> Shrink`.
  - Pause rule (§6.4 of the player-states spec): UI and transition-critical
    nodes continue to process during grow/shrink. Verify by triggering the
    animation and confirming the HUD timer *pauses* while the animation
    runs (it is gameplay-tier) but the fade/transition overlay, if active,
    continues animating.
  - Coin pop (§9.3): bumping a coin question block or multi-coin brick now
    spawns a visible spinning coin that arcs up from the block, flips at
    ~6 Hz, and fades out in its final 0.1 s. Coin count and score still
    update on the bump frame — the pop is visual-only.
- Bug watchlist (refactor):
  - Scene left referencing the old `const` after the script was rewritten
    to use `Config.X` — the scene silently uses default values because the
    `[Export]` was never assigned in the inspector. Any sudden "feels wrong"
    after the refactor is this bug until proven otherwise.
  - `.tres` file edited outside the Godot editor can desync from its script
    schema (add/remove/rename an `[Export]` without the editor re-saving
    the resource). Keep resource edits inside the Godot inspector.
  - Two scenes pointing to the same `.tres` — edits propagate to both. If
    you need per-instance overrides, use **Local to Scene** on the resource
    or duplicate the `.tres`.
  - Transcription typos during migration (e.g., `Acceleration = 800.0f`
    becoming `800`). The regression clip check is how you catch these.
- Bug watchlist (polish):
  - Screen shake applied directly to `camera.Position` instead of
    `camera.Offset` fights with parallax and breaks camera follow.
  - Forward Plus not active → glow silently does nothing. Check project
    settings after any renderer change.
  - Particles on CanvasLayer inherit the wrong coordinate space and render
    off-screen.
  - Grow/shrink pause implemented by setting `GetTree().Paused = true`
    without marking the transition overlay's process mode appropriately:
    the fade/intro overlay will stop animating alongside gameplay. Use
    `ProcessModeEnum.Always` on the nodes that must keep running.
  - `GrowState` that doesn't record and restore the previous state on exit
    will drop Mario into Idle after grabbing a mushroom mid-jump, losing
    his airborne momentum. Cache the source state in `Enter()` and
    transition back to it (or to Fall, if the source was Jump and Velocity
    is now downward) in `Exit()`.
  - Collision shape resized mid-animation rather than at the end: if the
    shape grows while the drawer is still flickering to Small, Big Mario's
    collision clips into ceilings visually occupied by Small Mario. Resize
    once, on the final frame of the animation, matching the drawer's
    final form.

### Phase 7 - Advanced Gameplay

- Fire Mario and fireballs
- Starman
- Piranha Plant
- Pipe warps
- Flagpole sequence
- Timer countdown

**Testing & verification:**

- Headless: all new scenes and states load; no missing states in the player
  state machine.
- Manual gameplay:
  - Fireball: spawns at Mario's front, arcs with gravity, bounces on floor,
    dies on wall contact, kills enemies. Max 2 on screen at once.
  - Starman: invincibility works, palette cycles, enemies killed by contact,
    runs out with warning flashes, music duck/restore works.
  - Piranha Plant: retracts when Mario stands on its pipe; emerges otherwise.
    Damages on contact.
  - Pipe warp: press down on a warp pipe → pipe-enter state plays, scene
    transitions, Mario emerges from the destination pipe.
  - Flagpole: grab at various heights — scoring matches the height table,
    slide-down plays, walk-to-castle auto-moves Mario, level complete fires.
  - Timer: decrements visibly, HUD text turns red and pulses below 100,
    hitting zero triggers death.
- Bug watchlist:
  - Flagpole grabbed mid-jump from the back side of the pole doesn't trigger
    — check the collision area extends to both sides.
  - Pipe warp triggered while airborne or while carrying momentum creates
    visual glitches — only accept the warp input while grounded over the
    pipe.
  - Fireball passes through thin platforms or block seams due to tunneling —
    cap its speed or use shape cast.
  - Timer continuing to run during death or level-complete animations.

### Phase 8 - Menus and Loop

- Title screen
- Pause menu
- Level intro
- Game over
- Level complete flow

**Testing & verification:**

- Headless: every menu scene loads in isolation.
- Manual gameplay:
  - Boot the game — title screen appears, "PRESS START" blinks, any input
    advances to level intro.
  - Level intro shows `WORLD 1-1` and lives, lasts ~2.5 s, then gameplay
    begins.
  - Pause: press pause → gameplay freezes, menu is interactive (music ducks
    or pauses), unpause resumes exactly where it left off.
  - Die all lives → game over screen → return to title after ~3 s.
  - Complete the flagpole → level complete bonus tally → next level (or back
    to title if no next level).
- Bug watchlist:
  - Pause menu not set to `ProcessModeEnum.WhenPaused` — the menu freezes with
    the rest of the game.
  - Title screen input registering a stale jump press that carries into the
    first frame of gameplay.
  - `GameManager` state (score, lives, timer) not reset properly on return
    to title, causing the next run to start with leftover values.

### Phase 9 - Audio

- Add placeholder or final assets
- Wire EventBus-to-audio responses
- Tune volume mix

**Testing & verification:**

- Headless: audio registry loads without "missing stream" errors for any
  registered key.
- Manual gameplay:
  - Every gameplay event with a wired SFX plays it (jump, stomp, coin,
    power-up, bump, break, fireball, death, flagpole).
  - Music plays on level start; crossfade between stages works; Starman
    music supplants level music and restores afterward.
  - SFX pool size is sufficient — rapid events (coin pickup, multi-coin
    brick, enemy chain) do not drop sounds.
  - Volume mix: no clipping, SFX audible over music.
- Bug watchlist:
  - Signal connected twice → SFX plays twice and doubles in volume.
  - Empty key in audio registry plays nothing silently — log a warning on
    first use to surface missing assets.
  - Music player not set to `Bus = "Music"` means volume sliders don't
    affect it.

### Phase 10 - Expansion

- Fill out the full World 1-1 pass
- Add hidden 1-UP spots and polish
- World 1-2 underground level

**Testing & verification:**

- Headless: both level scenes load.
- Manual full-playthrough:
  - Complete World 1-1 from start to flagpole without dying. All blocks,
    enemies, items, pipes, and the flagpole behave correctly.
  - Find every hidden 1-UP in the documented positions.
  - Complete the pipe warp into the coin room (if included) and exit back
    into the level.
  - Complete World 1-2: underground palette, pipe exit to 1-3 or
    loop back to title.
- Bug watchlist:
  - Regression: earlier phases' bugs often resurface during level expansion
    (e.g., new block positions expose a camera limit bug). Re-run all
    earlier phase manual checks on the expanded level.
  - Level load time: sudden spikes usually mean a runtime resource is being
    rebuilt per-instance instead of cached.
  - Memory leaks across death/respawn cycles — play through the level 10+
    times in one session and confirm frame time stays stable.

---

## 16. Architectural Decisions

1. `CharacterBody2D` over `RigidBody2D` for the player because platformer controls require direct, deterministic movement.

2. `TileMapLayer` for terrain and separate scenes for interactive objects because blocks, pipes, and items have custom logic.

3. A dedicated player state machine because movement, damage, growth, pipes, and flagpole behavior would otherwise create brittle condition chains.

4. EventBus-based decoupling because HUD, audio, scoring, and effects should react without hard scene dependencies.

5. Forward Plus renderer because the visual pitch depends on subtle bloom and post-processing.

6. `_Draw()`-driven character rendering because the project intentionally avoids sprite production and benefits from procedural animation control.

7. A 16 px grid because it preserves Mario-style spacing and keeps scene authoring simple.

---

## 17. Open Questions

All previously open questions have been resolved in this spec:

- **Movement feel:** Defined in §6.2 and §6.3. The physics constants and state machine define the canonical feel for this project.
- **Hidden blocks:** Classic SMB behavior — invisible with a sensor-based detection mechanism. See §9.4.
- **Title screen:** Static for v1. No attract/demo playback.
- **World 1-2 scope:** Included in v1 scope (not a stretch goal).
