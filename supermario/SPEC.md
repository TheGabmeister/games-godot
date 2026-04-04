# SPEC.md — Super Mario Bros (Godot 4.6)

A 2D modernized recreation of Super Mario Bros using only primitive shapes and Godot's drawing tools. No sprites or textures. Cool visual effects (particles, shaders, glow, screen shake). Audio system skeleton ready for asset drop-in.

---

## 1. Project Configuration

### Display

| Setting | Value |
|---------|-------|
| Viewport | 512 x 448 |
| Window | 1024 x 896 (2x) |
| Stretch mode | `canvas_items` |
| Stretch aspect | `keep` |
| Tile grid | 16 x 16 px |

This gives 32x28 tiles visible, proportional to the NES 256x224 resolution.

### Renderer

Keep **Forward Plus** — required for `WorldEnvironment` glow/bloom post-processing on the 2D canvas. The `Compatibility` renderer lacks this pipeline. Performance cost is negligible for a 2D game.

### Physics

The existing `Jolt Physics` setting only affects 3D. Godot 4.x always uses GodotPhysics2D for 2D regardless. No change needed.

### Input Map

| Action | Keys | Gamepad |
|--------|------|---------|
| `move_left` | A, Left Arrow | D-Pad Left, Stick Left |
| `move_right` | D, Right Arrow | D-Pad Right, Stick Right |
| `jump` | Space, W, Up Arrow | A / Cross |
| `run` | Shift, J | X / Square |
| `crouch` | S, Down Arrow | D-Pad Down, Stick Down |
| `pause` | Escape, P | Start |

---

## 2. Directory Structure

```
res://
  scenes/
    main.tscn
    ui/
      title_screen.tscn
      hud.tscn
      game_over.tscn
      pause_menu.tscn
      level_complete.tscn
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
      coin.tscn
      mushroom.tscn
      fire_flower.tscn
      starman.tscn
      fireball.tscn
      flagpole.tscn
      pipe.tscn
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
      coin.gd
      power_up_base.gd
      mushroom.gd
      fire_flower.gd
      starman.gd
      fireball.gd
      flagpole.gd
      pipe.gd
    ui/
      hud.gd
      title_screen.gd
      game_over.gd
      pause_menu.gd
      level_complete.gd
    level/
      level_base.gd
      enemy_spawner.gd
      kill_zone.gd

  shaders/
    glow_pulse.gdshader
    star_power.gdshader
    background_gradient.gdshader
    damage_flash.gdshader
    outline.gdshader

  resources/
    color_palette.tres
    default_bus_layout.tres
```

---

## 3. Autoloads

Registered in `project.godot`:

```
EventBus       = "*res://scripts/autoloads/event_bus.gd"
GameManager    = "*res://scripts/autoloads/game_manager.gd"
AudioManager   = "*res://scripts/autoloads/audio_manager.gd"
SceneManager   = "*res://scripts/autoloads/scene_manager.gd"
CameraEffects  = "*res://scripts/autoloads/camera_effects.gd"
```

### 3.1 EventBus

Central signal hub — all cross-system communication goes through here. No node needs a direct reference to another.

```gdscript
# Player
signal player_died
signal player_respawned
signal player_powered_up(power_up_type: StringName)
signal player_damaged
signal player_star_power_started
signal player_star_power_ended

# Scoring
signal coin_collected(position: Vector2)
signal score_changed(new_score: int)
signal lives_changed(new_lives: int)
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

# Blocks
signal block_bumped(position: Vector2)
signal block_broken(position: Vector2)
signal item_spawned(item_type: StringName, position: Vector2)

# Game state
signal game_over
signal game_paused
signal game_resumed
```

### 3.2 GameManager

Tracks global game state that persists across scene transitions.

**State:**
- `score: int` — starts 0
- `coins: int` — starts 0, awards 1-UP at 100
- `lives: int` — starts 3
- `time_remaining: float` — starts 400, decrements each second during play
- `current_world: int`, `current_level: int`
- `current_power_state: PowerState` — enum `{SMALL, BIG, FIRE}`
- `game_state: GameState` — enum `{TITLE, PLAYING, PAUSED, GAME_OVER, LEVEL_COMPLETE, TRANSITIONING}`

**State transitions:**
```
TITLE → PLAYING (start game)
PLAYING ↔ PAUSED (pause input)
PLAYING → LEVEL_COMPLETE → TRANSITIONING → PLAYING (next level)
PLAYING → GAME_OVER (lives == 0 after death)
GAME_OVER → TITLE
```

**Responsibilities:**
- Score/coin/lives tracking with EventBus emissions
- Coin-to-1UP conversion (every 100 coins)
- Countdown timer (pauses during non-PLAYING states)
- Time bonus at level end (remaining_time × 50 points)
- Death/respawn orchestration

### 3.3 AudioManager

Skeleton design — no audio assets needed yet. Drop in `.wav`/`.ogg` files later by filling the registry paths.

**Audio bus layout:**
```
Master
  ├── Music
  ├── SFX
  │    ├── Player
  │    ├── Enemies
  │    └── Items
  └── UI
```

**Registry pattern:**
```gdscript
var _sfx_registry: Dictionary[StringName, String] = {
    &"jump": "", &"jump_big": "", &"stomp": "", &"coin": "",
    &"block_bump": "", &"block_break": "", &"powerup": "",
    &"powerdown": "", &"fireball": "", &"kick": "", &"pipe": "",
    &"1up": "", &"death": "", &"flagpole": "", &"game_over": "",
    &"stage_clear": "", &"warning": "",
}

var _music_registry: Dictionary[StringName, String] = {
    &"overworld": "", &"underground": "", &"star": "", &"hurry": "",
}
```

To add audio later: fill in paths like `"res://audio/sfx/jump.wav"`. If a path is empty, `play_sfx()` / `play_music()` silently no-ops.

**Key methods:**
- `play_sfx(sound_name: StringName, position: Vector2 = Vector2.ZERO) -> void`
- `play_music(music_name: StringName) -> void` — crossfades between two `AudioStreamPlayer` nodes
- `stop_music() -> void`

**SFX pool:** 10 `AudioStreamPlayer` + 6 `AudioStreamPlayer2D` nodes, round-robin for concurrent sounds.

**Signal connections** (in `_ready`): Listens to EventBus signals (`coin_collected` → `play_sfx("coin")`, `player_died` → `play_sfx("death")` + `stop_music()`, etc.)

### 3.4 SceneManager

Handles scene transitions with fade effects.

- `CanvasLayer` at layer 100 with a full-screen `ColorRect` overlay
- `change_scene(path: String)` — tween fade out (0.5s), load scene, tween fade in (0.5s)
- `reload_current_scene()` — for death/retry
- Optional level-intro overlay ("WORLD 1-1" / Mario × lives) displayed between transitions for 2.5s

### 3.5 CameraEffects

Controls screen effects applied to the active `Camera2D`.

- `shake(intensity: float, duration: float)` — random offset applied each frame during duration
- `freeze_frame(duration: float)` — brief engine pause for impact

**Shake presets:**
| Event | Intensity | Duration |
|-------|-----------|----------|
| Enemy stomp | 2 | 0.1s |
| Brick break | 4 | 0.15s |
| Player death | 6 | 0.3s |

---

## 4. Visual Style

All visuals use primitive shapes (`Polygon2D`, `Line2D`, `draw_*` methods, `ColorRect`). No textures or sprites. 16px grid.

### 4.1 Color Palette

```
# Sky / Background
SKY_BLUE          = Color(0.35, 0.65, 0.95)
SKY_UNDERGROUND   = Color(0.05, 0.05, 0.08)
CLOUD_WHITE       = Color(0.95, 0.95, 0.98)

# Ground / Terrain
GROUND_BROWN      = Color(0.55, 0.35, 0.15)
GROUND_GREEN      = Color(0.25, 0.65, 0.25)
BRICK_RED         = Color(0.72, 0.30, 0.18)
BRICK_DARK        = Color(0.55, 0.22, 0.12)

# Mario
MARIO_RED         = Color(0.90, 0.15, 0.15)
MARIO_SKIN        = Color(0.95, 0.75, 0.55)
MARIO_BLUE        = Color(0.20, 0.30, 0.75)
MARIO_FIRE_WHITE  = Color(0.95, 0.95, 0.95)

# Enemies
GOOMBA_BROWN      = Color(0.55, 0.30, 0.15)
GOOMBA_DARK       = Color(0.35, 0.18, 0.08)
KOOPA_GREEN       = Color(0.20, 0.70, 0.25)
KOOPA_SHELL       = Color(0.15, 0.55, 0.20)
PIRANHA_GREEN     = Color(0.15, 0.60, 0.15)
PIRANHA_RED       = Color(0.80, 0.15, 0.12)

# Objects
PIPE_GREEN        = Color(0.18, 0.60, 0.22)
PIPE_GREEN_LIGHT  = Color(0.28, 0.72, 0.32)
QUESTION_YELLOW   = Color(0.95, 0.80, 0.20)
QUESTION_DARK     = Color(0.70, 0.55, 0.10)
COIN_GOLD         = Color(1.0, 0.85, 0.20)
COIN_SHINE        = Color(1.0, 0.95, 0.60)
BLOCK_BROWN       = Color(0.50, 0.35, 0.20)
STAR_YELLOW       = Color(1.0, 0.90, 0.15)
FIRE_ORANGE       = Color(1.0, 0.55, 0.10)
FIRE_RED          = Color(1.0, 0.25, 0.10)
MUSHROOM_RED      = Color(0.90, 0.15, 0.15)
MUSHROOM_CREAM    = Color(0.95, 0.90, 0.80)
```

### 4.2 Character and Object Rendering

All characters use custom `_draw()` on a `Node2D` child. This allows programmatic squash/stretch, palette swaps, and animation without external assets.

**Mario (Small — 16×16):**
- Body: rectangle (12×10) in `MARIO_BLUE` (overalls)
- Head: rectangle (10×6) in `MARIO_SKIN` above body
- Hat: rectangle (12×3) in `MARIO_RED` on top, slight brim overhang
- Eyes: two 2×2 white squares with 1×1 black pupils
- Feet: two small rectangles in brown
- Power state changes swap colors (Fire: red → white, blue → red)

**Mario (Big — 16×32):**
- Same shapes scaled vertically. Body becomes 12×18, head taller.
- Belt line: 1px dark line separating shirt from overalls.

**Goomba (16×16):**
- Body: rounded trapezoid `Polygon2D` (wider at bottom) in brown
- Head: dome on top (wider polygon arc)
- Feet: two small dark rectangles, alternating for walk animation
- Eyes: white circles with angry angled brow lines via `draw_line`
- Death: scale Y → 0.3 over 0.15s (squish), then fade

**Koopa Troopa (16×24):**
- Shell: oval/capsule `Polygon2D` in green
- Head: small circle poking above shell
- Feet: two orange rectangles, bobbing walk

**Koopa Shell (16×16):**
- Oval `Polygon2D` in dark green
- Highlight `Line2D` stripe on top
- Motion trail `Line2D` when moving (6-8 points, fading alpha)

**Pipe (32 × variable height):**
- Top rim: wider rectangle (32×16) with light/dark green
- Shaft: narrower rectangle (28×height) centered
- Highlight stripe down left side via `Line2D`
- Dark ellipse at opening for inner shadow

**Brick Block (16×16):**
- Base `ColorRect` in `BRICK_RED`
- Grid of `draw_line` in `BRICK_DARK` for mortar pattern
- Bump: tween Y -4px and back (0.1s)
- Break: 4 triangular polygon fragments launched with velocity and gravity

**Question Block (16×16):**
- Base in `QUESTION_YELLOW` with `QUESTION_DARK` border
- "?" drawn with `draw_string` or polygon glyph, centered
- `glow_pulse.gdshader` for pulsing glow
- After hit: becomes `BLOCK_BROWN`, "?" removed

**Coin (8×14):**
- Thin vertical ellipse in `COIN_GOLD`, inner ellipse in `COIN_SHINE`
- Spin animation: modulate scale X sinusoidally (faux-3D rotation)
- `glow_pulse.gdshader` for subtle glow
- Collection: pop + sparkle `GPUParticles2D` burst

**Mushroom (16×16):**
- Cap: semicircle `Polygon2D` in red with white oval spots
- Stem: rectangle in cream below cap
- Emerges from block via tween (rise over 0.3s)

**Fire Flower (16×16):**
- Green stem, 4-5 radial petal circles in orange/red, yellow center
- Gentle pulsing scale animation

**Starman (16×16):**
- Five-pointed star `Polygon2D` (10 vertices) in yellow
- `star_power.gdshader` for rainbow cycling
- Sine-wave bounce animation

**Flagpole:**
- Pole: vertical `Line2D` (3px) in silver
- Flag: green triangle `Polygon2D`, tweens down on capture
- Gold orb at top via `draw_circle`

**Background decorations:**
- Clouds: overlapping white circles (3 per cloud), low opacity
- Hills: large green semicircles on background parallax layer
- Bushes: same as clouds but green, at ground level

**Ground tiles (TileMapLayer):**
- `ground_top`: solid brown with 2px green top stripe
- `ground_fill`: solid brown
- Tiles use a small programmatically-generated atlas or modulated white base tile

### 4.3 Shaders and Effects

**`glow_pulse.gdshader`** (CanvasItem):
- Applied to coins, question blocks, star
- Oscillates brightness with `sin(TIME * pulse_speed) * glow_intensity`
- Adds bloom-like halo via expanded UV with soft edge blend

**`star_power.gdshader`** (CanvasItem):
- Cycles hue of entire node: `fract(TIME * cycle_speed)`
- Applied to Mario during star invincibility and starman item

**`damage_flash.gdshader`** (CanvasItem):
- Uniform `flash_amount` (0–1), mixes color toward white
- Triggered by a quick tween ramp up/down

**`outline.gdshader`** (CanvasItem):
- 1px dark outline around characters for readability
- Samples neighboring pixels; draws outline where opaque meets transparent

**`background_gradient.gdshader`** (CanvasItem):
- Vertical gradient from light blue (top) to darker blue (bottom)
- Applied to a full-screen `ColorRect` on background `CanvasLayer`

**GPUParticles2D:**

| Effect | Particles | Shape | Behavior |
|--------|-----------|-------|----------|
| Coin collect | 8-12 gold squares | Radial burst | Fade over 0.3s |
| Brick break | 4-6 brown rectangles | Explosive + gravity | Random rotation |
| Stomp kill | 6-8 white/gray circles | Expanding outward | Quick fade |
| Fireball hit | 10 orange/red particles | Burst | Fade over 0.2s |
| Power-up acquire | Ring of colored particles | Expanding ring | Fade |
| Fireworks | Large colored bursts | Various | End-of-level |

**Trails:**
- Koopa shell: `Line2D` with 6-8 fading points updated each frame
- Fireball: `Line2D` trail in orange/yellow
- Star power Mario: afterimage — spawn fading semi-transparent copy every 3 frames

**WorldEnvironment** (attached to main scene):
- Glow/bloom enabled: threshold 0.8, intensity 0.3, additive blend
- Makes coins, question blocks, fire, and star effects bloom subtly
- This is why we keep Forward Plus renderer

---

## 5. Player Controller

`CharacterBody2D` with state machine pattern.

### 5.1 Scene Hierarchy

```
Player (CharacterBody2D)
  ├── CollisionShape2D (RectangleShape2D, resizes with power state)
  ├── Visuals (Node2D, flip scale.x for facing direction)
  │    └── PlayerDrawer (Node2D, custom _draw() via player_drawer.gd)
  ├── StateMachine (Node, state_machine.gd)
  │    ├── IdleState
  │    ├── RunState
  │    ├── JumpState
  │    ├── FallState
  │    ├── CrouchState
  │    ├── DeathState
  │    ├── GrowState
  │    ├── ShrinkState
  │    ├── PipeEnterState
  │    └── FlagpoleState
  ├── AnimationPlayer (squash/stretch, invincibility blink)
  ├── CoyoteTimer (Timer, 0.08s)
  ├── JumpBufferTimer (Timer, 0.1s)
  ├── InvincibilityTimer (Timer, 2.0s)
  ├── StarTimer (Timer, 10.0s)
  ├── FireballCooldown (Timer, 0.25s)
  ├── Camera2D
  └── StompDetector (Area2D below feet)
```

### 5.2 Physics Constants

```
WALK_SPEED        = 130.0    # px/s
RUN_SPEED         = 210.0    # px/s
ACCELERATION      = 800.0    # ground accel
DECELERATION      = 1200.0   # ground braking
AIR_ACCELERATION  = 600.0    # reduced air control
TURN_ACCELERATION = 1600.0   # skid turnaround
JUMP_VELOCITY     = -330.0   # initial jump impulse (up)
JUMP_RELEASE_MULT = 0.5      # velocity × this on early release
GRAVITY           = 900.0    # standard
FAST_FALL_GRAVITY = 1400.0   # after releasing jump while ascending
MAX_FALL_SPEED    = 500.0    # terminal velocity
COYOTE_TIME       = 0.08     # seconds after leaving edge
JUMP_BUFFER_TIME  = 0.1      # seconds before landing
```

### 5.3 Core Mechanics

**Variable-height jump:** The defining mechanic. Tap = short hop, hold = full height. When jump is released while ascending, apply `FAST_FALL_GRAVITY` and multiply velocity by `JUMP_RELEASE_MULT`.

**Running:** Hold `run` to increase max speed from `WALK_SPEED` to `RUN_SPEED`. Running slightly increases jump height (multiplier on `JUMP_VELOCITY` when speed > `WALK_SPEED * 0.8`).

**Skidding:** When pressing opposite direction while moving above a speed threshold on ground, apply `TURN_ACCELERATION` and emit dust particles.

**Crouching:** Big/Fire Mario only. Hold `crouch` while on ground to duck — collision box shrinks to 16×16 (same as small Mario). Used to fit through 1-tile gaps. Small Mario ignores crouch input. Cannot move while crouching.

**Facing direction:** The `Visuals` node's `scale.x` flips to `-1` when moving left, `1` when moving right. The `_draw()` code always draws facing right; the flip handles the mirror.

**Coyote time:** 0.08s window to jump after walking off an edge.

**Jump buffer:** 0.1s — pressing jump slightly before landing still registers.

### 5.4 State Machine

`state_machine.gd` (extends `Node`) manages the current state:
- Holds `current_state: PlayerState` reference
- Delegates `_process`, `_physics_process`, `_unhandled_input` to `current_state`
- `transition_to(state_name: StringName)` — calls `current_state.exit()`, sets new state, calls `new_state.enter()`
- Each state is a child node of the StateMachine node

Base state class:
```gdscript
class_name PlayerState extends Node
var player: CharacterBody2D
func enter() -> void: pass
func exit() -> void: pass
func process_input(event: InputEvent) -> void: pass
func process_frame(delta: float) -> void: pass
func process_physics(delta: float) -> void: pass
```

**State transitions:**
```
Idle → Run (move input), Jump (jump + on floor), Fall (off edge), Crouch (crouch + BIG/FIRE)
Run → Idle (stopped), Jump (jump), Fall (off edge)
Jump → Fall (ascending ended or jump released)
Fall → Idle (landed, no input), Run (landed + moving), Jump (landed + buffer active)
Crouch → Idle (crouch released), Jump (jump while crouching, stand up first)
Any → Death (killed)
Any → Grow/Shrink (power state change)
Flagpole → (terminal: level complete sequence)
Death → (terminal: respawn via GameManager)
```

**Grow/Shrink freeze:** On power state change, set `get_tree().paused = true`. The player's `AnimationPlayer` plays the grow/shrink animation with `process_mode = PROCESS_MODE_ALWAYS` so it runs during pause. On animation complete, unpause. This freezes all gameplay for ~0.5s while the transformation plays, matching SMB behavior.

---

## 6. Power-Up System

**Power states:** `enum PowerState { SMALL, BIG, FIRE }`

**Rules (matching SMB):**
- SMALL + Mushroom → BIG (grow animation, collision 16×16 → 16×32)
- SMALL + Fire Flower → BIG (same as mushroom when small)
- BIG + Fire Flower → FIRE (palette swap, gains fireball)
- BIG/FIRE + Damage → SMALL (shrink animation, 2s invincibility blink)
- SMALL + Damage → Death
- Any + Star → 10s invincibility, rainbow shader, kills enemies on contact

**Collision box:** `RectangleShape2D` resizes from `Vector2(12, 16)` to `Vector2(12, 30)`. Position adjusts so feet stay on ground.

**Fireball (FIRE state):**
- Press `run` to shoot (max 2 on screen)
- `CharacterBody2D` with small circle, `Line2D` trail
- 250 px/s horizontal, bounces off ground with slight arc
- Destroys on wall hit or enemy hit, spawns particle burst

---

## 7. Enemies

### 7.1 Enemy Base

`CharacterBody2D` with shared logic:
- `speed`, `gravity = 900.0`, `direction = -1.0` (left)
- Apply gravity, `move_and_slide`, reverse on wall
- `die()` and `stomp()` virtual methods
- `VisibleOnScreenNotifier2D` for off-screen cleanup (see 10.3)
- Enemies do NOT collide with each other — layer 3 does not mask layer 3. They walk through one another (matching SMB).

### 7.2 Goomba

- Walk at 40 px/s, reverse on walls/edges
- **Stomp:** squish (scale Y → 0.3), disable collision, queue_free after 0.5s. 100 points.
- **Die** (fireball/shell/star): flip upside down, fall off screen. 200 points.

### 7.3 Koopa Troopa

- Walk at 35 px/s, reverse on walls
- **Stomp:** replace with `koopa_shell.tscn` at same position. 100 points.
- **Die** (fireball/star): flip and fall. 200 points.

### 7.4 Koopa Shell

Two states: IDLE and MOVING.

- **IDLE:** sits still. Player kick on contact → MOVING.
- **MOVING:** 300 px/s. Kills enemies it hits. Bounces off walls. Damages player from side/below. Player can stomp a moving shell to stop it.
- **Combo system:** consecutive enemy kills by same shell award escalating points: 500, 800, 1000, 2000, 5000, 8000, 1-UP.
- `Line2D` motion trail when moving.

### 7.5 Piranha Plant

- No physics — uses tween for vertical bob from pipe
- Cycle: 1.5s emerge, 1.0s wait, 1.5s retreat, 2.0s hidden
- Does NOT emerge if player is adjacent to pipe (check x-distance)
- No stomp hitbox — contact only. Killed by fireball or star.

### 7.6 Pipe Warp

Pipes with `export var warp_target: NodePath` enable warp. Entry requires player standing on top and holding `crouch`. Sequence:
1. Player enters `PipeEnterState` — disable input, tween player Y downward into pipe over 0.5s
2. Play `AudioManager.play_sfx("pipe")`
3. `SceneManager` transitions (fade to black)
4. Spawn player at target pipe's exit position, tween player Y upward out of pipe over 0.5s
5. Resume normal state

Pipes without `warp_target` are purely decorative/collision obstacles.

---

## 8. Blocks

### 8.1 Question Block

`StaticBody2D` with `export var contents: StringName = "coin"` — values: `"coin"`, `"mushroom"`, `"fire_flower"`, `"star"`, `"1up_mushroom"`.

**When hit from below:**
1. Bump animation (tween Y -4px and back)
2. Spawn contents above block
3. Visual → empty block (brown, no "?")
4. Kill any enemy standing on top (check `Area2D` overlap on top face — enemy calls `die()`)
5. Emit `EventBus.block_bumped` + `EventBus.item_spawned`

**Context-sensitive spawning:** If contents is `"mushroom"` and player is BIG/FIRE, spawn Fire Flower instead (matching SMB behavior).

**Hit detection:** `Area2D` on bottom face, triggered when player collides while moving upward (velocity.y < 0).

### 8.2 Brick Block

`StaticBody2D` with optional `export var coin_count: int = 0` for multi-coin bricks.

**When hit from below:**
- **Player is SMALL:** bump only (can't break). Knocks enemies on top.
- **Player is BIG/FIRE:** break. Spawn 4 fragment particles. Remove block. 50 points. Emit `EventBus.block_broken`.
- **Multi-coin:** each hit gives 1 coin + bounce. After all coins, becomes empty.

---

## 9. Collision Layers

| Layer | Name | Used By |
|-------|------|---------|
| 1 | Terrain | Ground tiles, blocks, pipes |
| 2 | Player | Mario CharacterBody2D |
| 3 | Enemies | Goomba, Koopa CharacterBody2D |
| 4 | PlayerHitbox | Area2D on player for overlap detection |
| 5 | EnemyHitbox | Area2D on enemies for stomp/hit |
| 6 | Items | Coins, power-ups (Area2D triggers) |
| 7 | Fireballs | Player fireballs |
| 8 | KoopaShell | Moving shell |
| 9 | KillZone | Bottom-of-screen pit |
| 10 | Interactable | Pipes, flagpole |

**Mask rules — CharacterBody2D (physics collisions via `move_and_slide`):**
- Player body (layer 2) masks: 1 (Terrain)
- Enemies body (layer 3) masks: 1 (Terrain)
- Items body (layer 6) masks: 1 (Terrain)
- Fireballs body (layer 7) masks: 1 (Terrain)
- KoopaShell body (layer 8) masks: 1 (Terrain)

**Mask rules — Area2D (overlap detection via signals):**
- PlayerHitbox (layer 4) masks: 5 (EnemyHitbox), 6 (Items), 9 (KillZone), 10 (Interactable)
- EnemyHitbox (layer 5) masks: 4 (PlayerHitbox), 7 (Fireballs), 8 (KoopaShell)
- KillZone (layer 9) masks: 2 (Player), 3 (Enemies)

**Enemy-enemy interaction:** Enemies do NOT collide with each other (matching SMB). They walk through one another. Enemies on layer 3 do not mask layer 3.

---

## 10. Level System

### 10.1 Level Scene Structure

```
Level_1_1 (Node2D)
  ├── Background (CanvasLayer, layer -1)
  │    ├── SkyGradient (ColorRect + background_gradient.gdshader)
  │    ├── Clouds (Node2D, Polygon2D children, parallax via script)
  │    └── Hills (Node2D, Polygon2D children, parallax)
  ├── TileMapLayer_Ground (terrain collision tiles)
  ├── Blocks (Node2D)
  │    ├── QuestionBlock instances
  │    └── BrickBlock instances
  ├── Pipes (Node2D)
  ├── Coins (Node2D)
  ├── Enemies (Node2D)
  │    └── EnemySpawner (activates enemies as camera approaches)
  ├── Interactables (Node2D)
  │    └── Flagpole
  ├── KillZone (Area2D, full-width below screen)
  ├── LevelBounds (StaticBody2D, left wall prevents backtracking)
  ├── Player (instance)
  ├── HUD (CanvasLayer)
  └── WorldEnvironment (glow/bloom)
```

### 10.2 TileMap

Only non-interactive terrain uses `TileMapLayer`. Blocks with behavior are individual scene instances.

Tiles (16×16): `ground_top` (brown + green stripe), `ground_fill` (solid brown). Created programmatically with `ImageTexture` or modulated white base tile.

### 10.3 Enemy Spawner

- Enemies start with `process_mode = PROCESS_MODE_DISABLED`, hidden
- **Activation:** EnemySpawner checks each frame — when an enemy's X is within 320px of camera's right edge, enable and show it. One-time activation only.
- **Cleanup:** Each enemy has a `VisibleOnScreenNotifier2D`. When an activated enemy leaves the screen *below* (fell into pit, knocked off), it calls `queue_free()`. Enemies that scroll off the left edge are also freed.
- No respawning — once activated and removed, gone for the session

### 10.4 Camera

`Camera2D` (child of Player):
- Horizontal follow only, Y fixed per level
- `position_smoothing_enabled = true`, speed 10.0
- `limit_left = 0` (no backtracking), `limit_right = level_width`
- Slight look-ahead: offset X based on facing direction, tweened smoothly

---

## 11. World 1-1 Layout

Level is ~3392px wide (212 tiles × 16px), 14 tiles tall playable area. Ground at Y rows 12-13.

```
Section 1 (X: 0-50) — Starting area
  - Flat ground (rows 12-13), player spawn at tile (3, 11)
  - Question block (coin) at (16, 8)
  - Row at Y=8: Brick, Question (mushroom), Brick, Question (coin), Brick at X: 20-24
  - High question block (coin) at (22, 4)
  - Goomba at (22, 11)
  - Goomba pair at (40-41, 11)

Section 2 (X: 50-90) — Pipes
  - Pipe (h=2) at (56, 10)
  - Pipe (h=3) at (64, 9)
  - Pipe (h=4) at (72, 8)
  - Pipe (h=4, warp) at (80, 8)

Section 3 (X: 90-130) — Gaps and koopa
  - First pit: X 91-92 (2 tiles wide)
  - Brick row at Y=8 near X 100, one contains hidden star
  - Koopa at (106, 11)
  - Second pit: X 112-114 (3 tiles wide)

Section 4 (X: 130-170) — Block structures
  - Floating brick/question rows at Y=4 and Y=8
  - Two Goombas patrolling platforms
  - Multi-coin brick at (148, 8)
  - Third pit: X 158-160

Section 5 (X: 170-200) — Staircases
  - Staircase up (1-4 blocks high) at X 178-181
  - Gap between staircases
  - Staircase down (4-1 blocks) at X 184-187
  - Goomba pair at (192-193, 11)

Section 6 (X: 200-212) — Flagpole
  - Final staircase (1-8 blocks high) at X 198-205
  - Flagpole at X 206
  - Castle (rectangle + triangle roof, Polygon2D) at X 208-211
```

**Background decorations** (repeating every ~48 tiles): hills at X 0, 48, 96, 160 — clouds at Y 2-3 at X 8, 19, 27, 36 — bushes at ground level at X 11, 23, 41.

---

## 12. Scoring

| Event | Points |
|-------|--------|
| Coin | 200 |
| Stomp Goomba/Koopa | 100 |
| Fireball kill | 200 |
| Brick break | 50 |
| Mushroom/Fire Flower/Star | 1000 |
| Consecutive stomps | 100, 200, 400, 500, 800, 1000, 2000, 4000, 5000, 8000, 1-UP |
| Shell combo kills | 500, 800, 1000, 2000, 5000, 8000, 1-UP |
| Flagpole (height-based) | 100–5000 |
| Time bonus | remaining_time × 50 |

**Score popup:** Floating label at award position, tweens up 20px and fades over 0.5s.

---

## 13. HUD

```
HUD (CanvasLayer, layer 10)
  └── MarginContainer
       └── HBoxContainer
            ├── VBox: "MARIO" / ScoreLabel "000000"
            ├── VBox: CoinIcon / CoinLabel "×00"
            ├── VBox: "WORLD" / WorldLabel "1-1"
            └── VBox: "TIME" / TimeLabel "400"
```

- White text, 1px black shadow (via `LabelSettings`)
- Score: 6 digits with leading zeros
- Timer turns red and pulses below 100
- Coin icon: tiny animated gold polygon matching in-game coin

---

## 14. Game Flow

```
main.tscn
  → Title Screen ("SUPER MARIO BROS", "PRESS START" blinking)
  → Level Intro (black screen, "WORLD 1-1", Mario × lives, 2.5s)
  → Gameplay
      ├── Death → animation → lives-1 → level intro (or Game Over if lives=0)
      ├── Flagpole → slide → walk to castle → time bonus → fireworks → next level
      └── Pause → overlay, tree.paused=true
  → Game Over ("GAME OVER", 3s, back to title)
```

---

## 15. Implementation Phases

**Phase 1 — Foundation**
Directory structure, project.godot settings (display, input, autoloads), EventBus, GameManager, AudioManager skeleton, SceneManager, CameraEffects.

**Phase 2 — Player**
player.tscn, player_controller.gd, state_machine.gd, player_drawer.gd, states (idle/run/jump/fall/crouch), `_draw()` for Small + Big Mario, test on flat ground.

**Phase 3 — Level Structure**
TileSet with colored tiles, world_1_1.tscn terrain, Camera2D with limits, KillZone, background (sky gradient, clouds, hills), HUD.

**Phase 4 — Blocks and Items**
Question block (bump, spawn, empty), brick block (bump, break), coins (static + pop-out), mushroom (emerge, move, collect → grow), power state changes, death state + respawn.

**Phase 5 — Enemies**
Enemy base, Goomba, Koopa, Koopa Shell, stomp detection, player damage, enemy spawner.

**Phase 6 — Effects and Polish**
glow_pulse shader, GPUParticles2D (coin/brick/stomp), screen shake, outline shader, score popups, trails, star_power shader, WorldEnvironment bloom.

**Phase 7 — Advanced Gameplay**
Fire Flower + Fire Mario + fireballs, Starman + invincibility, Piranha Plant, pipe warps, flagpole + level complete sequence, stomp combos, time countdown.

**Phase 8 — Menus and Flow**
Title screen, level intro, game over, pause menu, complete game loop.

**Phase 9 — Audio**
Source/create placeholder audio, fill registry paths, test all signal→audio connections, tune volumes.

**Phase 10 — Level Expansion**
Complete World 1-1 layout, hidden blocks, 1-UP locations, warp zones, World 1-2 (underground) stretch goal.

---

## 16. Key Architectural Decisions

1. **CharacterBody2D over RigidBody2D** for player — platformers need deterministic, frame-precise movement. `move_and_slide` gives direct velocity control.

2. **Individual scenes for blocks, TileMap for terrain** — blocks have behavior (bump, break, spawn). TileMap tiles are static. This separation is clean and performant.

3. **State machine for player** — many distinct modes (idle, run, jump, fall, death, grow, shrink, pipe, flagpole). Prevents spaghetti if/else in `_physics_process`.

4. **EventBus for decoupling** — enemies don't need to know about the HUD. AudioManager just listens. Any node emits/listens without structural dependencies.

5. **Forward Plus renderer** — enables WorldEnvironment glow/bloom post-processing. Worth the minor overhead for the visual polish.

6. **`_draw()` for character visuals** — programmatic control over every vertex. Enables squash/stretch, palette swaps, and animation without external assets. Keeps visuals in code, matching the no-texture constraint.

7. **16px grid** — proportional to NES tile size. At 512×448 viewport, gives 32×28 tiles visible. Correct spacing for Mario-style gameplay.
