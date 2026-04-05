# SPEC.md - Super Mario Bros (Godot 4.6)

## 0. Purpose

This document defines the target design for a 2D Super Mario Bros inspired game built in Godot 4.6.

Project pillars:
- Primitive-shape visuals only. No spritesheets or texture-based characters.
- Tight, readable platforming that feels close to classic SMB.
- Modern polish through particles, glow, screen shake, transitions, and clean architecture.
- Audio-ready structure even if placeholder or empty assets are used at first.

Current repository status:
- The repo is currently a minimal Godot starter project.
- `project.godot`, `icon.svg`, and a placeholder `new_script.gd` exist.
- Everything else in this spec describes the intended target architecture, not the current state on disk.

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
- Own the top-level gameplay shell
- Ensure transition/UI overlay layers exist
- Load the title screen first
- Provide a stable place for `WorldEnvironment` and debug-only nodes if needed

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

  scripts/
    autoloads/
      event_bus.gd
      game_manager.gd
      audio_manager.gd
      scene_manager.gd
      camera_effects.gd
    player/
      player_controller.gd
      player_drawer.gd
      state_machine.gd
      player_states/
        player_state.gd
        idle_state.gd
        run_state.gd
        jump_state.gd
        fall_state.gd
        crouch_state.gd
        death_state.gd
        grow_state.gd
        shrink_state.gd
        pipe_enter_state.gd
        flagpole_state.gd
    enemies/
      enemy_base.gd
      goomba.gd
      koopa.gd
      koopa_shell.gd
      piranha_plant.gd
    objects/
      brick_block.gd
      question_block.gd
      hidden_block.gd
      coin.gd
      power_up_base.gd
      mushroom.gd
      fire_flower.gd
      starman.gd
      fireball.gd
      flagpole.gd
      pipe.gd
      castle.gd
    ui/
      hud.gd
      title_screen.gd
      game_over.gd
      pause_menu.gd
      level_complete.gd
      level_intro.gd
    level/
      level_base.gd
      enemy_spawner.gd
      kill_zone.gd
      parallax_controller.gd

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
```

Notes:
- `new_script.gd` is a temporary placeholder and should be removed or replaced once the real scene structure is created.
- Generated files under `.godot/`, `*.uid`, and `*.import` should not be hand-edited.

---

## 3. Autoloads

Register these singletons in `project.godot`:

```text
EventBus      = "*res://scripts/autoloads/event_bus.gd"
GameManager   = "*res://scripts/autoloads/game_manager.gd"
AudioManager  = "*res://scripts/autoloads/audio_manager.gd"
SceneManager  = "*res://scripts/autoloads/scene_manager.gd"
CameraEffects = "*res://scripts/autoloads/camera_effects.gd"
```

All autoloads should extend `Node`.

### 3.1 EventBus

Central signal hub for cross-system communication. Systems should prefer signals over hard references when the interaction is not local and obvious.

Required signals:

```gdscript
# Player
signal player_died
signal player_respawned
signal player_powered_up(power_up_type: StringName)
signal player_power_state_changed(old_state: int, new_state: int)
signal player_damaged
signal player_star_power_started
signal player_star_power_ended

# Scoring and HUD
signal coin_collected(position: Vector2)
signal score_awarded(points: int, position: Vector2)
signal score_changed(new_score: int)
signal lives_changed(new_lives: int)
signal coins_changed(new_coin_count: int)
signal time_tick(time_remaining: int)
signal one_up_earned

# Level
signal level_started(world: int, level: int)
signal level_completed
signal flagpole_reached(height_ratio: float)

# Enemies
signal enemy_stomped(position: Vector2)
signal enemy_killed(position: Vector2, enemy_type: StringName)
signal combo_stomp(count: int, position: Vector2)

# Blocks and items
signal block_bumped(position: Vector2)
signal block_broken(position: Vector2)
signal item_spawned(item_type: StringName, position: Vector2)

# Game state
signal game_paused
signal game_resumed
signal game_over
```

### 3.2 GameManager

Tracks persistent game state across scene loads.

State fields:
- `score: int = 0`
- `coins: int = 0`
- `lives: int = 3`
- `time_remaining: float = 400.0`
- `current_world: int = 1`
- `current_level: int = 1`
- `current_power_state: PowerState = PowerState.SMALL`
- `game_state: GameState = GameState.TITLE`

Enums:

```gdscript
enum PowerState { SMALL, BIG, FIRE }
enum GameState { TITLE, PLAYING, PAUSED, GAME_OVER, LEVEL_COMPLETE, TRANSITIONING }
```

State flow:

```text
TITLE -> PLAYING
PLAYING <-> PAUSED
PLAYING -> LEVEL_COMPLETE -> TRANSITIONING -> PLAYING
PLAYING -> GAME_OVER
GAME_OVER -> TITLE
```

Responsibilities:
- Score, coin, and life tracking
- Coin-to-1UP conversion every 100 coins
- Countdown timer while in `PLAYING`
- Death and respawn orchestration
- Time bonus payout at level end (`remaining_time * 50`)
- Resetting per-run state on new game start

Add these helper methods:
- `start_new_game() -> void`
- `add_score(points: int, position: Vector2 = Vector2.ZERO) -> void`
- `add_coin(position: Vector2 = Vector2.ZERO) -> void`
- `lose_life() -> void`
- `set_power_state(state: PowerState) -> void`
- `set_game_state(state: GameState) -> void`

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

```gdscript
var _sfx_registry: Dictionary[StringName, String] = {
    &"jump": "",
    &"jump_big": "",
    &"stomp": "",
    &"coin": "",
    &"block_bump": "",
    &"block_break": "",
    &"powerup": "",
    &"powerdown": "",
    &"fireball": "",
    &"kick": "",
    &"pipe": "",
    &"1up": "",
    &"death": "",
    &"flagpole": "",
    &"game_over": "",
    &"stage_clear": "",
    &"warning": "",
}

var _music_registry: Dictionary[StringName, String] = {
    &"overworld": "",
    &"underground": "",
    &"star": "",
    &"hurry": "",
}
```

Rules:
- Empty paths should safely no-op.
- Use two `AudioStreamPlayer` nodes for music crossfades.
- Use pooled `AudioStreamPlayer` and `AudioStreamPlayer2D` nodes for concurrent SFX.

Recommended pool sizes:
- 10 non-positional SFX players
- 6 positional SFX players

Key methods:
- `play_sfx(sound_name: StringName, position: Vector2 = Vector2.ZERO) -> void`
- `play_music(music_name: StringName) -> void`
- `stop_music() -> void`
- `set_music_ducked(enabled: bool) -> void`

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
- `change_scene(path: String) -> void`
- `reload_current_scene() -> void`
- `show_level_intro(world: int, level: int, lives: int) -> void`

### 3.5 CameraEffects

Controls temporary effects on the active `Camera2D`.

Methods:
- `shake(intensity: float, duration: float) -> void`
- `freeze_frame(duration: float) -> void`

Recommended shake presets:

| Event | Intensity | Duration |
|-------|-----------|----------|
| Enemy stomp | 2.0 | 0.10s |
| Brick break | 4.0 | 0.15s |
| Player death | 6.0 | 0.30s |

Implementation note:
- `freeze_frame()` should be very short and must not break timers or long tweens. Use a tiny `Engine.time_scale` dip or a controlled local pause rather than freezing the whole app indiscriminately.

---

## 4. Core Scenes

### 4.1 Main Scene

`main.tscn` should act as the shell scene, not the level itself.

Suggested hierarchy:

```text
Main (Node)
  SceneRoot (Node)
  OverlayRoot (CanvasLayer)
  DebugRoot (Node) [optional]
```

### 4.2 Level Scene Contract

Every gameplay level scene should:
- inherit the same broad structure
- expose a spawn marker for the player
- define camera bounds
- contain a `KillZone`
- contain one `WorldEnvironment`

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
- `draw_rect`
- `draw_circle`
- `draw_polygon`
- `ColorRect`

Rules:
- No sprite textures for characters or gameplay objects
- Keep geometry aligned to the 16 px grid
- Favor bold silhouettes and high contrast over tiny detail

### 5.1 Color Palette

```gdscript
# Sky / Background
const SKY_BLUE         := Color(0.35, 0.65, 0.95)
const SKY_UNDERGROUND  := Color(0.05, 0.05, 0.08)
const CLOUD_WHITE      := Color(0.95, 0.95, 0.98)

# Ground / Terrain
const GROUND_BROWN     := Color(0.55, 0.35, 0.15)
const GROUND_GREEN     := Color(0.25, 0.65, 0.25)
const BRICK_RED        := Color(0.72, 0.30, 0.18)
const BRICK_DARK       := Color(0.55, 0.22, 0.12)

# Mario
const MARIO_RED        := Color(0.90, 0.15, 0.15)
const MARIO_SKIN       := Color(0.95, 0.75, 0.55)
const MARIO_BLUE       := Color(0.20, 0.30, 0.75)
const MARIO_FIRE_WHITE := Color(0.95, 0.95, 0.95)

# Enemies
const GOOMBA_BROWN     := Color(0.55, 0.30, 0.15)
const GOOMBA_DARK      := Color(0.35, 0.18, 0.08)
const KOOPA_GREEN      := Color(0.20, 0.70, 0.25)
const KOOPA_SHELL      := Color(0.15, 0.55, 0.20)
const PIRANHA_GREEN    := Color(0.15, 0.60, 0.15)
const PIRANHA_RED      := Color(0.80, 0.15, 0.12)

# Objects
const PIPE_GREEN       := Color(0.18, 0.60, 0.22)
const PIPE_GREEN_LIGHT := Color(0.28, 0.72, 0.32)
const QUESTION_YELLOW  := Color(0.95, 0.80, 0.20)
const QUESTION_DARK    := Color(0.70, 0.55, 0.10)
const COIN_GOLD        := Color(1.00, 0.85, 0.20)
const COIN_SHINE       := Color(1.00, 0.95, 0.60)
const BLOCK_BROWN      := Color(0.50, 0.35, 0.20)
const STAR_YELLOW      := Color(1.00, 0.90, 0.15)
const FIRE_ORANGE      := Color(1.00, 0.55, 0.10)
const FIRE_RED         := Color(1.00, 0.25, 0.10)
const MUSHROOM_RED     := Color(0.90, 0.15, 0.15)
const MUSHROOM_CREAM   := Color(0.95, 0.90, 0.80)
```

### 5.2 Character and Object Rendering

All main characters should render through a dedicated `Node2D` drawer child using `_draw()`. That keeps gameplay logic separate from visual construction and makes palette swaps easier.

Mario:
- Small Mario footprint: 16 x 16
- Big Mario footprint: 16 x 32
- Draw facing right by default
- Flip via parent `Visuals.scale.x`
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

```gdscript
const WALK_SPEED        := 130.0
const RUN_SPEED         := 210.0
const ACCELERATION      := 800.0
const DECELERATION      := 1200.0
const AIR_ACCELERATION  := 600.0
const TURN_ACCELERATION := 1600.0
const JUMP_VELOCITY     := -330.0
const JUMP_RELEASE_MULT := 0.5
const GRAVITY           := 900.0
const FAST_FALL_GRAVITY := 1400.0
const MAX_FALL_SPEED    := 500.0
const COYOTE_TIME       := 0.08
const JUMP_BUFFER_TIME  := 0.10
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
- Only BIG and FIRE Mario may crouch
- Crouch collision height matches 1 tile height
- If there is not enough overhead clearance, standing back up is blocked
- Small Mario ignores crouch for collision changes

Facing:
- `Visuals.scale.x = -1` when moving left
- `Visuals.scale.x = 1` when moving right

### 6.4 State Machine

`state_machine.gd` should:
- hold `current_state: PlayerState`
- delegate input/frame/physics to the active state
- provide `transition_to(state_name: StringName) -> void`

Base state:

```gdscript
class_name PlayerState
extends Node

var player: CharacterBody2D

func enter() -> void:
    pass

func exit() -> void:
    pass

func process_input(event: InputEvent) -> void:
    pass

func process_frame(delta: float) -> void:
    pass

func process_physics(delta: float) -> void:
    pass
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

```gdscript
enum PowerState { SMALL, BIG, FIRE }
```

Rules:
- SMALL + Mushroom -> BIG
- SMALL + Fire Flower -> BIG
- BIG + Fire Flower -> FIRE
- BIG or FIRE + damage -> SMALL
- SMALL + damage -> death
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
- `speed`
- `gravity = 900.0`
- `direction = -1.0`

Shared behavior:
- Apply gravity
- Move with `move_and_slide()`
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
- `IDLE`
- `MOVING`

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

Pipes may optionally define:

```gdscript
@export var warp_target: NodePath
```

Entry rules:
- Player must be on top of the pipe
- Player must hold `crouch`
- Warp only triggers on valid target pipes

Warp sequence:
1. Enter `PipeEnterState`
2. Disable normal input
3. Tween player down into pipe
4. Play pipe SFX
5. Fade transition
6. Reposition at target pipe exit
7. Tween player out
8. Return control

---

## 9. Blocks and Interactables

### 9.1 Question Block

Root type: `StaticBody2D`

Default content:

```gdscript
@export var contents: StringName = &"coin"
```

Allowed content values:
- `&"coin"`
- `&"mushroom"`
- `&"fire_flower"`
- `&"star"`
- `&"1up_mushroom"`

Behavior on hit from below:
1. Play bump animation
2. Spawn contents above block
3. Switch to empty appearance
4. Damage or kill enemies standing on top
5. Emit relevant EventBus signals

Context-sensitive behavior:
- If content is mushroom and player is already BIG or FIRE, spawn a Fire Flower instead

### 9.2 Brick Block

Root type: `StaticBody2D`

Optional export:

```gdscript
@export var coin_count: int = 0
```

Rules:
- SMALL Mario can bump but not break
- BIG and FIRE Mario can break standard bricks
- Multi-coin bricks pay out one coin per hit, then become empty
- Enemy standing on top can be popped or killed on impact

### 9.3 Hidden Block

Root type: `StaticBody2D`

Purpose:
- Support classic hidden coin or 1-UP placements
- Stay invisible until hit from below

Rules:
- Initially has no visible geometry and no collision
- Player can pass freely through the tile space until their head strikes it from below while moving upward
- On that first head-strike, the block reveals, enables collision, and triggers its contents (coin or 1-UP)
- After reveal, behaves like an empty brown block (solid, inert)

### 9.4 Flagpole

Root type: `Area2D` plus visual pole geometry

Rules:
- Trigger only once
- Capture height determines bonus points
- Player enters `FlagpoleState`
- Slide down, touch ground, walk toward castle, then finish level

### 9.5 Castle

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

### 11.1 Level Scene Structure

Suggested gameplay hierarchy:

```text
Level_1_1 (Node2D)
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
    PlayerSpawn
  Player
  HUD
  WorldEnvironment
```

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
| Time bonus | `remaining_time * 50` |

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

### Phase 1 - Foundation

- Create repo folders and scene/script skeletons
- Configure project display and input
- Add autoloads
- Implement transition shell and game state shell

### Phase 2 - Player

- Build `player.tscn`
- Implement controller movement
- Add state machine
- Draw small and big Mario
- Validate movement on flat ground

### Phase 3 - Level Basics

- Build `world_1_1.tscn`
- Add terrain tilemap
- Add camera, bounds, and kill zone
- Add parallax/background layers
- Add HUD

### Phase 4 - Blocks and Items

- Question blocks
- Brick blocks
- Hidden blocks
- Coins
- Mushroom and Fire Flower
- Power-state transitions

### Phase 5 - Enemies

- Enemy base
- Goomba
- Koopa
- Koopa shell
- Stomp and damage logic
- Enemy activation/cleanup

### Phase 6 - Effects and Polish

- Particles
- Glow shader
- Damage flash
- Screen shake
- Score popups
- Motion trails

### Phase 7 - Advanced Gameplay

- Fire Mario and fireballs
- Starman
- Piranha Plant
- Pipe warps
- Flagpole sequence
- Timer countdown

### Phase 8 - Menus and Loop

- Title screen
- Pause menu
- Level intro
- Game over
- Level complete flow

### Phase 9 - Audio

- Add placeholder or final assets
- Wire EventBus-to-audio responses
- Tune volume mix

### Phase 10 - Expansion

- Fill out the full World 1-1 pass
- Add hidden 1-UP spots and polish
- Stretch goal: World 1-2 underground level

---

## 16. Architectural Decisions

1. `CharacterBody2D` over `RigidBody2D` for the player because platformer controls require direct, deterministic movement.

2. `TileMapLayer` for terrain and separate scenes for interactive objects because blocks, pipes, and items have custom logic.

3. A dedicated player state machine because movement, damage, growth, pipes, and flagpole behavior would otherwise create brittle condition chains.

4. EventBus-based decoupling because HUD, audio, scoring, and effects should react without hard scene dependencies.

5. Forward Plus renderer because the visual pitch depends on subtle bloom and post-processing.

6. `_draw()`-driven character rendering because the project intentionally avoids sprite production and benefits from procedural animation control.

7. A 16 px grid because it preserves Mario-style spacing and keeps scene authoring simple.

---

## 17. Open Questions

All previously open questions have been resolved:

- **Movement feel:** Implemented. See `scripts/player/` — the current physics constants and state machine define the canonical feel for this project.
- **Hidden blocks:** Classic SMB behavior — no visuals and no collision until hit from below while the player is moving upward. See §9.3.
- **Title screen:** Static for v1. No attract/demo playback.
- **World 1-2 scope:** Included in v1 scope (not a stretch goal).
