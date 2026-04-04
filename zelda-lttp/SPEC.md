# SPEC - Zelda: A Link to the Past - Mechanics Recreation in Godot 4.6

## Project Overview

A mechanics-faithful recreation of The Legend of Zelda: A Link to the Past (SNES, 1991) built in Godot 4.6. The project recreates game feel, interaction rules, combat rhythms, exploration flow, and progression structure without relying on original sprites or audio assets.

All visuals are rendered from primitive shapes, shaders, particles, and 2D lighting. Audio is implemented through a placeholder-first API that can log events now and accept real assets later without changing gameplay code.

### Goals

1. Recreate the core feel of ALTTP movement, combat, exploration, and progression.
2. Build the game in clean, modular Godot 4.6 architecture that can scale from a prototype to a multi-dungeon project.
3. Ship each phase as a playable vertical slice, not just a pile of unfinished systems.
4. Keep art and audio implementation legally clean by using original primitive visuals and placeholder-friendly hooks.

### Non-Goals

1. Pixel-perfect reproduction of SNES art, animation frames, or sound.
2. A byte-for-byte clone of ALTTP map layout, scripting, or hidden values.
3. Multiplayer, networking, procedural generation, or mod tooling.
4. Full content parity with the original game before the core game loop is stable.

### Design Principles

1. Mechanics first - if a system looks abstract but feels right, that is acceptable.
2. Primitive art, polished feedback - the visual language should be simple but deliberate.
3. Additive milestones - every phase must keep earlier work intact.
4. Data-driven content - items, enemies, drops, and dungeons should be defined by resources where practical.
5. Small, testable scenes - scenes own presentation and local behavior; autoloads own global state.
6. Swap-ready audio - gameplay calls stable methods, whether assets exist yet or not.

### Technical Foundation

- Engine: Godot 4.6, GDScript
- Renderer: Forward Plus (already configured; supports the 2D lighting and shader effects this project uses)
- Resolution: 256x224 logical pixels, integer-scaled to 1024x896 by default
- Stretch settings: `display/window/stretch/mode = "viewport"`, `display/window/stretch/aspect = "keep"`
- Physics: Godot built-in 2D physics only
- Tile size: 16x16 base grid
- Health unit: 1 unit = half a heart
- Starting health: 6 units = 3 hearts
- Max health display: hearts, with 2 units per heart
- Magic meter: 0-128 units
- Input targets: keyboard and gamepad for all gameplay actions

### Core Conventions

- The player is a persistent scene instance created once per run and reparented into the active room's `Entities` node during transitions.
- The sword is always available. There is one active item slot, not two.
- Room scripts must expose a stable `room_id: StringName` for persistence and analytics (e.g., `light_overworld_0_0`, `dungeon_01_room_03`). Set via `@export`, never derived from the file name at runtime.
- Every persistent entity (chest, push block, switch, boss, locked door) must have an `@export var persist_id: StringName` set in the editor. This is a stable identifier that never changes even if the node is renamed or reparented. Flag keys are built as `{room_id}/{persist_id}` (e.g., `light_overworld_0_0/chest_north`).
- The editor should warn (via `_get_configuration_warnings()`) if `persist_id` is empty on a persistent entity.
- JSON save data must include a schema version so future migrations are possible.
- All phase deliverables must be testable from either the normal game flow or [`debug/debug_room.tscn`](/c:/dev/games-godot/zelda-lttp/debug/debug_room.tscn) once that scene exists.

---

## Directory Structure

```text
res://
|-- autoloads/
|   |-- event_bus.gd
|   |-- game_manager.gd
|   |-- inventory_manager.gd
|   |-- audio_manager.gd
|   |-- scene_manager.gd
|   `-- save_manager.gd
|-- components/
|   |-- state_machine.tscn/.gd
|   |-- state.gd
|   |-- health_component.tscn/.gd
|   |-- hitbox_component.tscn/.gd
|   |-- hurtbox_component.tscn/.gd
|   |-- loot_drop_component.tscn/.gd
|   |-- flash_component.tscn/.gd
|   `-- knockback_component.tscn/.gd
|-- scenes/
|   |-- main/
|   |   `-- main.tscn/.gd
|   |-- player/
|   |   |-- player.tscn/.gd
|   |   |-- states/
|   |   |   |-- player_state.gd
|   |   |   |-- idle_state.gd
|   |   |   |-- walk_state.gd
|   |   |   |-- attack_state.gd
|   |   |   |-- knockback_state.gd
|   |   |   |-- fall_state.gd
|   |   |   |-- dash_state.gd
|   |   |   |-- item_use_state.gd
|   |   |   |-- item_get_state.gd
|   |   |   `-- swim_state.gd
|   |   `-- components/
|   |       `-- shield_component.tscn/.gd
|   |-- enemies/
|   |   |-- base_enemy.gd          # Script base class only, no base .tscn
|   |   |-- enemy_state.gd         # Base EnemyState class
|   |   |-- soldier/
|   |   |   |-- soldier.tscn/.gd
|   |   |   `-- states/            # States unique to this enemy
|   |   |       |-- soldier_patrol.gd
|   |   |       |-- soldier_chase.gd
|   |   |       `-- soldier_attack.gd
|   |   |-- octorok/
|   |   |   |-- octorok.tscn/.gd
|   |   |   `-- states/
|   |   |       |-- octorok_wander.gd
|   |   |       `-- octorok_shoot.gd
|   |   |-- keese/
|   |   |   `-- keese.tscn/.gd     # Simple enough for one script, no subfolder states
|   |   |-- stalfos/
|   |   |   |-- stalfos.tscn/.gd
|   |   |   `-- states/
|   |   |       |-- stalfos_wander.gd
|   |   |       `-- stalfos_throw.gd
|   |   `-- buzz_blob/
|   |       `-- buzz_blob.tscn/.gd  # Wander-only, one script
|   |-- bosses/
|   |   |-- base_boss.gd            # Script base class only, no base .tscn
|   |   `-- armos_knights/
|   |       |-- armos_knights.tscn/.gd
|   |       |-- armos_knight_unit.tscn/.gd
|   |       `-- states/
|   |-- items/
|   |   |-- base_item_effect.gd     # BaseItemEffect (RefCounted)
|   |   |-- effects/                # One script per active item
|   |   |   |-- bow_effect.gd
|   |   |   |-- bomb_effect.gd
|   |   |   |-- boomerang_effect.gd
|   |   |   |-- hookshot_effect.gd
|   |   |   |-- lamp_effect.gd
|   |   |   |-- fire_rod_effect.gd
|   |   |   |-- ice_rod_effect.gd
|   |   |   |-- magic_powder_effect.gd
|   |   |   `-- hammer_effect.gd
|   |   |-- sword_hitbox.tscn/.gd
|   |   |-- projectile_base.tscn/.gd
|   |   |-- arrow.tscn/.gd         # Spawned scenes (projectiles, bombs, etc.)
|   |   |-- bomb.tscn/.gd
|   |   |-- boomerang.tscn/.gd
|   |   |-- hookshot.tscn/.gd
|   |   `-- pickup.tscn/.gd
|   |-- world/
|   |   |-- room.tscn/.gd
|   |   |-- door.tscn/.gd
|   |   |-- locked_door.tscn/.gd
|   |   |-- boss_door.tscn/.gd
|   |   |-- chest.tscn/.gd
|   |   |-- push_block.tscn/.gd
|   |   |-- switch.tscn/.gd
|   |   |-- pressure_plate.tscn/.gd
|   |   |-- pit.tscn/.gd
|   |   |-- conveyor_belt.tscn/.gd
|   |   |-- destructible.tscn/.gd
|   |   `-- npc.tscn/.gd
|   |-- effects/
|   |   |-- impact_particles.tscn
|   |   |-- magic_particles.tscn
|   |   `-- dust_particles.tscn
|   |-- ui/
|   |   |-- hud.tscn/.gd
|   |   |-- hearts_display.tscn/.gd
|   |   |-- magic_meter.tscn/.gd
|   |   |-- rupee_counter.tscn/.gd
|   |   |-- item_slot.tscn/.gd
|   |   |-- minimap.tscn/.gd
|   |   |-- inventory_screen.tscn/.gd
|   |   |-- dialog_box.tscn/.gd
|   |   |-- title_screen.tscn/.gd
|   |   `-- game_over_screen.tscn/.gd
|   `-- maps/
|       |-- light_world/
|       |   |-- overworld_0_0.tscn
|       |   `-- ...
|       |-- dark_world/
|       |   |-- overworld_0_0.tscn
|       |   `-- ...
|       `-- dungeons/
|           |-- dungeon_01/
|           |   |-- room_00.tscn
|           |   `-- ...
|           `-- ...
|-- resources/
|   |-- item_data.gd
|   |-- enemy_data.gd
|   |-- loot_table.gd
|   |-- dungeon_data.gd
|   |-- room_data.gd
|   |-- items/
|   |   |-- sword_01.tres
|   |   |-- bow.tres
|   |   `-- ...
|   |-- enemies/
|   |   |-- soldier.tres
|   |   `-- ...
|   |-- dungeon_data/
|   |   `-- dungeon_01.tres
|   |-- room_data/
|   |   `-- overworld_0_0.tres
|   `-- loot_tables/
|       |-- bush_loot.tres
|       `-- enemy_loot.tres
|-- shaders/
|   |-- water.gdshader
|   |-- damage_flash.gdshader
|   |-- screen_transition.gdshader
|   |-- dark_world_palette.gdshader
|   |-- lighting_overlay.gdshader
|   `-- post_process.gdshader
|-- audio/
|   |-- bgm/
|   `-- sfx/
`-- debug/
    `-- debug_room.tscn
```

---

## Primitive Visual Language

Every entity uses a simple, repeatable shape language so the game remains readable without sprites.

| Entity | Visual Rule |
|---|---|
| Player | Green pentagon torso, skin-tone circular head, directional cap triangle |
| Sword slash | White or pale yellow arc drawn during attack frames |
| Shield | Small colored polygon on the forward side of the player body |
| Soldier | Red rectangle body with small helmet triangle |
| Octorok | Red circle |
| Stalfos | White triangle |
| Keese | Purple diamond |
| Buzz Blob | Yellow circle with pulsing shader |
| Bush | Green circle cluster |
| Pot | Brown square with lighter rim |
| Chest | Brown rectangle with light lid strip |
| Arrow | Yellow triangle |
| Bomb | Gray circle with short fuse line |
| Hookshot | Blue-gray line and tip |
| Heart HUD | Red polygon heart |
| Rupee HUD | Green diamond |

Color should encode intent consistently:

- Green and warm neutrals for the player and friendly objects
- Red and orange for immediate threats
- Blue for water, magic, and stun or freeze states
- Gray and brown for structural environment
- Gold and yellow for key objectives, keys, and rewards

---

## Visual Direction

The primitive shapes are the skeleton — the effects layer is what makes the game look good. This section defines the visual identity that should be applied consistently throughout all phases.

### Lighting

Every room has a mood set by lighting. This is the single biggest lever for making flat shapes look atmospheric.

- **CanvasModulate** per room sets the base ambient color. Overworld daytime: warm white `Color(1.0, 0.98, 0.9)`. Forests: dappled green `Color(0.7, 0.85, 0.65)`. Dungeons: cool gray `Color(0.5, 0.5, 0.6)`. Dark World: desaturated purple `Color(0.6, 0.45, 0.65)`. Dark rooms: near-black `Color(0.08, 0.08, 0.12)` until torches/lamp activate.
- **Player glow**: `PointLight2D` (warm yellow, energy ~0.4, texture: soft radial gradient). Always on. Makes the player feel like the focal point.
- **Torches**: `PointLight2D` with orange tint. Energy oscillates randomly between 0.6–1.0 each frame for flicker. In dark rooms, torches are the only light sources until the Lantern is used.
- **Boss rooms**: Dramatic lighting — dim ambient with a single strong `PointLight2D` on the boss (red/orange tint).
- **Water glow**: Faint blue `PointLight2D` emanating from water tile areas, giving caves with water a cool ambient bounce.

### Shaders

These run throughout the game, not just as one-off effects:

- **Water** (`water.gdshader`): Sine-wave UV distortion (amplitude ~2px, period ~1.5s) + slow blue color cycling between two blue tones. Applied to all water `TileMapLayer` cells. Makes water feel alive.
- **Damage flash** (`damage_flash.gdshader`): `mix(original_color, white, flash_amount)`. Tweened 1.0→0.0 over 0.08s. Applied to any entity on hit via `FlashComponent`.
- **Screen transitions** (`screen_transition.gdshader`): Iris wipe (expanding/contracting circle) centered on player position. For dungeon doors: iris-out → black → iris-in. For world switch: radial swirl distortion that intensifies to black.
- **Dark World palette** (`dark_world_palette.gdshader`): Screen-wide post-process on a `CanvasLayer`. Shifts hues toward purple, reduces saturation by ~20%, darkens midtones. Applied whenever the player is in the Dark World.
- **Lighting overlay** (`lighting_overlay.gdshader`): Subtle vignette (darken screen edges ~15%) for dungeon/cave interiors. Adds visual focus toward the center.
- **Pulsing glow**: Used on Buzz Blobs, boss weak points, and collectibles. Sinusoidal modulate on `self_modulate.a` or energy for `PointLight2D`.

### Post-Processing

Applied via a `ColorRect` on a dedicated `CanvasLayer` (layer 19, just below `TransitionOverlay`). Both effects share a single `post_process.gdshader` to avoid multiple full-screen passes.

**Bloom / Glow**

Gives lights, magic, and collectibles a soft halo against dark backgrounds. Especially important in dungeons and caves where `CanvasModulate` is dim and bright elements should pop.

- Extract pixels above a brightness threshold (~0.7), blur them (two-pass Gaussian, 3px radius at 256×224 is plenty), and add back to the scene.
- Intensity controlled by a `bloom_strength` uniform (0.0–1.0). Default 0.3 for subtle glow. Crank to 0.6 in dark rooms.
- Primary bloom sources: `PointLight2D` halos, magic projectiles (Fire/Ice Rod), collectible pickups, boss weak points, Lamp flame, torch fire, rupee glint.
- Bloom is applied after `CanvasModulate` so it respects the room's ambient darkness.

**Color Grading Per Biome**

A lookup-based or uniform-driven color adjustment that shifts the overall palette per area. Makes each biome feel distinct beyond just tile colors.

| Area | Grading |
|---|---|
| Overworld field | Warm — slight boost to reds/yellows, lift shadows slightly. Sunny feel. |
| Forest | Green push — shift midtones toward green, slightly crush blacks. Dense canopy mood. |
| Mountain/cave | Cool desaturate — reduce saturation ~15%, shift shadows toward blue. Stone coldness. |
| Desert | Hot — boost warm tones, raise overall brightness slightly, reduce blues. |
| Lake | Cool blue — strong blue shift in shadows, keep highlights neutral. |
| Dungeon interior | Neutral desaturate — drop saturation ~25%, slightly cool midtones. Sterile stone. |
| Dark World | Handled by `dark_world_palette.gdshader` (purple shift, desaturate, darken midtones). |
| Boss room | High contrast — crush blacks harder, boost highlights slightly. Dramatic. |

Implemented as uniforms on the post-process shader: `color_shift: vec3` (additive RGB offset for midtones), `saturation: float`, `brightness: float`, `contrast: float`. `SceneManager` tweens these uniforms during room transitions (0.3s) so the grading shifts smoothly, not abruptly.

`RoomData` stores the grading preset per room (either as direct uniform values or as a `StringName` key into a grading dictionary).

### Particles (GPUParticles2D)

Particles are cheap and add life to every interaction:

- **Sword impact**: 6–10 white/yellow spark sprites, burst outward from hit point, 0.15s lifetime. Triggered on every sword-hits-enemy/wall contact.
- **Enemy death**: 8–12 triangles in the enemy's body color, explode outward + slight gravity, 0.4s lifetime. Combined with a brief scale-to-zero tween on the body.
- **Bomb explosion**: 15–20 orange/red circles, radial burst, 0.3s. Accompanied by screen shake (intensity 2.0, 0.2s).
- **Dash dust**: Continuous trail while dashing. Small brown/tan circles, low velocity downward, 0.3s lifetime, emitting from player's feet.
- **Grass/bush cut**: 4–6 small green leaf shapes scatter upward with slight spread.
- **Chest open**: Golden sparkles rise upward from chest, 0.5s, slight drift.
- **Ambient — forest**: Slow-moving leaf particles drifting diagonally, very low opacity, sparse (1 every ~2s).
- **Ambient — dungeon**: Floating dust motes, near-stationary, faint white, very low opacity.
- **Ambient — Dark World**: Faint purple embers drifting upward, slow.
- **Water splash**: Small blue droplets on entering/exiting water, burst upward.
- **Magic use**: Colored sparkles matching the item (blue for ice, red for fire, green for magic powder) burst from player on cast.

### Procedural Animation (Squash & Stretch)

All driven by `AnimationPlayer` tracks on the visual node's `scale` property:

- **Sword swing**: Player body squashes horizontally (0.8x, 1.2y) on wind-up frame, then stretches (1.2x, 0.8y) on swing, returns to 1.0 over 0.1s.
- **Dash start**: Brief horizontal stretch (1.3x, 0.7y) on first frame.
- **Landing from fall/pit**: Squash (1.3x, 0.6y) on land frame, bounce back over 0.15s.
- **Enemy hit reaction**: Brief squash (0.8x, 1.15y) toward knockback direction, then snap back.
- **Pickup collect**: Item scales up (1.5x) and fades out simultaneously over 0.2s.
- **Chest lid**: Lid rectangle rotates open (0° to -90°) over 0.3s.

### Screen Shake

Triggered via `EventBus.screen_shake_requested(intensity, duration)`. Implemented by randomizing `Camera2D.offset` each physics frame during the shake window, decaying intensity linearly. If a new shake request arrives while one is active, keep whichever has the higher current intensity — do not stack them additively.

| Trigger | Intensity | Duration |
|---|---|---|
| Player takes damage | 1.0 | 0.12s |
| Bomb explosion | 2.5 | 0.25s |
| Boss stomp/land | 2.0 | 0.2s |
| Push block lands | 0.5 | 0.08s |
| Boss phase transition | 3.0 | 0.4s |

### Trails and Motion Lines

For fast-moving entities, draw a fading trail using `_draw()`:

- **Sword arc**: Draw 3–4 fading copies of the sword polygon at previous rotation angles during the swing, each with decreasing alpha. Creates a visible sweep arc.
- **Boomerang**: Short trail of 2–3 faded copies behind it.
- **Dash**: Speed lines — 3 short horizontal lines behind the player, drawn via `_draw()`, fading over 0.1s.
- **Hookshot chain**: Line segments drawn via `_draw()` from player to hook tip, with small joint marks every 8px.

---

## Shared Systems and Data Rules

### Room Metadata

Each room scene should have a companion `RoomData` resource or exported fields on `room.gd` with:

- `room_id: StringName`
- `room_type: StringName` such as `overworld`, `cave`, `dungeon`
- `world_type: StringName` such as `light`, `dark`, `interior`
- `screen_coords: Vector2i` for overworld screens when applicable
- `music_track: StringName`
- `ambient_color: Color`
- `is_dark_room: bool`
- `neighbor_paths: Dictionary` keyed by `up`, `down`, `left`, `right`

This keeps transitions, music, save flags, and debug reporting consistent.

### Damage Typing

All hitboxes should expose a typed damage source so armor, shields, and enemy immunities can branch cleanly.

Recommended enum:

```gdscript
enum DamageType {
    CONTACT,
    SWORD,
    ARROW,
    BOMB,
    FIRE,
    ICE,
    MAGIC,
    PIT,
    WATER,
    SPIKE
}
```

### Damage Formula

All damage values are in **half-heart units** (1 unit = half heart, 2 units = full heart).

**Step 1 — Shield check** (before any damage is applied):
- If the hit is a projectile, it came from the front, and it hit the `ShieldArea`:
  - Check `projectile_class` against shield tier blocking table (see section 3.4)
  - If blockable: deflect (tier 1–2, projectile vanishes) or reflect (tier 3, projectile reverses). **No damage taken. Skip all remaining steps.**
  - If not blockable: proceed to Step 2.
- Non-projectile damage (CONTACT, SWORD, SPIKE, PIT) is never blocked by shield.

**Step 2 — Immunity check**:
- Check `damage_type` against the target's `damage_immunities` array.
- If immune: **no damage. No knockback. No effect.** Play a "clink" SFX to give feedback.

**Step 3 — Armor reduction** (player only, enemies have no armor):
- Armor only reduces **combat damage types**: CONTACT, SWORD, ARROW, BOMB, FIRE, ICE, MAGIC.
- **Environmental damage types bypass armor entirely**: PIT, WATER, SPIKE. These always deal their raw value.
- Reduction formula: `final_damage = max(raw_damage - armor_reduction, 1)`
  - Armor tier 0 (no armor): 0 reduction
  - Armor tier 1 (Green Mail): 0 reduction (this is the baseline — Green Mail is the default tunic)
  - Armor tier 2 (Blue Mail): damage halved (`raw_damage / 2`, rounded up)
  - Armor tier 3 (Red Mail): damage quartered (`raw_damage / 4`, rounded up)
- Minimum 1 unit of damage after reduction (no hit is ever completely negated by armor alone).

**Step 4 — Apply damage**:
- `HealthComponent.take_damage(final_damage)`
- All side effects fire: flash, knockback, i-frames, screen shake, SFX.

**Sword damage output** (for reference):

| Sword Tier | Base Damage | Notes |
|---|---|---|
| 1 (Fighter's) | 2 | |
| 2 (Master) | 4 | |
| 3 (Tempered) | 8 | |
| 4 (Golden) | 16 | At full health, emits sword beam (2 damage) |

**Standard enemy damage output**:

| Source | Raw Damage | Notes |
|---|---|---|
| Weak enemy contact (Keese, Octorok) | 2 | 1 heart |
| Medium enemy contact (Soldier) | 4 | 2 hearts |
| Strong enemy contact (Dark World) | 8 | 4 hearts |
| Boss contact | 8 | |
| Boss special attack | 12 | |
| Pit / fall | 2 | Bypasses armor |
| Spike | 2 | Bypasses armor |
| Water (no Flippers) | 2 | Bypasses armor, pushes player back |

These values are starting points — balance via playtesting.

### Save Schema

Save files must include at minimum:

```json
{
  "schema_version": 1,
  "slot": 1,
  "timestamp_utc": "2026-04-04T10:00:00Z",
  "player": {},
  "inventory": {},
  "game_state": {}
}
```

The exact payload can grow later, but `schema_version` is required from the first real save implementation onward.

### Debug Expectations

- `debug_room.tscn` should expose representative hazards, pickups, one destructible, one door, and at least one enemy archetype as systems land.
- Any new core interaction should be testable in isolation without needing a full overworld.
- Audio placeholder logs should include a category prefix so noisy logs stay readable, for example `[Audio][SFX] sword_swing`.

---

## Phase 1: Core Foundation

**Milestone**: "Link Walks Around a Room"

### 1.1 Project Configuration

- Keep the Forward Plus renderer (already configured, needed for 2D lighting/shaders)
- Resolution: 256x224 with viewport stretch and integer-friendly upscaling
- Default window: 1024x896
- Physics tick: leave at Godot default unless profiling proves it needs adjustment
- Input map:
  - `move_up`, `move_down`, `move_left`, `move_right`
  - `action_sword`
  - `action_item`
  - `action_dash`
  - `action_shield`
  - `interact`
  - `pause`
- Suggested keyboard bindings:
  - Move: WASD and arrows
  - Sword: `J` and `X`
  - Item: `K` and `Z`
  - Dash: `L` and `C`
  - Shield: Left Shift
  - Interact: `E` and Space
  - Pause: Escape and Enter
- Suggested gamepad bindings:
  - Move: left stick and d-pad
  - Sword: east face button
  - Item: west face button
  - Dash: south face button
  - Shield: left shoulder
  - Interact: north face button
  - Pause: Start

Physics layers:

| Layer | Name | Used By |
|---|---|---|
| 1 | World | Walls, solid terrain, room geometry |
| 2 | Player | Player body and shield component |
| 3 | Enemies | Enemy bodies and hurtboxes |
| 4 | PlayerAttacks | Sword hitbox and player projectiles |
| 5 | EnemyAttacks | Enemy projectiles and enemy contact hitboxes |
| 6 | Interactables | Chests, signs, NPCs, pots, bushes |
| 7 | Hazards | Pits, spikes, water hazards before flippers |
| 8 | Triggers | Room transitions, cutscene zones, sensors |

Autoload registration order:

1. `EventBus`
2. `GameManager`
3. `InventoryManager`
4. `AudioManager`
5. `SceneManager`
6. `SaveManager`

### 1.2 Main Scene

`scenes/main/main.tscn` is the always-loaded root scene.

Node layout:

- `Main` (`Node`)
  - `World` (`Node2D`)
  - `HUDLayer` (`CanvasLayer`, layer 10)
  - `DialogLayer` (`CanvasLayer`, layer 15)
  - `TransitionOverlay` (`CanvasLayer`, layer 20)
  - `PauseLayer` (`CanvasLayer`, layer 25, `process_mode = ALWAYS`)
  - `DebugLayer` (`CanvasLayer`, optional, editor/debug only)

Rules:

- `SceneManager` swaps room scenes only under `World`
- `Main` itself is never replaced during gameplay
- Title screen, overworld rooms, dungeon rooms, and game over screen are all children loaded beneath `World`
- The persistent player instance is spawned once and inserted into the active room's `Entities` node

### 1.3 Autoload Responsibilities

**EventBus**

Pure signal hub. Initial signals:

- `player_health_changed(current, max)`
- `player_magic_changed(current, max)`
- `player_rupees_changed(amount)`
- `player_damaged(amount, source_type)`
- `player_died()`
- `enemy_defeated(enemy_type, position)`
- `item_get_requested(item: ItemData)` — triggers ItemGetState presentation
- `item_acquired(item_id)` — emitted after presentation completes and inventory is mutated
- `room_transition_requested(target_room_id, entry_point)`
- `world_switch_requested(target_world_type)`
- `dialog_requested(lines)`
- `screen_shake_requested(intensity, duration)`

**GameManager**

Owns run-level state:

- Current world type
- Current dungeon id and room id
- Global flags dictionary
- Pause state
- Last safe player position
- Current save slot

Public methods:

- `set_flag(key: StringName, value: Variant) -> void`
- `get_flag(key: StringName, default_value := false) -> Variant`
- `has_flag(key: StringName) -> bool`

Flag keys follow the pattern `{room_id}/{persist_id}` for room-scoped state (chests, blocks, switches) and plain keys like `dungeon_01/boss_defeated` or `items/bow` for global state. Keys are always built from `@export` fields, never from node names or scene paths.

**SceneManager**

Owns:

- Loading and unloading room scenes
- Room transition timing
- Reparenting the persistent player into the new room
- Applying room camera limits
- Starting room music from room metadata

Implementation notes:

- Use `ResourceLoader.load_threaded_request()` for room preloading
- Maintain `current_room`, `current_room_id`, and `current_screen_coords`
- Provide a blocking fallback load path so the game still works if threaded loading is unavailable in a debug context

**AudioManager**

Placeholder-first audio API:

- Two `AudioStreamPlayer` children for BGM crossfade
- Pool of 8 `AudioStreamPlayer` nodes for SFX
- `play_bgm(track_name)`
- `stop_bgm()`
- `play_sfx(sfx_name)`
- `set_bgm_volume(db)`
- `set_sfx_volume(db)`

Behavior:

- If the requested file exists in `res://audio/bgm` or `res://audio/sfx`, play it
- Otherwise log a tagged placeholder message
- Gameplay code must never branch based on whether a real asset exists

**InventoryManager**

Owns:

- `equipped_item_id: StringName` — currently equipped active item (or `""`)
- `owned_active_items: Dictionary` — id → ItemData for acquired active items
- `item_effects: Dictionary` — id → cached BaseItemEffect instance per active item
- `passives: Dictionary` — StringName → int (e.g., `{"sword": 2, "boots": 1}`)
- `rupees: int`, `arrows: int`, `bombs: int` — consumable counters
- `dungeon_keys: Dictionary` — dungeon_id → {small_keys, has_big_key, has_map, has_compass}
- `current_health: int`, `max_health: int` — in half-heart units
- `current_magic: int`, `max_magic: int`
- `heart_pieces: int` — 0–3, resets on reaching 4

Single acquisition entry point: `add_item(item: ItemData)` — branches on `item_type` to handle ACTIVE, PASSIVE, and COLLECTIBLE differently (see section 3.2).

Public methods:

- `add_item(item: ItemData) -> void`
- `equip_item(item_id: StringName) -> void`
- `get_equipped_item() -> ItemData`
- `get_equipped_effect() -> BaseItemEffect`
- `has_item(item_id: StringName) -> bool`
- `get_passive(key: StringName) -> int` — returns 0 if not owned
- `has_passive(key: StringName) -> bool` — shorthand for `get_passive() > 0`
- `consume_item_cost(item: ItemData) -> bool` — deducts magic + ammo, returns false if can't afford
- `spend_rupees(amount: int) -> bool`
- `spend_ammo(kind: StringName, amount: int) -> bool`
- `add_key(dungeon_id: StringName, amount: int = 1) -> void`
- `use_key(dungeon_id: StringName) -> bool`

**SaveManager**

Phase 1 behavior:

- Stub methods may log instead of writing real files
- Method names and payload shape should already match the final save system

Final responsibility:

- Serialize `GameManager`, `InventoryManager`, and player position to `user://save_{slot}.json`
- Preserve `schema_version`

### 1.4 Player Character

`scenes/player/player.tscn`

- `Player` (`CharacterBody2D`)
  - `CollisionShape2D`
  - `PlayerBody` (`Node2D`, custom `_draw()`)
  - `SwordHitbox` (`Area2D` or child scene with `HitboxComponent`)
  - `ShieldComponent` (`Area2D`)
  - `HurtboxComponent` (`Area2D`)
  - `InteractionProbe` (`ShapeCast2D` or `Area2D`)
  - `StateMachine`
  - `AnimationPlayer`
  - `Camera2D`
  - `DashDustSpawner` (`GPUParticles2D`)
  - `PointLight2D`

Core properties:

- `facing_direction: Vector2`
- `move_input: Vector2`
- `speed := 90.0`
- `push_speed := 30.0`
- `dash_speed_multiplier := 2.5`
- `last_safe_position: Vector2`

Rules:

- Movement is 8-directional
- Diagonal movement must be normalized
- The player collision box should fit a 16-pixel corridor comfortably, approximately 12x14 pixels
- `facing_direction` persists when idle
- `action_dash` does nothing until Pegasus Boots are acquired

### 1.5 Player State Machine

Use a generic reusable `StateMachine` node under `components/`.

Phase 1 required states:

| State | Behavior |
|---|---|
| Idle | No movement. Transition to Walk on movement input. Transition to Attack on sword input. |
| Walk | 8-direction movement at base speed. Transition to Idle when input ends. |
| Attack | Short sword swing, roughly 0.25-0.3 seconds. Player movement locked. |
| Knockback | Brief forced motion after damage, then return to Idle. |
| Fall | Triggered by pits or fallback hazards. Shrink or scale tween, respawn at last safe position, apply damage. |

Later states:

- `DashState` after Pegasus Boots
- `ItemUseState` after active items exist
- `ItemGetState` for item acquisition presentation (see section 3.2)
- `SwimState` after Flippers
- `LiftState`, `CarryState`, and `ThrowState` after gloves

Input buffering:

- Buffer `action_sword`, `action_item`, and `action_dash` for 0.1 seconds
- Consume the oldest valid buffered action when the current state becomes interruptible

### 1.6 Camera System

Player-owned `Camera2D`:

- Overworld rooms use bounded follow with smoothing
- Dungeon rooms use fixed room framing
- Screen transitions temporarily override free follow

Defaults:

- `position_smoothing_enabled = true`
- `position_smoothing_speed = 8.0`

Transition behavior:

- Overworld edge crossing: 0.5-second camera scroll and short player auto-walk
- Dungeon door transition: fade out, swap room, fade in

### 1.7 Base Room Structure

`scenes/world/room.tscn`

- `Room` (`Node2D`)
  - `Terrain` (`TileMapLayer`)
  - `Overlay` (`TileMapLayer`)
  - `Entities` (`Node2D`, `y_sort_enabled = true`)
  - `Transitions` (`Node2D`)
  - `EntryPoints` (`Node2D` containing `Marker2D`s)
  - `NavigationRegion2D`
  - `CanvasModulate`
  - Optional `PointLight2D` nodes

Rules:

- `Terrain` owns floor, walls, hazards, and collision
- `Overlay` owns visual elements that draw above the player
- `Entities` contains enemies, NPCs, pickups, interactables, and the persistent player instance
- Entry points are named markers used by `SceneManager`

Tile behavior by type:

| Tile Type | Behavior |
|---|---|
| Floor | Walkable |
| Wall | Solid collision |
| Water | Hazard or blocked movement before Flippers; swimmable after Flippers |
| Pit | Triggers Fall state |
| Ledge | One-way traversal where appropriate |
| Conveyor | Adds velocity while overlapping |
| Ice | Reduced friction and longer slide distance |

Room loading strategy:

- Dungeon transitions load one room at a time
- Overworld scroll transitions temporarily load current room plus destination room
- `SceneManager` should preload the four cardinal overworld neighbors when possible

Persistence:

- Enemies respawn when re-entering a room unless a specific room script overrides that behavior for a boss or scripted event.
- Chests, solved push blocks, toggled switches, opened boss doors, and world-state changes must restore from `GameManager` flags.
- Each persistent entity has an `@export var persist_id: StringName` (set in editor, never auto-generated from node name). On `_ready()`, the entity builds its flag key as `{room.room_id}/{persist_id}` and checks `GameManager.get_flag()` to restore its solved/opened/defeated state. On state change (chest opened, block pushed, boss killed), it calls `GameManager.set_flag()` with the same key.
- If `persist_id` is empty, the entity is treated as non-persistent (no save/restore). This is intentional for optional elements like resettable switches.
- `room_id` and `persist_id` are both `@export` fields set by hand in the editor. This avoids any dependency on node names, scene paths, or tree structure — renaming or reparenting nodes does not break save data.

### 1.8 HUD

The HUD is built in Phase 1, not deferred. It's essential for seeing game state during development.

HUD lives on `CanvasLayer` 10 (already part of `main.tscn`) and remains visible during all gameplay.

**Phase 1 elements** (minimum viable):

- **Hearts** (top-left): drawn via `_draw()`. Full heart = red, half = half-filled, empty = dark outline. Listens to `EventBus.player_health_changed`.
- **Rupee count** (below hearts): green diamond polygon + monospace `Label`. Listens to `EventBus.player_rupees_changed`.
- **Equipped item slot** (top-right): box outline. Empty in Phase 1, shows item `icon_shape` in `icon_color` once items exist (Phase 3).

**Added in Phase 3:**

- **Magic meter** (left, under hearts): vertical bar, green fill, dark border. Listens to `EventBus.player_magic_changed`.
- **Ammo display** (near equipped item): small number showing current arrow/bomb count for the equipped item's ammo type.

**Added in Phase 4:**

- **Dungeon minimap** (top-right corner): grid of small rectangles. Current room = highlighted, visited = dimmed, unvisited = hidden unless dungeon map collected. Only visible when inside a dungeon.
- **Small key count** (near minimap): key icon + number. Dungeon only.

Rules:

- HUD listens to EventBus signals — never polls managers each frame.
- Heart rendering supports full, half, and empty states (health is in half-heart units).
- Dungeon-only widgets are hidden when outside a dungeon.
- All HUD elements are drawn via `_draw()` or `Polygon2D` — no sprite textures.

### 1.9 Phase 1 Deliverable

Acceptance criteria:

1. One playable room exists with walls, at least one hazard, and at least one valid entry point marker.
2. The player can move in 8 directions, swing a visible sword arc, take damage, and recover from knockback.
3. The camera remains bounded inside the room.
4. HUD shows hearts and updates on damage.
5. Audio calls log correctly even with no real assets present.

---

## Phase 2: Combat System

**Milestone**: "Link Fights Enemies"

### 2.1 Core Combat Components

**HurtboxComponent**

- `Area2D` that receives hits
- Tracks invincibility frames
- Emits `hurt(hitbox_data)` with damage, source direction, and damage type

**HitboxComponent**

- `Area2D` that deals damage
- Properties:
  - `damage: int`
  - `damage_type: DamageType`
  - `knockback_force: float`
  - `effect: HitEffect`
  - `source_team: StringName` such as `player` or `enemy`

**KnockbackComponent**

- Applies decelerating knockback over a short window

**FlashComponent**

- Brief white-flash visual using shader or modulation tween

Recommended `HitEffect` enum:

```gdscript
enum HitEffect {
    NONE,
    STUN,
    FREEZE,
    BURN
}
```

### 2.2 Enemy Data Resource

`EnemyData` stores only stats that are genuinely shared by all enemies. Movement behavior, detection logic, and attack patterns live in each enemy's state scripts — not in data.

```gdscript
class_name EnemyData extends Resource

@export var id: StringName
@export var display_name: String
@export var max_health: int
@export var contact_damage: int           # 0 if enemy has no contact hitbox
@export var knockback_resistance: float   # 0.0 = full knockback, 1.0 = immune
@export var drop_table: LootTable
@export var color: Color                  # Primary body color for _draw()
@export var damage_immunities: Array[int] # DamageType enum values this enemy ignores
```

Balance-tunable values like movement speed, detection radius, attack range, and firing cadence are `@export` vars on the enemy's own script or its state scripts — not on EnemyData. This avoids forcing a flat structure onto enemies with multi-modal behavior (e.g., Soldier walks slowly on patrol but runs when chasing).

### 2.3 Enemy Architecture

**Composition over scene inheritance.** There is no `base_enemy.tscn`. Instead:

- `base_enemy.gd` is a **script** that extends `CharacterBody2D`. It holds shared logic: health management, death sequence (particles + loot + `EventBus.enemy_defeated` + `queue_free()`), damage reception, and the `@export var enemy_data: EnemyData` binding.
- Each enemy type is its own **standalone scene** that uses `base_enemy.gd` (or a type-specific subclass of it) as its root script. The scene includes only the components that enemy actually needs.

Example — Soldier scene:

```
Soldier (CharacterBody2D, script: soldier.gd extends BaseEnemy)
  ├── CollisionShape2D
  ├── EnemyBody (Node2D, _draw())
  ├── HurtboxComponent        ← always
  ├── ContactHitbox            ← because Soldier deals contact damage
  ├── HealthComponent          ← always
  ├── KnockbackComponent       ← always
  ├── FlashComponent           ← always
  ├── LootDropComponent        ← always
  ├── StateMachine
  │     ├── Patrol  (soldier_patrol.gd)
  │     ├── Chase   (soldier_chase.gd)
  │     ├── Attack  (soldier_attack.gd)
  │     └── Stunned (shared stunned_state.gd)
  ├── NavigationAgent2D        ← Soldier needs pathfinding
  └── DetectionZone (Area2D)   ← Soldier reacts to player proximity
```

Example — Keese scene (much simpler):

```
Keese (CharacterBody2D, script: keese.gd extends BaseEnemy)
  ├── CollisionShape2D
  ├── EnemyBody
  ├── HurtboxComponent
  ├── ContactHitbox
  ├── HealthComponent
  ├── KnockbackComponent
  ├── FlashComponent
  ├── LootDropComponent
  └── StateMachine
        ├── Flutter  (keese_flutter.gd)  ← erratic sine-wave movement + contact
        └── Stunned  (shared stunned_state.gd)
```

No `NavigationAgent2D`, no `DetectionZone` — Keese doesn't need them.

**`EnemyState`** (`scenes/enemies/enemy_state.gd`): extends `State`, types `actor` as `BaseEnemy`. Shared convenience: `StunnedState` can be reused by all enemies since stun behavior is universal (immobile, blue tint, timer). Everything else is per-type.

### 2.4 Level Design Exports

Each enemy scene exposes `@export` properties for per-instance configuration in the room editor:

```gdscript
# On base_enemy.gd or the type-specific script
@export var enemy_data: EnemyData
@export var initial_facing: Vector2 = Vector2.DOWN

# On enemies with patrol behavior (Soldier, Octorok, Stalfos)
@export var patrol_points: PackedVector2Array  # Local-space waypoints
@export var patrol_wait_time: float = 1.0      # Pause at each point

# On enemies with detection (Soldier, Stalfos)
@export var detection_radius: float = 80.0
@export var lose_interest_radius: float = 120.0

# On enemies with ranged attacks (Octorok, Stalfos)
@export var fire_cadence: float = 2.0          # Seconds between shots

# On enemies with chase behavior (Soldier)
@export var patrol_speed: float = 30.0
@export var chase_speed: float = 60.0
```

This means the same Soldier scene can be placed twice in one room with different patrol routes, facing directions, and detection ranges — all configured in the editor without touching code.

### 2.5 Initial Enemy Set

| Enemy | Shape | Components | States | Notes |
|---|---|---|---|---|
| Soldier | Red rectangle + helmet triangle | Nav, Detection, Contact | Patrol → Chase → Attack (lunge) → Stunned | Two speeds: `patrol_speed` and `chase_speed` |
| Octorok | Red circle | Contact | Wander → Shoot → Stunned | No detection zone — shoots on a timer in facing direction. `fire_cadence` export. |
| Keese | Purple diamond | Contact | Flutter → Stunned | One movement state: erratic sine-wave path. No patrol points, no detection. |
| Stalfos | White triangle | Detection, Contact | Wander → Throw → Stunned | Random walk, throws bone projectile when player is in detection range. |
| Buzz Blob | Yellow pulsing circle | Contact | Wander → Stunned | Random walk only. Immune to sword (`damage_immunities` includes SLASH). |

### 2.5 Projectile System

`projectile_base.tscn`

- Root type: `Area2D`
- Required properties:
  - `speed`
  - `damage`
  - `damage_type`
  - `direction`
  - `lifetime`
  - `pierce`
  - `deflectable`
  - `source_team`

Rules:

- Destroy on world collision unless explicitly bouncing
- Damage valid opposing hurtboxes
- Do not damage same-team actors by default
- Specialized subclasses override behavior, for example boomerang return, hookshot retract, bomb explode

### 2.6 Loot Drops

**LootTable**

- Weighted entries: `item_id`, `weight`, `quantity_min`, `quantity_max`
- `roll()` returns zero or more pickup payloads

**LootDropComponent**

- Spawns pickups on death or object destruction
- Pickups bob visually and magnetize lightly toward the player on overlap or close collection radius
- Pickups despawn after a timeout unless the design later chooses permanence

Pickup types:

- Heart: restore 1 health unit
- Green rupee: +1
- Blue rupee: +5
- Red rupee: +20
- Magic jar: restore magic
- Arrow bundle
- Bomb bundle

### 2.7 Phase 2 Deliverable

Acceptance criteria:

1. At least three enemy types are fightable in one room.
2. Player and enemies both use hitbox and hurtbox components with knockback and invincibility frames.
3. Enemies drop pickups through weighted tables.
4. Shield-blockable projectiles and non-blockable damage sources are distinguishable in data.

---

## Phase 3: Items and Inventory

**Milestone**: "Link Has Equipment"

### 3.1 Item Data Resource

```gdscript
class_name ItemData extends Resource

@export var id: StringName
@export var display_name: String
@export var description: String
@export var item_type: ItemType       # ACTIVE, PASSIVE, COLLECTIBLE
@export var icon_color: Color
@export var icon_shape: PackedVector2Array

# ACTIVE items only:
@export var magic_cost: int           # 0 if no magic needed
@export var ammo_type: StringName     # "arrows", "bombs", or "" for none
@export var ammo_cost: int
@export var use_script: Script        # Extends BaseItemEffect (see 3.3)

# PASSIVE items only:
@export var passive_key: StringName   # e.g. "sword", "boots", "armor"
@export var tier: int                 # Upgrade level (boolean passives use 1)

# COLLECTIBLE items only:
@export var collect_key: StringName   # e.g. "rupees", "arrows", "heart_piece"
@export var collect_amount: int       # How much to add
```

```gdscript
enum ItemType {
    ACTIVE,
    PASSIVE,
    COLLECTIBLE
}
```

Not all fields apply to every type. `use_script` is only relevant for ACTIVE, `passive_key` for PASSIVE, etc. Unused fields are left at default.

### 3.2 Acquisition Presentation

Significant items (chest contents, dungeon rewards, NPC gifts) get a short presentation sequence before being added to inventory. Minor pickups (rupees, hearts, ammo drops from enemies/bushes) skip presentation and are collected instantly.

**ItemGetState** (player state):

1. Source (chest, NPC, pickup) calls `EventBus.item_get_requested.emit(item)` 
2. Player transitions to `ItemGetState`
3. Gameplay pauses: `get_tree().paused = true` (player scene has `process_mode = ALWAYS`)
4. Player visual: arms-up pose via `_draw()` — body polygon shifts, item shape drawn above head in `item.icon_color`
5. `AudioManager.play_sfx("item_fanfare")` — different jingles for major (active/passive) vs minor (key, map) items
6. Dialog box shows: `"You got the {item.display_name}! {item.description}"`
7. Wait for player to press `interact` or `action_sword` to dismiss
8. `InventoryManager.add_item(item)` — actual inventory mutation happens here
9. `get_tree().paused = false`
10. Player transitions back to `IdleState`

**What triggers presentation vs instant collect:**

| Source | Presentation? | Reason |
|---|---|---|
| Chest (active/passive item) | Yes | Major reward |
| Chest (rupees, ammo) | Short (auto-dismiss ~1.5s) | Minor chest reward, still show the hold pose |
| Boss defeat (Heart Container) | Yes | Major reward |
| NPC gift | Yes | Story moment |
| Ground pickup (heart, rupee, ammo) | No | Collected on overlap, SFX only |
| Ground pickup (key, heart piece) | Yes | Significant enough to pause |

For the "No" cases, the pickup scene calls `InventoryManager.add_item()` directly and `queue_free()`s itself. No state change.

For the "Yes" cases, the source emits `EventBus.item_get_requested` and the player handles the presentation. The source waits for `EventBus.item_acquired` (emitted at end of presentation) before completing its own logic (e.g., chest stays open).

### 3.3 Inventory Mutation

`InventoryManager.add_item(item: ItemData)` is the single entry point for all inventory changes. Called at the end of the presentation sequence (or immediately for instant pickups). It branches on `item_type`:

**ACTIVE path:**
1. Store in `owned_active_items: Dictionary` (id → ItemData)
2. Instantiate the `use_script` and cache it in `item_effects: Dictionary` (id → BaseItemEffect instance)
3. If no item is currently equipped, auto-equip this one
4. Emit `EventBus.item_acquired(item.id)`

**PASSIVE path:**
1. Apply to `passives: Dictionary` (StringName → int): `passives[item.passive_key] = max(current, item.tier)`
2. Effect is immediate and permanent — no equipping, never appears in the item grid
3. Emit `EventBus.item_acquired(item.id)`

**COLLECTIBLE path:**
1. Add to the appropriate counter: rupees, arrows, bombs, heart pieces, etc.
2. Heart pieces: if count reaches 4, reset to 0 and increase max health by 2 (1 full heart)
3. Clamp to max capacity (e.g., max 999 rupees, max ammo based on upgrade tier)
4. Emit the relevant EventBus signal (e.g., `player_rupees_changed`)

No GameManager flags are set for item ownership. `InventoryManager` is the single source of truth. Rooms/NPCs that need to check ownership call `InventoryManager.has_item()` or `InventoryManager.get_passive()` directly.

```gdscript
# InventoryManager public methods:

# Acquisition
func add_item(item: ItemData) -> void

# Active items
func equip_item(item_id: StringName) -> void
func get_equipped_item() -> ItemData          # null if nothing equipped
func get_equipped_effect() -> BaseItemEffect  # null if nothing equipped
func has_item(item_id: StringName) -> bool
func get_owned_active_items() -> Dictionary   # id → ItemData

# Passive queries — the player script uses these to gate abilities
func get_passive(key: StringName) -> int      # 0 if not owned
func has_passive(key: StringName) -> bool     # shorthand for get_passive() > 0

# Consumables
func spend_rupees(amount: int) -> bool        # false if insufficient
func spend_ammo(kind: StringName, amount: int) -> bool
func consume_item_cost(item: ItemData) -> bool  # deducts magic + ammo, false if can't afford
func add_key(dungeon_id: StringName, amount: int = 1) -> void
func use_key(dungeon_id: StringName) -> bool
```

### 3.4 Item Use System

**BaseItemEffect** — lightweight script that defines what an active item does when used:

```gdscript
class_name BaseItemEffect extends RefCounted

# Can the player afford to use this right now?
func can_use(player: Player) -> bool:
    return true

# Execute the item effect. Returns the duration (seconds) that
# ItemUseState should lock the player before returning to Idle.
func activate(player: Player) -> float:
    return 0.0
```

Each active item has a script extending `BaseItemEffect`. InventoryManager instantiates it once on acquisition and caches the instance. No repeated instantiation on use.

**ItemUseState wiring:**

```gdscript
# scenes/player/states/item_use_state.gd
extends PlayerState

var lock_timer: float = 0.0

func enter() -> void:
    var effect := InventoryManager.get_equipped_effect()
    var item := InventoryManager.get_equipped_item()

    if effect == null or item == null or not effect.can_use(actor):
        state_machine.transition_to("idle")
        return

    InventoryManager.consume_item_cost(item)
    lock_timer = effect.activate(actor)
    AudioManager.play_sfx(item.id)  # e.g., "bow", "bomb"

func physics_update(delta: float) -> void:
    lock_timer -= delta
    if lock_timer <= 0.0:
        state_machine.transition_to("idle")
```

**What each effect does inside `activate()`:**

| Item | activate() behavior | Lock duration |
|---|---|---|
| Bow | Spawns Arrow scene in current room, aimed in `player.facing_direction` | ~0.3s |
| Bomb | Spawns Bomb scene at player position | ~0.2s |
| Boomerang | Spawns Boomerang projectile, returns to player | ~0.3s (throw anim) |
| Hookshot | Spawns hookshot chain, extends until hit. On hookable target: pulls player (lock until arrival). On wall/enemy: retracts (lock until retract done). Returns variable duration via callback. | Variable |
| Lamp | Creates temporary `PointLight2D` ahead of player, lights torches in range | ~0.2s |
| Magic Powder | Spawns particle cone in facing direction, checks overlap for transformable enemies | ~0.3s |
| Fire Rod | Spawns fire projectile with particle trail | ~0.3s |
| Ice Rod | Spawns ice projectile with particle trail | ~0.3s |
| Hammer | Enables hammer hitbox in facing direction, checks for pegs | ~0.4s |

The spawned things (Arrow, Bomb, Hookshot chain) are full scenes in `scenes/items/` with their own scripts and lifecycle. The effect script is just the trigger.

**Hookshot special case:** Lock duration is not known at activation time (depends on what it hits and how far). The hookshot effect keeps a reference to the player's state machine and calls `transition_to("idle")` directly when the hookshot completes. `activate()` returns a large timeout (e.g., 5.0s) as a safety fallback.

### 3.5 Active Items

| Item | Ammo | Magic | Notes |
|---|---|---|---|
| Bow | 1 arrow | 0 | |
| Bomb | 1 bomb | 0 | 2.5s fuse, Area2D explosion, screen shake |
| Boomerang | 0 | 0 | Stuns enemies, collects pickups. Magic variant has full-screen range. |
| Hookshot | 0 | 0 | Pulls player to hookable targets, stuns enemies |
| Lamp | 0 | 4 | Creates light, ignites torches |
| Magic Powder | 0 | 4 | Transforms certain enemies |
| Fire Rod | 0 | 8 | Ranged fire projectile, lights torches |
| Ice Rod | 0 | 8 | Ranged ice projectile, freezes enemies |
| Hammer | 0 | 0 | Pounds pegs, flips enemies, short range |

### 3.6 Passive Upgrades

All passives are stored in `InventoryManager.passives: Dictionary` as `{StringName: int}`. Boolean passives use 0 (don't have) / 1 (have). Tiered passives use their tier number. Acquiring a passive calls `passives[key] = max(current, new_tier)` — upgrades only go up.

| `passive_key` | Tiers | Effect | Where it's checked |
|---|---|---|---|
| `"sword"` | 1–4 | Damage increase, stronger slash visuals | `AttackState` reads tier for damage + arc width |
| `"armor"` | 1–3 | Damage reduction (see Damage Formula) | `player._on_hurtbox_hurt()` reads tier for reduction calc |
| `"shield"` | 1–3 | Blocks more projectile classes | `ShieldComponent` reads tier to decide block/deflect/reflect |
| `"gloves"` | 1–2 | Lift light (1) or heavy (2) objects | `LiftState.enter()` checks tier vs object weight |
| `"flippers"` | 0–1 | Swim in water instead of taking damage | Water tile handler checks `has_passive("flippers")` |
| `"boots"` | 0–1 | Enables dash | `IdleState`/`WalkState` check `has_passive("boots")` before allowing transition to `DashState` |
| `"moon_pearl"` | 0–1 | Prevents Dark World transformation | `SceneManager` checks on world switch |

Sword beam rule:

- At full health, sword swings emit a forward beam projectile (2 damage) if sword tier ≥ 2
- Sword beam does not consume magic

### 3.7 Shield Mechanics

The shield is primarily passive, matching ALTTP.

Base behavior:

- While idle or walking, the shield protects the player's forward-facing arc
- The player does not gain omnidirectional protection
- Holding `action_shield` is an optional precision stance:
  - locks facing
  - slows movement
  - widens the frontal block window

Shield tiers:

| Tier | Blocks |
|---|---|
| 1 | Rocks, arrows |
| 2 | Tier 1 plus fireballs and beams |
| 3 | Tier 2 plus stronger magic projectiles, reflects select shots |

Implementation note:

- Incoming projectiles should declare a `projectile_class` or equivalent data field
- Shield logic should decide block, deflect, or reflect from data, not enemy-specific special cases

### 3.8 Inventory Screen

Pause-driven full-screen overlay:

- `get_tree().paused = true`
- Inventory UI nodes use `process_mode = ALWAYS`

Layout:

- Top: one equipped active item slot and a selectable grid of owned active items
- Middle: passive gear display for sword, armor, shield, gloves
- Bottom: collectible status such as heart pieces and dungeon collectibles
- Cursor: yellow outline rectangle
- Item icons: generated from `icon_shape` and `icon_color`

### 3.9 Phase 3 Deliverable

Acceptance criteria:

1. The player can pause, equip an active item from the inventory grid, and use it in gameplay.
2. At least four active items are functional via `BaseItemEffect` scripts.
3. Ammo and magic consumption are enforced through `InventoryManager.consume_item_cost()`.
4. Acquiring a passive item (e.g., Pegasus Boots) immediately enables the corresponding ability (e.g., dash) without manual equipping.
5. `InventoryManager.get_passive()` correctly gates player states (dash, swim, lift).
6. Shield tiers visibly affect projectile blocking behavior.

---

## Phase 4: World Structure and Transitions

**Milestone**: "Explorable Overworld"

### 4.1 Overworld Grid

- One screen = 256x224 pixels
- Naming convention: `overworld_X_Y.tscn`
- `SceneManager` tracks `current_screen_coords: Vector2i`

Screen-edge transition flow:

1. Detect exit direction
2. Disable free player control
3. Load or reveal adjacent room
4. Scroll camera over 0.5 seconds
5. Auto-walk player a short distance into the new screen
6. Free old room and re-enable control

Initial content target:

- 4x4 light-world overworld
- Biome variation through tile color and object density

### 4.2 Interior and Cave Transitions

`Door` scene requirements:

- Trigger method: walk-in or `interact`, depending on door type
- Exported fields:
  - `target_scene`
  - `target_entry_point`
  - `transition_style`

Transition styles:

- `fade`
- `iris`
- `instant` for debugging only

### 4.3 Dungeon Structure

`DungeonData` resource:

```gdscript
class_name DungeonData extends Resource

@export var dungeon_id: StringName
@export var dungeon_name: String
@export var rooms: Dictionary
@export var starting_room: Vector2i
@export var boss_room: Vector2i
@export var small_key_count: int
@export var boss_id: StringName
```

Notes:

- Dictionary keys can be `Vector2i` in memory, but save serialization should convert them to strings such as `"2,1"`
- Dungeon rooms use fade transitions rather than side-scroll transitions

Dungeon elements:

- `LockedDoor`: consumes one small key
- `BossDoor`: requires big key
- `Chest`: opens once and persists
- `PushBlock`: pushes one tile and persists if puzzle design needs it
- `Switch`: toggles linked elements
- `PressurePlate`: reacts to player or block weight
- `Pit`: fall hazard or floor-drop trigger
- `ConveyorBelt`: continuous directional push

### 4.4 Light World and Dark World

The game supports paired overworld maps with shared coordinates.

Dark World requirements:

- Distinct palette or `CanvasModulate`
- Different room scenes or room variants
- Tougher enemy distribution

Magic Mirror behavior:

1. Activate from the Dark World
2. Run swirl transition
3. Place player at mirrored coordinates in the Light World
4. Spawn temporary return portal if that mechanic is kept

Without Moon Pearl:

- Entering the Dark World transforms the player
- Transformed state limits sword and item access unless later design changes it deliberately

### 4.5 Phase 4 Deliverable

Acceptance criteria:

1. A 4x4 overworld scrolls correctly between adjacent screens.
2. At least two interiors or caves can be entered and exited.
3. One dungeon with at least four rooms includes a key, locked door, chest, and push-block or switch puzzle.
4. Light/Dark World switching works for at least a 2x2 subset.

---

## Phase 5: Bosses and Advanced Combat

**Milestone**: "First Dungeon Complete"

### 5.1 Boss Architecture

Bosses are **not extensions of the enemy system**. Each boss is a bespoke scene with its own structure, because boss encounters vary too much to share a base scene (multi-entity formations, segment chains, teleporters, etc.).

What bosses share is a **`base_boss.gd` script** (extends `Node2D`, not `CharacterBody2D`) that provides:

- `phase: int` — current phase, changed by the boss's own logic
- `total_health: int` / `current_health: int` — aggregate HP (may be split across sub-entities)
- `_on_phase_change(new_phase)` — virtual. Called automatically when `phase` changes. Triggers brief invulnerability, particle flourish, and screen shake.
- `start_encounter()` — called when player enters boss room. Locks camera to room bounds, closes boss door, starts BGM.
- `end_encounter()` — called on defeat. Spawns heart container, warp tile, sets dungeon completion flag.
- `BossHealthBar` — a `Control` child that draws at the top of the screen. Updated via signal.

Each boss scene owns its own `StateMachine` with **boss-specific states** (not Patrol/Chase/Attack). The state machine drives phase behavior.

### 5.2 Armos Knights

```
ArmosKnights (Node2D, script: armos_knights.gd extends BaseBoss)
  ├── StateMachine
  │     ├── Formation  (phase 1: coordinated hopping)
  │     └── LastStand  (phase 2: solo aggressive knight)
  ├── BossHealthBar
  ├── Knight1 (CharacterBody2D, script: armos_knight_unit.gd)
  │     ├── CollisionShape2D
  │     ├── KnightBody (Node2D, _draw())
  │     ├── HurtboxComponent
  │     └── ContactHitbox
  ├── Knight2 ... Knight6
  └── SpawnPositions (Marker2D nodes)
```

The controller (`armos_knights.gd`) manages all 6 knight units. Individual knights are **not** full enemies — they have hitboxes/hurtboxes but no `StateMachine` of their own. The controller tells them where to hop.

**Phase 1** (6 alive): Knights hop in a synchronized grid pattern. The controller picks a formation, tweens all knights to target positions, pauses, repeats. Occasionally one knight targets the player's position. Contact damage. Each knight has individual HP. When one dies: death particles, remaining knights speed up slightly. Phase change triggers when 5 are dead.

**Phase 2** (1 remaining): Last knight turns red (shader color shift). Hops faster. Jump-attacks the player's position — a shadow indicator (dark circle on ground) telegraphs the landing spot 0.4s before impact. Higher contact damage.

**Defeat**: heart container drop + warp tile via `end_encounter()`.

### 5.3 Boss Design Guidelines

Future bosses follow the same pattern — bespoke scene, `base_boss.gd` script, own state machine:

- **Dungeon 2 boss**: Could be a single large entity with projectile-pattern phases. Scene is a `CharacterBody2D` extending `BaseBoss` directly (no sub-entities needed).
- **Moldorm (Dungeon 3)**: Chain of `CharacterBody2D` segments. Only the tail segment has a `HurtboxComponent`. Controller drives erratic movement, speeds up as health drops.
- Each boss should have at least 2 phases with a visible transition (flash, shake, color change).

### 5.4 Dungeon Completion Flow

On boss defeat:

1. Set dungeon completion flag
2. Spawn Heart Container pickup
3. Fully heal player on pickup
4. Spawn warp tile back to dungeon entrance

### 5.5 Phase 5 Deliverable

Acceptance criteria:

1. One dungeon can be entered, cleared, and exited end to end.
2. The boss has at least two distinct phases.
3. Completion flagging, reward drop, and exit warp all work in one continuous run.

---

## Phase 6: HUD, UI, and Polish

**Milestone**: "Feels Like a Game"

### 6.1 HUD Polish Pass

The HUD is built in Phase 1 (section 1.8) and extended in Phases 3–4. Phase 6 is the polish pass:

- Tighten spacing and alignment of all HUD elements
- Add subtle background panel (semi-transparent dark bar behind hearts/rupees) for readability over bright rooms
- Heart damage animation: briefly flash the lost heart white before it goes dark
- Rupee count: number ticks up/down digit by digit (not instant) when gaining/spending
- Equipped item: brief highlight flash when switching items
- Ensure all HUD elements look consistent across overworld, dungeon, and dark world color grading

### 6.2 Dialog System

Dialog box requirements:

- Bottom-of-screen panel
- Typewriter effect
- `interact` advances or fast-forwards text
- Supports multi-page line arrays

Triggered through:

- `EventBus.dialog_requested(lines)`

### 6.3 Shaders, Effects & Juice

Phase 6 is when all 5 shaders, all particle types, squash/stretch animation, screen shake, and trail effects described in the **Visual Direction** section are implemented and wired up. These effects are not cosmetic afterthoughts — they are what makes primitive shapes feel like a real game.

Specifically, Phase 6 must deliver:
- All shaders functional (water, damage flash, screen transition, dark world palette, lighting overlay, post-process)
- Post-process bloom working in dark rooms and on magic/light sources
- Color grading presets applied per biome with smooth transitions between rooms
- All particle effects for combat (sword impact, enemy death, bomb explosion, grass cut)
- All particle effects for environment (ambient per-biome, water splash, chest sparkle)
- Squash/stretch on player attacks, landings, and enemy hit reactions
- Screen shake hooked up to all triggers (damage, explosions, boss events)
- Sword arc trail and motion lines on fast-moving entities
- Per-room `CanvasModulate` lighting applied to all existing rooms
- Torch `PointLight2D` flicker in dungeon rooms

Note: effects should be added incrementally as systems are built in earlier phases (e.g., `FlashComponent` in Phase 2, dash dust in Phase 1). Phase 6 is the pass where everything is polished, consistent, and nothing is missing.

### 6.4 Title Screen

Minimum title screen features:

- New Game
- Continue
- Options placeholder
- Animated background treatment

`Continue` should be disabled or hidden when no save file exists.

### 6.5 Phase 6 Deliverable

Acceptance criteria:

1. HUD is polished with animations (heart flash, rupee tick, item highlight).
2. Dialog system works end-to-end (triggered by NPCs, signs, item acquisition).
3. All shaders, particles, squash/stretch, screen shake, and trails from the Visual Direction section are implemented and consistent.
4. Title screen with New Game / Continue flow.
5. The project feels coherent and polished despite using primitive art.

---

## Phase 7: Expanded Content

**Milestone**: "Full Game Loop"

### 7.1 Additional Dungeons

- Dungeon 2: conveyor and pit-heavy spaces, projectile-pattern boss
- Dungeon 3: dark rooms, moving platform or traversal-heavy spaces, multi-phase boss

Each dungeon should include:

- Entrance and completion loop
- 6-10 rooms
- Map, compass, big key
- 2-4 small keys
- Unique boss
- Heart Container reward

### 7.2 Heart Pieces

Four pieces combine into one heart container.

Sources:

- Optional caves
- Mini-puzzles
- NPC rewards
- Hidden chests
- Future mini-games if added

### 7.3 NPC System

NPC scene expectations:

- Static or wandering movement
- Primitive visual shape
- Interact area
- `dialog_lines`
- Optional visibility or dialog gating by flag

### 7.4 Destructible Objects

Objects:

- Bushes
- Pots
- Skulls

Behaviors:

- Destroyable by sword, dash, or throw depending on object type
- Can spawn loot
- Lift and throw once gloves are available

### 7.5 Expanded Overworld

World target grows from 4x4 to 8x8.

Biomes:

- Field
- Forest
- Mountain
- Desert
- Lake
- Village
- Graveyard

### 7.6 Save and Load

Real save system requirements:

- Three save slots
- Slot metadata for UI, including play time and last save timestamp
- Save points or safe save triggers
- Load from title screen

Saved data must include:

- Player room id and position
- Current world type
- InventoryManager state
- GameManager flags
- Dungeon progression state

### 7.7 Phase 7 Deliverable

Acceptance criteria:

1. Three dungeons are completable.
2. Save and load work across multiple slots.
3. Overworld includes NPCs, optional rewards, and destructible interactions.

---

## Phase 8: Advanced Mechanics

**Milestone**: "Feature Complete"

### 8.1 Swimming

With Flippers:

- Enter water instead of being rejected or damaged
- Movement speed reduced from normal ground speed
- Ripple particles and smaller body profile

Without Flippers:

- Water acts as a hazard or blocked terrain, depending on room design

### 8.2 Lifting and Throwing

With gloves:

- `interact` lifts a valid object in front of the player
- Object attaches above player while carried
- Sword use is disabled while carrying unless deliberately changed later
- Throw launches object as a simple projectile

Tier rules:

- Power Glove lifts light objects
- Titan's Mitt lifts heavy objects

### 8.3 Magic System

Max magic: 128 units

Suggested costs:

- Lamp: 4
- Fire Rod: 8
- Ice Rod: 8
- Magic Powder: 4
- Medallion-class future items: 32-64

Refills:

- Small magic jar: 16
- Large magic jar: full or large partial refill
- Half Magic upgrade halves future costs

Spin attack should not consume magic.

### 8.4 Game Over

Flow:

1. Player health reaches zero
2. Play death animation and transition
3. Show game over screen
4. Offer Continue or Save and Quit

Continue behavior:

- Respawn at dungeon entrance or designated overworld safe point
- Restore to 3 hearts

### 8.5 Advanced Enemies

These enemies have unique state sets that don't map to the simple Patrol/Chase/Attack model, reinforcing why per-enemy states are necessary.

**Wizzrobe** — standalone scene, no `NavigationAgent2D`, no `DetectionZone`:

```
Wizzrobe (CharacterBody2D, script: wizzrobe.gd extends BaseEnemy)
  ├── HurtboxComponent, HealthComponent, FlashComponent, LootDropComponent
  └── StateMachine
        ├── Hidden    (invisible, invulnerable, picking next teleport spot)
        ├── Appear    (fade in over 0.2s, become vulnerable)
        ├── Telegraph (brief wind-up visual, ~0.4s)
        ├── Fire      (spawn magic projectile)
        └── Disappear (fade out, become invulnerable → Hidden)
```

Cycle: Hidden → Appear → Telegraph → Fire → Disappear → repeat. Can only be damaged during Appear/Telegraph/Fire.

**Like-Like** — needs a unique Engulf state:

```
LikeLike (CharacterBody2D, script: like_like.gd extends BaseEnemy)
  ├── HurtboxComponent, ContactHitbox, HealthComponent, ...
  ├── DetectionZone
  └── StateMachine
        ├── Idle     (stationary, waits for detection)
        ├── Pursue   (slow movement toward player)
        ├── Engulf   (captures player: disable player input, tick damage, player mashes to escape)
        └── Stunned
```

On Engulf: player's state machine is forced into a special trapped state. If engulf duration expires before escape, shield tier drops by 1.

**Moldorm** — note: this is a mini-boss, not a regular enemy. Uses the boss architecture:

```
Moldorm (Node2D, script: moldorm.gd extends BaseBoss)
  ├── StateMachine
  │     ├── Erratic  (phase 1: random direction changes)
  │     └── Frenzy   (phase 2: faster, tighter turns)
  ├── Head (CharacterBody2D, contact damage, no hurtbox)
  ├── Segment1 ... Segment3 (follow head, contact damage, no hurtbox)
  └── Tail (CharacterBody2D, contact damage, HAS hurtbox — only vulnerable point)
```

Segments follow the head using a position history queue (each segment takes the position the one ahead had N frames ago). Only the tail takes damage. Speed increases as health drops.

### 8.6 Audio Hookup Coverage

All major systems should already call `AudioManager` even if assets are absent.

Coverage list:

- BGM: overworld biomes, dungeons, bosses, title, game over, caves, Dark World
- SFX: sword swing and hit, shield block, pickups, chest open, door unlock, bomb place and explode, arrow fire, hookshot, player hurt and death, enemy hurt and death, menu move and select, text blip, dash, push block, switch toggle, fall, transitions, item fanfare (major), item fanfare (minor)

Asset convention:

- `res://audio/bgm/{name}.ogg`
- `res://audio/sfx/{name}.ogg`

### 8.7 Phase 8 Deliverable

Acceptance criteria:

1. Swimming, lifting, throwing, magic consumption, and game over all work in normal gameplay.
2. Advanced enemies meaningfully exercise those systems.
3. Audio coverage is documented and already wired through gameplay code.

---

## Architecture Reference

### Signal Flow: Player Takes Damage

```text
Enemy hitbox overlaps player hurtbox
  -> HurtboxComponent validates invincibility and source team
  -> HurtboxComponent emits hurt(hit_data)
  -> Player receives hit_data
  -> Armor and shield rules modify or reject hit
  -> HealthComponent.take_damage(final_damage)
  -> EventBus.player_health_changed(current, max)
  -> FlashComponent.flash()
  -> KnockbackComponent.apply(direction, force)
  -> StateMachine.transition_to("knockback")
  -> AudioManager.play_sfx("player_hurt")
  -> EventBus.screen_shake_requested(intensity, duration)
  -> If health <= 0, EventBus.player_died()
```

### Base State Class

```gdscript
class_name State extends Node

var state_machine: StateMachine
var actor: Node

func enter() -> void:
    pass

func exit() -> void:
    pass

func handle_input(_event: InputEvent) -> void:
    pass

func physics_update(_delta: float) -> void:
    pass
```

Player states extend `PlayerState` (types `actor` as `Player`). Enemy states extend `EnemyState` (types `actor` as `BaseEnemy`). Each enemy type has its own state scripts — only `StunnedState` is shared across enemies. Boss states extend `State` directly since bosses use `BaseBoss` (Node2D), not `BaseEnemy` (CharacterBody2D).

### State Machine Pattern

```gdscript
class_name StateMachine extends Node

@export var initial_state: State

var current_state: State
var states: Dictionary = {}

func _ready() -> void:
    var parent := get_parent()

    for child in get_children():
        if child is State:
            var key := StringName(child.name.to_lower())
            states[key] = child
            child.state_machine = self
            child.actor = parent

    current_state = initial_state
    if current_state:
        current_state.enter()

func _physics_process(delta: float) -> void:
    if current_state:
        current_state.physics_update(delta)

func _unhandled_input(event: InputEvent) -> void:
    if current_state:
        current_state.handle_input(event)

func transition_to(state_name: StringName) -> void:
    if not states.has(state_name):
        push_warning("Unknown state: %s" % state_name)
        return

    if current_state:
        current_state.exit()

    current_state = states[state_name]
    current_state.enter()
```

### Item Resource Examples

Active item (Bow):
```gdscript
[gd_resource type="Resource" script_class="ItemData"]

[resource]
id = &"bow"
display_name = "Bow"
item_type = 0  # ACTIVE
icon_color = Color(0.6, 0.4, 0.2, 1.0)
magic_cost = 0
ammo_type = &"arrows"
ammo_cost = 1
use_script = preload("res://scenes/items/effects/bow_effect.gd")
```

Passive item (Pegasus Boots):
```gdscript
[gd_resource type="Resource" script_class="ItemData"]

[resource]
id = &"pegasus_boots"
display_name = "Pegasus Boots"
item_type = 1  # PASSIVE
icon_color = Color(0.6, 0.3, 0.1, 1.0)
passive_key = &"boots"
tier = 1
```

Collectible (Blue Rupee):
```gdscript
[gd_resource type="Resource" script_class="ItemData"]

[resource]
id = &"rupee_blue"
display_name = "Blue Rupee"
item_type = 2  # COLLECTIBLE
icon_color = Color(0.2, 0.3, 0.9, 1.0)
collect_key = &"rupees"
collect_amount = 5
```

### Collision Masks

| Entity | Layer | Mask |
|---|---|---|
| Player body | 2 | 1, 7 |
| Player hurtbox | 2 | 5 |
| Sword hitbox | 4 | 3, 6 |
| Player projectile | 4 | 1, 3, 6 |
| Shield component | 2 | 5 |
| Enemy body | 3 | 1, 3 |
| Enemy hurtbox | 3 | 4 |
| Enemy contact hitbox | 5 | 2 |
| Enemy projectile | 5 | 1, 2 |
| Pickups | 6 | 2 |
| Triggers | 8 | 2 |

---

## Implementation Priority

| Phase | Milestone | Key Systems |
|---|---|---|
| 1 | Link Walks Around a Room | Movement, room loading, player, HUD (hearts, rupees, item slot), autoloads |
| 2 | Link Fights Enemies | Combat components, enemy archetypes, drops |
| 3 | Link Has Equipment | Inventory, active items, passive upgrades |
| 4 | Explorable Overworld | Screen transitions, dungeon structure, world switching |
| 5 | First Dungeon Complete | Boss architecture, full dungeon completion loop |
| 6 | Feels Like a Game | HUD polish, dialog, shader/particle polish pass, title screen |
| 7 | Full Game Loop | Additional dungeons, NPCs, heart pieces, save/load |
| 8 | Feature Complete | Swimming, lifting, throwing, magic, game over, advanced enemies |

Rules for phase completion:

1. No phase should require throwing away previous systems.
2. Every phase must leave the game in a runnable state.
3. New content should plug into existing resources and managers instead of bypassing them.
4. If a shortcut is taken for milestone speed, it must be written down in the spec or tracked as explicit tech debt.
