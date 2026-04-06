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
- The sword is always available. There is one skill slot (the B button), not two.
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
|   |-- item_registry.gd           # Scans res://resources/items/ at boot, maps id → ItemData
|   |-- player_state.gd            # The PlayerState autoload (character sheet)
|   |-- audio_manager.gd
|   |-- scene_manager.gd
|   |-- save_manager.gd
|   `-- cutscene.gd
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
|   |   |   |-- base_player_state.gd  # Base BasePlayerState class (do not confuse with PlayerState autoload)
|   |   |   |-- idle_state.gd
|   |   |   |-- walk_state.gd
|   |   |   |-- attack_state.gd
|   |   |   |-- knockback_state.gd
|   |   |   |-- fall_state.gd
|   |   |   |-- dash_state.gd
|   |   |   |-- item_use_state.gd
|   |   |   |-- item_get_state.gd
|   |   |   |-- cutscene_state.gd
|   |   |   |-- swim_state.gd
|   |   |   |-- lift_state.gd         # Phase 7.4
|   |   |   |-- carry_state.gd        # Phase 7.4
|   |   |   |-- throw_state.gd        # Phase 7.4
|   |   |   `-- trapped_state.gd      # Phase 8.3 (Like-Like engulf)
|   |   `-- components/
|   |       `-- shield_component.tscn/.gd
|   |-- enemies/
|   |   |-- base_enemy.gd          # Script base class only, no base .tscn
|   |   |-- base_enemy_state.gd    # Base BaseEnemyState class
|   |   |-- stunned_state.gd       # Shared across all enemy types (immobile, blue tint, timer)
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
|   |   |-- effects/                # One script per skill
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
|   |-- cutscenes/                   # Coroutine-based scripted sequences
|   |   |-- armos_intro.gd
|   |   |-- boss_defeat.gd
|   |   `-- ...
|   |-- ui/
|   |   |-- hud.tscn/.gd
|   |   |-- hearts_display.tscn/.gd
|   |   |-- magic_meter.tscn/.gd
|   |   |-- rupee_counter.tscn/.gd
|   |   |-- item_slot.tscn/.gd
|   |   |-- minimap.tscn/.gd
|   |   |-- subscreen.tscn/.gd      # Pause subscreen (skills, upgrades, resources)
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

Every room scene must have a companion `RoomData` resource (`@export var room_data: RoomData` on `room.gd`). This is the single source of truth for room metadata — do not duplicate these fields as loose exports on the room script.

`RoomData` fields:

- `room_id: StringName`
- `scene_path: String` — `res://` path to the room's `.tscn`, used by `SceneManager.room_registry`
- `room_type: StringName` such as `overworld`, `cave`, `dungeon`
- `dungeon_id: StringName` — matches `DungeonData.dungeon_id` for dungeon rooms, empty for overworld/cave/interior
- `world_type: StringName` such as `light`, `dark`, `interior`
- `screen_coords: Vector2i` for overworld screens when applicable
- `music_track: StringName`
- `ambient_color: Color`
- `is_dark_room: bool`
- `is_safe_respawn_point: bool` — dungeon entrance rooms and overworld save-point rooms set this to `true`
- `neighbor_ids: Dictionary` keyed by `up`, `down`, `left`, `right` — values are `room_id` StringNames, not scene paths

`SceneManager` scans all `RoomData` `.tres` files under `res://resources/room_data/` at startup to build its `room_registry: Dictionary[StringName, String]` (room_id → scene_path). A room without a `RoomData` resource is undiscoverable by transitions and will not load.

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
  - Check `projectile_class` against shield tier blocking table (see section 3.7)
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
- For the player: `PlayerState.apply_damage(final_damage)`. This mutates `current_health`, emits `EventBus.player_health_changed(current, max)`, and emits `EventBus.player_died` if health reaches 0.
- For enemies: the enemy's child `HealthComponent.take_damage(final_damage)`. Enemies are transient per room, so a node-local component is the natural fit; the player is persistent and serialized, so its health lives on `PlayerState` instead.
- All side effects fire regardless of target: flash, knockback, i-frames, screen shake, SFX.

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

See Phase 6 section 6.6 for the full save/load system, JSON schema, and SaveManager API. The key rule: `schema_version` is required from the first save implementation onward so future changes can migrate old saves.

### Debug Expectations

- `debug_room.tscn` should expose representative hazards, pickups, one destructible, one door, and at least one enemy archetype as systems land.
- Any new core interaction should be testable in isolation without needing a full overworld.
- Audio placeholder logs should include a category prefix so noisy logs stay readable, for example `[Audio][SFX] sword_swing`.

### Testing Strategy

Every subphase has a **Verification** block with concrete, runnable checks. Bugs should surface at the subphase level, not accumulate until end-of-phase deliverables.

**Three types of verification:**

1. **Unit tests** — pure GDScript logic with no scene dependencies (damage formula, PlayerState acquisition, loot table rolls, save serialization). Uses the [GUT](https://github.com/bitwes/Gut) framework (Godot Unit Testing). Added as an addon in Phase 2 when the first testable logic lands (damage formula, loot tables). Save serialization tests are added later in Phase 6 (section 6.6) when the save system itself lands.

2. **Debug scene checks** — load `debug/debug_room.tscn` or a dedicated test scene in the editor and verify gameplay behavior manually against a checklist. The debug room grows over time to expose every system added so far.

3. **Headless smoke checks** — `godot --path . --headless --quit` to verify the project loads without errors after any change. Also catches broken scene references, missing resources, and parser errors.

**Test folder structure:**

```
res://
└── tests/
    ├── unit/
    │   ├── test_damage_formula.gd
    │   ├── test_player_state.gd
    │   ├── test_loot_table.gd
    │   ├── test_save_serialization.gd
    │   └── ...
    └── scenes/
        ├── combat_test.tscn       # isolated combat sandbox
        ├── skills_test.tscn       # skill acquisition, equipping, and use
        ├── cutscene_test.tscn     # cutscene primitives
        └── ...
```

**Running tests:**

```bash
# Headless smoke check
godot --path . --headless --quit

# GUT unit tests (after GUT is installed)
godot --path . --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests/unit -gexit
```

**What to verify at each subphase** (the "Verification" block):

- Name 1–3 concrete observable behaviors
- Say where to verify: debug_room, test scene, unit test, or headless smoke check
- Be specific enough that passing the checks is unambiguous
- Don't re-test things earlier subphases already covered (cumulative, not exhaustive)

**Rule:** a subphase is not "done" until its Verification block passes. The phase deliverable aggregates verified subphases — it is not the only test gate.

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
3. `ItemRegistry` — must register before `PlayerState` so that `PlayerState.deserialize()` can resolve item ids during save loads
4. `PlayerState`
5. `AudioManager`
6. `SceneManager`
7. `SaveManager`
8. `Cutscene` (added in Phase 6, see section 6.3)

**Verification:**
- Headless smoke check passes (`godot --path . --headless --quit`) — confirms project loads, all autoloads register in order, no parser errors.
- Every input action in the map responds to its bound key and gamepad button (test with a temporary print on each action in a throwaway scene).
- Window opens at 1024x896 and scales primitive shapes cleanly (no blurry edges, no stretching).

### 1.2 Main Scene

`scenes/main/main.tscn` is the always-loaded root scene.

Node layout:

- `Main` (`Node`)
  - `World` (`Node2D`)
  - `HUDLayer` (`CanvasLayer`, layer 10)
  - `DialogLayer` (`CanvasLayer`, layer 15)
  - `PostProcessLayer` (`CanvasLayer`, layer 19) — `ColorRect` child with `post_process.gdshader` for bloom/color-grade
  - `TransitionOverlay` (`CanvasLayer`, layer 20)
  - `PauseLayer` (`CanvasLayer`, layer 25, `process_mode = ALWAYS`)
  - `DebugLayer` (`CanvasLayer`, optional, editor/debug only)

Rules:

- `SceneManager` swaps room scenes only under `World`
- `Main` itself is never replaced during gameplay
- Title screen, overworld rooms, dungeon rooms, and game over screen are all children loaded beneath `World`
- The persistent player instance is spawned once and inserted into the active room's `Entities` node

**Verification:**
- Open `main.tscn` in the editor — all CanvasLayers present at correct layer indices.
- Run `main.tscn` — `World`, `HUDLayer`, `DialogLayer`, `TransitionOverlay`, `PauseLayer` all visible in the remote scene tree.
- `PauseLayer` continues processing when `get_tree().paused = true` (test by pausing via a temporary hotkey).

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
- `item_acquired(item_id)` — emitted after presentation completes and `PlayerState` is mutated
- `room_transition_requested(target_room_id, entry_point)`
- `world_switch_requested(target_world_type)`
- `dialog_requested(lines)`
- `dialog_closed()` — emitted when dialog box dismisses (used by cutscene system to await completion)
- `screen_shake_requested(intensity, duration)`
- *(cutscene lifecycle signals live on the `Cutscene` autoload itself — `Cutscene.cutscene_started` / `Cutscene.cutscene_finished` — not on EventBus; see section 6.3)*

**GameManager**

Owns persistent run-level state (saved/restored, not transient navigation):

- Global flags dictionary
- Pause state
- Last safe player position (`last_safe_position: Vector2`)
- Last safe room id (`last_safe_room_id: StringName`) — updated whenever the player enters a room whose `RoomData.is_safe_respawn_point` is `true`
- Current save slot

`GameManager` does **not** track current room, dungeon, or world type — that is transient navigation state owned by `SceneManager` (see below). `GameManager` reads from `SceneManager` when it needs those values (e.g., building flag keys, serializing save data).

Public methods:

- `set_flag(key: StringName, value: Variant) -> void`
- `get_flag(key: StringName, default_value := false) -> Variant`
- `has_flag(key: StringName) -> bool`

Flag keys follow the pattern `{room_id}/{persist_id}` for room-scoped state (chests, blocks, switches) and `{dungeon_id}/...` or plain keys for global state. Keys are always built from `@export` fields, never from node names or scene paths.

**What belongs in `GameManager` flags vs `PlayerState`:**

| Goes on `PlayerState` | Goes in `GameManager` flags |
|---|---|
| Skills (owned_skills, equipped_skill_id) | Per-dungeon booleans (big key, map, compass) |
| Upgrades (sword tier, armor tier, boots, flippers…) | Pendants (3 total) and Crystals (7 total) |
| Resources (rupees, arrows, bombs, magic, hearts, small keys) | Dungeon boss defeated, dungeon cleared |
| Health, heart pieces, bottles | Room-scoped persistence (chests, blocks, switches) |
| | Story/cutscene progression, NPC dialog flags |

Rule of thumb: if it's on the character sheet (things Link himself carries or is), it's `PlayerState`. If it's a boolean about world/story progress, it's a `GameManager` flag — even when it's technically "collected" like a pendant or crystal. Pendants and crystals are dungeon rewards used as progression gates, not consumables, so they live with the other progression flags.

**Canonical flag keys for progression:**

- `dungeon_01/has_big_key`, `dungeon_01/has_map`, `dungeon_01/has_compass` — per-dungeon once-and-done items. Repeat for each dungeon.
- `dungeon_01/boss_defeated`, `dungeon_01/complete` — dungeon clear state.
- `pendants/courage`, `pendants/power`, `pendants/wisdom` — the 3 Light World pendants.
- `crystals/1` through `crystals/7` — the 7 Dark World crystals.
- `items/bow`, `items/hookshot`, etc. — **do not use.** Skill ownership lives on `PlayerState.owned_skills`; check with `PlayerState.has_skill("bow")`, never via flags.

**SceneManager**

Owns:

- Loading and unloading room scenes
- Room transition timing
- Reparenting the persistent player into the new room
- Applying room camera limits
- Starting room music from room metadata

**Spawn authority:**

- Every room scene has a `PlayerSpawn` `Marker2D` that marks the default entry position. `SceneManager` places the player at the matching entry-point marker when loading a room.
- **New Game**: always loads `room_id = &"start_house"` (Link's house intro room) and places the player at `PlayerSpawn`.
- **Continue (save load)**: `SaveManager.load_game()` restores the serialized `current_room_id` and `player_position` directly — no marker lookup needed since the exact position is saved.
- **Respawn after death**: `SceneManager` loads `GameManager.last_safe_room_id` and places the player at `PlayerSpawn`. `GameManager` updates `last_safe_room_id` whenever the player enters a room whose `RoomData.is_safe_respawn_point` is `true`, or uses a save point.

**SceneManager is the single owner of transient navigation state:**

- `current_room: Node` — the active room scene instance
- `current_room_data: RoomData` — the active room's metadata (room_id, dungeon_id, world_type, etc.)
- `current_screen_coords: Vector2i` — for overworld scroll tracking
- `room_registry: Dictionary[StringName, String]` — room_id → scene_path, built at startup from `RoomData` scans

Other autoloads that need the current dungeon_id, world_type, or room_id read them from `SceneManager.current_room_data`. For example, `PlayerState.acquire()` reads `SceneManager.current_room_data.dungeon_id` for dungeon-scoped items; `SaveManager.save_game()` serializes `SceneManager.current_room_data.room_id` and the player's position.

Implementation notes:

- Use `ResourceLoader.load_threaded_request()` for room preloading
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

**ItemRegistry**

A read-only lookup that maps a stable item id (`StringName`) to its `ItemData` Resource. The registry exists so that save files can reference items by id (a small, stable string) rather than embedding the full `ItemData` — see section 3.1 and section 6.6.

Behavior:

- On `_ready()`, scans `res://resources/items/` recursively, loading every `.tres` file as an `ItemData`
- For each loaded `ItemData`, registers it under its `id` field in an internal `Dictionary[StringName, ItemData]`
- If two items share an id, logs an error and keeps the first one loaded (ids must be globally unique)
- If an `.tres` file in that directory fails to load as `ItemData` (wrong script class, broken reference), logs a warning and skips it
- Scan runs once at boot and is not repeated at runtime — adding a new item requires an editor reload, which is fine because item authoring is a content-build step, not a gameplay action

Public methods:

```gdscript
func get(id: StringName) -> ItemData         # null if id not registered
func has(id: StringName) -> bool
func all_ids() -> Array[StringName]          # for debug commands like "give every item"
func all_items() -> Array[ItemData]
```

Why autoload and not a static class: the scan must run at game boot (needs `_ready()`), the result must live for the full session (not rebuilt per query), and many systems call into it (`PlayerState.deserialize()`, chests, NPCs, debug commands, the 6.5 title screen's save slot preview). An autoload gives all of that for free.

**Verification:**
- Placing a `.tres` under `res://resources/items/` with `id = &"test_item"` makes `ItemRegistry.get(&"test_item")` return the loaded `ItemData` after a project reload.
- `ItemRegistry.get(&"nonexistent")` returns `null` and does not crash.
- Two `.tres` files with the same `id` produce a logged error on boot, and only the first is retained.
- `ItemRegistry.all_ids()` returns every registered id — useful for the "give every item" debug command.

**PlayerState**

The player character sheet. ALTTP has no inventory in the RPG sense (no slot capacity, no trading, no stacking, no storage) — it has **skills** (permanent ability unlocks), **upgrades** (monotonic stat tiers), and **resources** (countable consumables including health and magic). `PlayerState` is the single autoload that owns all three. It is distinct from `BasePlayerState`, which is the state-machine base class for player states.

Owns:

```gdscript
# Skills — permanent ability unlocks, one equipped at a time via the action button
equipped_skill_id: StringName         # currently equipped skill (or &"")
owned_skills: Dictionary              # id → ItemData for acquired skill items
skill_effects: Dictionary             # id → cached BaseItemEffect instance per skill

# Upgrades — monotonic stat tiers (sword 1–4, armor 1–3, boots 0–1, etc.)
upgrades: Dictionary                  # StringName → int (e.g., {"sword": 2, "boots": 1})

# Resources — health, magic, and consumables
current_health: int                   # in half-heart units
max_health: int                       # 6 at start (3 hearts)
current_magic: int
max_magic: int
heart_pieces: int                     # 0–3, resets on reaching 4
rupees: int
arrows: int
bombs: int
dungeon_small_keys: Dictionary        # dungeon_id (StringName) → int; consumable per-dungeon

# Bottles — the one ALTTP mechanic closest to an "inventory"
bottle_count: int                     # 0–4; how many bottles the player has earned
bottles: Array[int]                   # fixed size 4; each element is a BottleContents enum value
                                      # only indices [0, bottle_count) are meaningful; rest are ignored
```

Per-dungeon booleans (big key, map, compass) and story/progression flags (pendants, crystals, dungeon completion) do **not** live here — they are `GameManager` flags under `{dungeon_id}/...` keys. See GameManager section and section 3.1.

**BottleContents enum:**

```gdscript
enum BottleContents {
    EMPTY,          # bottle is owned but currently holding nothing
    RED_POTION,
    GREEN_POTION,
    BLUE_POTION,
    FAIRY,
    BEE,
    GOOD_BEE,
    MAGIC_POWDER,
}
```

ALTTP caps bottle count at 4, so `bottles` is a fixed-size Array of 4 ints, and `bottle_count` tracks how many of those slots the player has actually earned. Slot index is meaningful (it's the order the player sees in the subscreen). `EMPTY` means "owned but nothing inside" — distinct from "not yet earned," which is represented by the slot being outside `[0, bottle_count)`.

Single acquisition entry point: `acquire(item: ItemData)` — branches on `item_type` to handle `SKILL`, `UPGRADE`, and `RESOURCE` differently (see section 3.3).

Public methods:

```gdscript
# Acquisition
func acquire(item: ItemData) -> void

# Skills (equipped via B button)
func equip_skill(skill_id: StringName) -> void
func get_equipped_skill() -> ItemData          # null if nothing equipped
func get_equipped_effect() -> BaseItemEffect   # null if nothing equipped
func has_skill(skill_id: StringName) -> bool
func get_owned_skills() -> Dictionary          # id → ItemData

# Upgrades (queried by player states to gate abilities)
func get_upgrade(key: StringName) -> int       # 0 if not owned
func has_upgrade(key: StringName) -> bool      # shorthand for get_upgrade() > 0

# Resources
func apply_damage(amount: int) -> void         # mutates current_health, emits player_health_changed
func heal(amount: int) -> void
func spend_rupees(amount: int) -> bool         # false if insufficient
func spend_ammo(kind: StringName, amount: int) -> bool
func consume_skill_cost(item: ItemData) -> bool  # deducts magic + ammo, false if can't afford

# Dungeon small keys (consumable, scoped per dungeon)
# Keys are scoped by dungeon_id at usage time but persist across leaving/re-entering
# the dungeon — `dungeon_small_keys` is part of PlayerState, so counts survive room
# transitions, overworld trips, and save/load. Unused keys remain in the dictionary
# indefinitely, including after the dungeon is completed; they are simply unreachable
# once every LockedDoor in that dungeon is open, which matches canonical ALTTP behavior.
# Use-site enforcement: `use_small_key(dungeon_id)` only decrements the slot matching
# the argument — it never falls back to another dungeon's pool, so a Dungeon 1 key
# cannot be spent on a Dungeon 2 door even though both counts live in the same dict.
func add_small_key(dungeon_id: StringName, amount: int = 1) -> void
func use_small_key(dungeon_id: StringName) -> bool

# Bottles
func add_bottle() -> bool                      # increments bottle_count up to 4
func set_bottle_contents(slot: int, contents: BottleContents) -> void
func get_bottle_contents(slot: int) -> BottleContents
```

**SaveManager**

Phase 1 behavior:

- Stub autoload registered in the correct load order (after `SceneManager`)
- Method signatures (`save_game`, `load_game`, `has_save`, `get_slot_metadata`, `delete_save`) exist and match the final save system
- Stub methods log what they would do instead of writing real files — this lets Phases 2–5 reference `SaveManager` from the Title Screen and Game Over screens without the real system existing yet

Final responsibility (implemented in Phase 6, section 6.6):

- Serialize `GameManager`, `PlayerState`, and player position to `user://save_{slot}.json`
- Preserve `schema_version`
- Deserialize and restore on load, trigger room reload via `SceneManager`

**Verification:**
- `GameManager.set_flag("test/foo", true)` then `get_flag("test/foo")` returns `true`. Flag survives room transitions.
- `PlayerState.upgrades` starts empty; `acquire()` with a test UPGRADE item correctly updates the dict.
- `AudioManager.play_sfx("missing_file")` logs `[Audio][SFX] missing_file` and does not crash.
- `EventBus` signals can be connected from a test script and fire as expected (emit one, observe receiver).

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

**Verification** (in `debug_room.tscn`):
- Player moves in all 8 directions, diagonal speed equals cardinal speed (no 1.41x boost).
- Player polygon visibly rotates its cap triangle to match `facing_direction`.
- Player collision fits through a 16px corridor without snagging.
- Releasing all movement keys leaves `facing_direction` unchanged.

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
- `ItemUseState` after skills exist
- `ItemGetState` for item acquisition presentation (see section 3.2)
- `SwimState` after Flippers
- `LiftState`, `CarryState`, and `ThrowState` land in Phase 7 with destructibles (section 7.4). Baseline capability covers light objects (pots, signs, small bushes) bare-handed. The `gloves` upgrade in Phase 8 extends the weight cap but does not introduce the states — lifting is not gated on owning gloves.

Input buffering:

- Buffer `action_sword`, `action_item`, and `action_dash` for 0.1 seconds
- Consume the oldest valid buffered action when the current state becomes interruptible

**Verification** (in `debug_room.tscn`):
- State transitions fire in response to input: Idle → Walk → Idle → Attack → Idle.
- Attack state locks movement for its full duration (~0.3s) then returns to Idle or Walk based on held input.
- Input buffering: press sword during the final frames of walking; attack executes as soon as walk ends.
- Fall state: stepping on a pit triggers shrink tween and respawn at last safe position with 1 heart of damage.
- Knockback state: entering it via a test hazard forces motion for ~0.2s then returns control.

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

**Verification** (in `debug_room.tscn`):
- Camera follows player with visible smoothing (not snapping).
- Camera respects room bounds — moving the player into a corner does not reveal area outside the room.
- Moving the player quickly shows smoothing lag of ~8 units/sec feel.

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

Dungeon scoping:

- `dungeon_id` is authored on the room's `RoomData` resource (see "Room Metadata" in Shared Systems). The room script exposes it as a read-only property: `var dungeon_id: StringName: get = func(): return room_data.dungeon_id`. There is no separate `@export var dungeon_id` on the room script — `RoomData` is the single source.
- Entities that need dungeon context — `LockedDoor`, `BossDoor`, anything that reads `PlayerState.dungeon_small_keys` or per-dungeon `GameManager` flags — read `dungeon_id` from their containing `Room` at `_ready()` time rather than declaring their own. This prevents a door from drifting out of sync with the dungeon it's placed in (e.g., a Dungeon 1 door copy-pasted into Dungeon 2 would automatically pick up the right dungeon_id from its new parent room).

**Verification** (in `debug_room.tscn`):
- Walls block movement, floor is walkable, water/pit tiles trigger expected behavior (damage/fall).
- `Entities` y-sort correctly: an NPC at y=100 draws behind an NPC at y=150 and in front of one at y=50.
- `CanvasModulate` visibly tints the room.
- Test persistence: set a `GameManager` flag, exit and re-enter the room, entity state restores.

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

**Verification** (in `debug_room.tscn`):
- 3 full hearts visible at start (6 health units).
- Damaging the player by 1 unit shows 2 full hearts + 1 half heart.
- Damaging by 1 more unit shows 2 full hearts + 1 empty outline.
- Emitting `EventBus.player_rupees_changed(42)` updates the rupee counter label to `42`.

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

**Verification:**
- **Unit test** (`test_damage_formula.gd`): cover all 4 steps of the damage pipeline (shield block, immunity, armor reduction, minimum 1). Each damage type through each armor tier. Environmental types bypass armor. Immunity = 0 damage.
- **Debug scene**: Player with HurtboxComponent takes a hit from a test HitboxComponent — correct signal fires, i-frames prevent a second hit for the invincibility window, FlashComponent visibly flashes white.
- **Debug scene**: KnockbackComponent applied to player pushes them in the specified direction then decelerates.

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

**Verification:**
- Create a test `EnemyData.tres` with placeholder values. Load it in a dummy scene, confirm all fields serialize/deserialize correctly.
- `damage_immunities` accepts multiple DamageType values and the runtime check correctly rejects matching hits.

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

**`BaseEnemyState`** (`scenes/enemies/base_enemy_state.gd`): extends `State`, types `actor` as `BaseEnemy`. Shared convenience: `StunnedState` can be reused by all enemies since stun behavior is universal (immobile, blue tint, timer). Everything else is per-type.

**Verification** (in `debug_room.tscn`):
- Soldier scene loads with all expected components, enemy_data reference intact.
- Keese scene is structurally minimal — confirm no NavigationAgent2D or DetectionZone exist.
- A test enemy's StateMachine transitions to StunnedState on stun hit, returns to prior state after timer.
- Enemy death: particles fire, loot drops, `EventBus.enemy_defeated` emits, node frees.

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

**Verification:**
- Place two Soldier instances in `debug_room.tscn` with different `patrol_points`; each walks its own route.
- `@export` variables show in the Godot inspector and round-trip through save/load without issue.

### 2.5 Initial Enemy Set

| Enemy | Shape | Components | States | Notes |
|---|---|---|---|---|
| Soldier | Red rectangle + helmet triangle | Nav, Detection, Contact | Patrol → Chase → Attack (lunge) → Stunned | Two speeds: `patrol_speed` and `chase_speed` |
| Octorok | Red circle | Contact | Wander → Shoot → Stunned | No detection zone — shoots on a timer in facing direction. `fire_cadence` export. |
| Keese | Purple diamond | Contact | Flutter → Stunned | One movement state: erratic sine-wave path. No patrol points, no detection. |
| Stalfos | White triangle | Detection, Contact | Wander → Throw → Stunned | Random walk, throws bone projectile when player is in detection range. |
| Buzz Blob | Yellow pulsing circle | Contact | Wander → Stunned | Random walk only. Immune to sword (`damage_immunities` includes SLASH). |

**Verification** (in `debug_room.tscn` with one of each enemy):
- Soldier: walks patrol route, chases on detection, lunges when close, returns to patrol when out of range.
- Octorok: fires projectile on its `fire_cadence` regardless of player position.
- Keese: flies in erratic sine-wave, deals contact damage on overlap.
- Stalfos: only throws bones when player is within detection radius.
- Buzz Blob: sword hits do nothing (clink SFX), arrow/bomb kills it normally.

### 2.6 Projectile System

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

**Verification** (in `debug_room.tscn`):
- An Octorok projectile with `source_team = "enemy"` does not damage another Octorok on contact.
- A projectile destroys itself on wall collision.
- `lifetime` expiration auto-destroys the projectile.

### 2.7 Loot Drops

**LootTable**

- Weighted entries: `item_id`, `weight`, `quantity_min`, `quantity_max`
- `roll()` returns zero or more pickup payloads

**LootDropComponent**

- Spawns pickups on death or object destruction
- Pickups bob visually and magnetize lightly toward the player on overlap or close collection radius
- Pickups despawn after a timeout unless the design later chooses permanence

Pickup types:

- Heart: restore 2 health units (1 heart)
- Green rupee: +1
- Blue rupee: +5
- Red rupee: +20
- Small magic jar: restore 16 magic
- Large magic jar: restore 128 magic (full refill)
- Arrow bundle: +5 arrows
- Bomb bundle: +3 bombs
- Fairy: rare drop; fully heals health and is caught by an empty bottle if Link owns one (bottle mechanics land in Phase 3)

`max_magic` is fixed at 128 units (set on `PlayerState` at game start) — a "large magic jar" simply sets `current_magic = max_magic`. Half Magic and other future cost modifiers are applied at spend time via `consume_skill_cost()`, not at refill time, so the jar values are stable regardless of upgrade state.

**Verification:**
- **Unit test** (`test_loot_table.gd`): given a weighted table `[(A, 1.0), (B, 3.0)]`, 10000 rolls produce ~25%/75% distribution. Empty table returns empty. Single-entry table always returns that entry.
- **Debug scene**: killing a test enemy spawns pickups that bob and are collected on player overlap.
- Pickups update the correct counters (heart restores health, green rupee adds 1, small magic jar adds 16 magic clamped to `max_magic`, large magic jar fills to `max_magic`).

### 2.8 Phase 2 Deliverable

Acceptance criteria:

1. At least three enemy types are fightable in one room.
2. Player and enemies both use hitbox and hurtbox components with knockback and invincibility frames.
3. Enemies drop pickups through weighted tables.
4. Shield-blockable projectiles and non-blockable damage sources are distinguishable in data.

> **Note**: Persistent save/load is deferred to Phase 6 (section 6.6), because the full set of serializable state is only known after Phases 3–5 add skills, upgrades, dungeon progress, and world type. For mid-development testing in Phases 2–5, use editor reloads and a debug command that seeds `PlayerState` + `GameManager` with a known configuration — not a real save file.

---

## Phase 3: Skills, Upgrades, and Resources

**Milestone**: "Link Has Equipment"

ALTTP has no inventory in the RPG sense. Everything the player can pick up falls into one of three categories:

- **SKILL** — a permanent ability unlock (Bow, Hookshot, Lamp, Hammer, Medallions…). One skill can be equipped at a time via the action button. Acquiring a skill is one-way; skills are never removed.
- **UPGRADE** — a monotonic stat tier (sword 1–4, armor 1–3, shield 1–3, gloves 0–2, boots 0–1, flippers 0–1, moon_pearl 0–1, magic_halver 0–1). Upgrades stack only upward: re-acquiring a lower tier is a no-op. Upgrades listed as `0–N` have a meaningful default: for gloves, tier 0 means bare-handed lifting of light objects (pots, signs, small bushes — see section 3.6); for boots/flippers/moon_pearl/magic_halver, tier 0 just means "not owned yet" with no gameplay effect.
- **RESOURCE** — a countable consumable (rupees, arrows, bombs, magic, hearts, small keys, heart pieces) or the fill state of a bottle.

Per-dungeon booleans (big key, map, compass), pendants, crystals, and dungeon completion are **not** categories here — they are `GameManager` flags.

### 3.1 Item Data Resource

```gdscript
class_name ItemData extends Resource

@export var id: StringName
@export var display_name: String
@export var description: String
@export var item_type: ItemType       # SKILL, UPGRADE, RESOURCE
@export var icon_color: Color
@export var icon_shape: PackedVector2Array

# SKILL items only:
@export var magic_cost: int           # 0 if no magic needed
@export var ammo_type: StringName     # "arrows", "bombs", or "" for none
@export var ammo_cost: int
@export var use_script: Script        # Extends BaseItemEffect (see 3.4)

# UPGRADE items only:
@export var upgrade_key: StringName   # e.g. "sword", "boots", "armor"
@export var tier: int                 # Stat tier (boolean upgrades use 1)

# RESOURCE items only:
@export var resource_key: StringName  # e.g. "rupees", "arrows", "heart_piece"
@export var resource_amount: int      # How much to add
```

```gdscript
enum ItemType {
    SKILL,       # permanent ability unlock, equippable
    UPGRADE,     # monotonic stat tier, permanent and non-equippable
    RESOURCE,    # countable consumable (rupees, ammo, hearts, keys)
}
```

`ItemData` is a unified Resource because all three categories share the same acquisition pipeline (pickup → presentation → `PlayerState.acquire()`). Only the fields relevant to a given `item_type` are filled in; the rest stay at default. This is deliberate — do **not** split `ItemData` into three Resources. The unified shape is what lets chests, NPCs, and pickups hand off a single typed value without caring which category it belongs to.

**Identity and lookup:**

Each `ItemData` instance is authored as a `.tres` file under `res://resources/items/` (e.g., `bow.tres`, `pegasus_boots.tres`, `rupee_blue.tres`). These files are content, not code — edited in the Godot Inspector, checked into version control, and shipped with the game. They are not generated, mutated, or created at runtime.

- **`id: StringName` is the stable contract.** It is the only field that save files, debug commands, and runtime lookups rely on. Renaming or moving a `.tres` file is safe as long as `id` is unchanged. Renaming an `id` is a save-breaking change and should be treated like a schema migration.
- **Filename and directory layout are free.** Items can be organized into subdirectories (`items/weapons/`, `items/tools/`, etc.) or flat — the `ItemRegistry` (section 1.3) discovers them by recursive scan, not by path convention.
- **Runtime references.** At authoring time, pickup/chest/NPC scenes reference items via `@export var item: ItemData`, drag-and-drop in the Inspector. At runtime, code that needs to look up an item from a string (save deserialize, debug commands, pendant/crystal grants from `GameManager` flags) calls `ItemRegistry.get(id)`. Gameplay code should never hardcode `.tres` paths — always go through the registry or an `@export`.
- **All three item types live in the registry.** Even UPGRADE and RESOURCE items that `PlayerState.acquire()` discards after applying their effect still need to exist as `.tres` files so that pickup/chest scenes can carry them through the acquisition pipeline and so that presentation dialogs can read `display_name` / `description` / `icon_color`.

**Verification:**
- Create three test `.tres` files (one SKILL, one UPGRADE, one RESOURCE). Each loads cleanly in the editor and at runtime.
- `item_type` switches correctly in the inspector — SKILL items show `use_script` field, UPGRADE shows `upgrade_key`, RESOURCE shows `resource_key`. This requires `item_data.gd` to be a `@tool` script and implement `_validate_property(property)` to call `property.usage = PROPERTY_USAGE_NO_EDITOR` on fields that don't apply to the current `item_type`.
- `ItemRegistry.get(test_item.id)` returns a valid `ItemData` with matching `id` after a project reload — confirms scan-at-boot picks up the new file. (Object identity across reloads is not a meaningful guarantee; equality is confirmed by matching `id`.)
- Moving a test `.tres` to a subdirectory and reloading the project: `ItemRegistry.get(id)` still returns the item (path-independent lookup).

### 3.2 Acquisition Presentation

Significant items (chest contents, dungeon rewards, NPC gifts) get a short presentation sequence before being acquired into `PlayerState`. Minor pickups (rupees, hearts, ammo drops from enemies/bushes) skip presentation and are collected instantly.

**ItemGetState** (player state):

1. Source (chest, NPC, pickup) calls `EventBus.item_get_requested.emit(item)` 
2. Player transitions to `ItemGetState`
3. Gameplay pauses: `get_tree().paused = true` (player scene has `process_mode = ALWAYS`)
4. Player visual: arms-up pose via `_draw()` — body polygon shifts, item shape drawn above head in `item.icon_color`
5. `AudioManager.play_sfx("item_fanfare")` — different jingles for major (SKILL/UPGRADE) vs minor (small key, compass) items
6. Dialog box shows: `"You got the {item.display_name}! {item.description}"`
7. Wait for player to press `interact` or `action_sword` to dismiss
8. `PlayerState.acquire(item)` — actual state mutation happens here
9. `get_tree().paused = false`
10. Player transitions back to `IdleState`

**What triggers presentation vs instant collect:**

| Source | Presentation? | Reason |
|---|---|---|
| Chest (SKILL or UPGRADE) | Yes | Major reward |
| Chest (rupees, ammo) | Short (auto-dismiss ~1.5s) | Minor chest reward, still show the hold pose |
| Boss defeat (Heart Container) | Yes | Major reward |
| NPC gift | Yes | Story moment |
| Ground pickup (heart, rupee, ammo) | No | Collected on overlap, SFX only |
| Ground pickup (key, heart piece) | Yes | Significant enough to pause |

For the "No" cases, the pickup scene calls `PlayerState.acquire()` directly and `queue_free()`s itself. No presentation.

For the "Yes" cases, the source emits `EventBus.item_get_requested` and the player handles the presentation. The source waits for `EventBus.item_acquired` (emitted at end of presentation) before completing its own logic (e.g., chest stays open).

**Verification** (in `debug_room.tscn`):
- Place a test chest. Open it. Game pauses, player poses with item overhead, dialog shows. Press `interact` → dialog dismisses, game resumes.
- Place a ground rupee. Walking over it collects instantly, no pause, SFX fires.
- The item is only applied to `PlayerState` AFTER the presentation dismisses, not before.

### 3.3 PlayerState Mutation

`PlayerState.acquire(item: ItemData)` is the single entry point for all `PlayerState` mutations driven by item pickups. Called at the end of the presentation sequence (or immediately for instant pickups). It branches on `item_type`:

**SKILL path:**
1. Store in `owned_skills: Dictionary` (id → ItemData)
2. Instantiate the `use_script` and cache it in `skill_effects: Dictionary` (id → BaseItemEffect instance)
3. If no skill is currently equipped, auto-equip this one
4. Emit `EventBus.item_acquired(item.id)`

**UPGRADE path:**
1. Apply to `upgrades: Dictionary` (StringName → int): `upgrades[item.upgrade_key] = max(current, item.tier)`
2. Effect is immediate and permanent — no equipping, never appears in the skill grid
3. Emit `EventBus.item_acquired(item.id)`

**RESOURCE path:**
1. Branch on `item.resource_key`:
   - `"big_key"`, `"map"`, `"compass"`: call `GameManager.set_flag(&"%s/has_%s" % [SceneManager.current_room_data.dungeon_id, item.resource_key], true)`. No PlayerState counter is incremented. Requires the current room to have a non-empty `dungeon_id` (always true when inside a dungeon room).
   - `"small_key"`: call `add_small_key(SceneManager.current_room_data.dungeon_id, item.resource_amount)`. Dungeon context is read from `SceneManager` at acquisition time, not stored on `ItemData`.
   - All other keys (rupees, arrows, bombs, heart pieces, magic, etc.): add `item.resource_amount` to the counter keyed by `item.resource_key`.
2. Heart pieces: if count reaches 4, reset to 0 and increase `max_health` by 2 (1 full heart)
3. Clamp to max capacity (e.g., max 999 rupees, max ammo based on quiver/bomb-bag upgrade tier)
4. Emit the relevant EventBus signal (e.g., `player_rupees_changed`, `player_health_changed`)

No GameManager flags are set for skill or upgrade ownership. `PlayerState` is the single source of truth for everything on the character sheet.

**Monotonicity and forced downgrades:** The `acquire()` path is monotonic — upgrades only ever go up via `max(current, tier)`. This guarantee applies to acquisition only. Gameplay effects (Like-Like engulf timeout, future curses) may directly reduce a tier via `reduce_upgrade(key, amount)`. This is a separate code path, not a bypass of `acquire()` — see `reduce_upgrade()` in the public API below. Rooms/NPCs that need to check skill ownership call `PlayerState.has_skill()`; to check stat tiers, `PlayerState.get_upgrade()`. Per-dungeon booleans (big key, map, compass, pendants, crystals) are `GameManager` flags instead, queried with `GameManager.get_flag(&"dungeon_02/has_big_key")` etc.

```gdscript
# PlayerState public methods:

# Acquisition
func acquire(item: ItemData) -> void

# Skills
func equip_skill(skill_id: StringName) -> void
func get_equipped_skill() -> ItemData           # null if nothing equipped
func get_equipped_effect() -> BaseItemEffect    # null if nothing equipped
func has_skill(skill_id: StringName) -> bool
func get_owned_skills() -> Dictionary           # id → ItemData

# Upgrades — the player script uses these to gate abilities
func get_upgrade(key: StringName) -> int        # 0 if not owned
func has_upgrade(key: StringName) -> bool       # shorthand for get_upgrade() > 0
func reduce_upgrade(key: StringName, amount: int = 1) -> void  # clamps to 0; used by Like-Like and similar effects

# Resources
func apply_damage(amount: int) -> void          # mutates current_health, emits player_health_changed
func heal(amount: int) -> void
func spend_rupees(amount: int) -> bool          # false if insufficient
func spend_ammo(kind: StringName, amount: int) -> bool
func consume_skill_cost(item: ItemData) -> bool # deducts magic + ammo, false if can't afford
func add_small_key(dungeon_id: StringName, amount: int = 1) -> void
func use_small_key(dungeon_id: StringName) -> bool

# Bottles
func add_bottle() -> bool                       # increments bottle_count up to 4
func set_bottle_contents(slot: int, contents: BottleContents) -> void
func get_bottle_contents(slot: int) -> BottleContents
```

**Verification:**
- **Unit test** (`test_player_state.gd`): SKILL path — `acquire(bow)` → `has_skill("bow")` true, `get_equipped_skill()` returns bow when slot was empty.
- **Unit test**: UPGRADE path — `acquire(boots)` → `get_upgrade("boots")` returns 1, acquiring it again doesn't change the tier.
- **Unit test**: UPGRADE monotonicity — `acquire(sword_t1)` → `get_upgrade("sword") == 1`. Then `acquire(sword_t3)` → `get_upgrade("sword") == 3`. Then `acquire(sword_t1)` again → still 3 (never downgrades).
- **Unit test**: RESOURCE — acquiring 4 heart pieces increases `max_health` by 2 and resets counter to 0. Rupees cap at 999.
- **Unit test**: `consume_skill_cost()` returns false when insufficient ammo/magic, does not deduct.
- **Unit test**: `apply_damage(2)` at full health reduces `current_health` by 2 and emits `player_health_changed`. At `current_health == 0`, emits `player_died`.

### 3.4 Item Use System

**BaseItemEffect** — lightweight script that defines what a skill does when used:

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

Each skill has a script extending `BaseItemEffect`. `PlayerState` instantiates it once on acquisition and caches the instance. No repeated instantiation on use.

**ItemUseState wiring:**

```gdscript
# scenes/player/states/item_use_state.gd
extends BasePlayerState

var lock_timer: float = 0.0

func enter() -> void:
    var effect := PlayerState.get_equipped_effect()
    var skill := PlayerState.get_equipped_skill()

    if effect == null or skill == null or not effect.can_use(actor):
        state_machine.transition_to("idle")
        return

    PlayerState.consume_skill_cost(skill)
    lock_timer = effect.activate(actor)
    AudioManager.play_sfx(skill.id)  # e.g., "bow", "bomb"

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

**Verification** (in `debug_room.tscn`):
- Equip bow with no arrows → pressing action item does nothing (can_use returns false).
- Equip bow with arrows → pressing action item spawns arrow, deducts 1, locks player for ~0.3s.
- Equip bomb → places bomb at player position, bomb explodes after 2.5s dealing damage.
- `ItemUseState` returns to idle after `lock_duration` expires even if the effect did nothing.

### 3.5 Skills

| Skill | Ammo | Magic | Notes |
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

**Verification** (in `skills_test.tscn` or `debug_room.tscn`):
- At least 4 skills are individually equippable and usable end-to-end: bow, bomb, boomerang, hookshot.
- Each skill visibly does its thing: arrow flies, bomb explodes, boomerang returns, hookshot extends and retracts.
- Magic costs are deducted correctly (test Lamp: uses 4 magic, cannot use at 3).

### 3.6 Upgrades

All upgrades are stored in `PlayerState.upgrades: Dictionary` as `{StringName: int}`. Boolean upgrades use 0 (don't have) / 1 (have). Tiered upgrades use their tier number. Acquiring an upgrade calls `upgrades[key] = max(current, new_tier)` — tiers only go up.

| `upgrade_key` | Tiers | Effect | Where it's checked |
|---|---|---|---|
| `"sword"` | 1–4 | Damage increase, stronger slash visuals | `AttackState` reads tier for damage + arc width |
| `"armor"` | 1–3 | Damage reduction (see Damage Formula) | `player._on_hurtbox_hurt()` reads tier for reduction calc |
| `"shield"` | 1–3 | Blocks more projectile classes | `ShieldComponent` reads tier to decide block/deflect/reflect |
| `"gloves"` | 0–2 | Extends the lift weight cap above baseline. 0 = bare hands (light only: pots, signs, small bushes). 1 = Power Glove (adds medium: skull rocks). 2 = Titan's Mitt (adds heavy: dark boulders). | `LiftState.enter()` checks `object.weight <= get_upgrade("gloves")` |
| `"flippers"` | 0–1 | Swim in water instead of taking damage. Player enters `SwimState` on contact with a water tile; water no longer triggers `FallState` or environmental damage. | Water tile handler checks `has_upgrade("flippers")`; `WalkState`/`IdleState` transition to `SwimState` when stepping onto a water tile and the check passes |
| `"boots"` | 0–1 | Enables dash | `IdleState`/`WalkState` check `has_upgrade("boots")` before allowing transition to `DashState` |
| `"moon_pearl"` | 0–1 | Prevents Dark World transformation | `SceneManager` checks on world switch |
| `"magic_halver"` | 0–1 | Halves the magic cost of every skill that consumes magic (Lamp, Fire Rod, Ice Rod, Magic Powder, future medallions). Monotonic — re-acquiring has no effect. | `PlayerState.consume_skill_cost(item)` applies `cost = ceil(cost / 2)` if `has_upgrade("magic_halver")` |

Sword rules:

- At full health, sword swings emit a forward beam projectile (2 damage) if sword tier ≥ 2.
- Sword beam does not consume magic.
- Spin attack (when added) does not consume magic. Only explicit skill activations (`ItemUseState` → `consume_skill_cost()`) draw from the magic pool — sword-based effects are always free.

**SwimState** (paired with the `flippers` upgrade):

- Movement speed while swimming is 60% of `speed` (ground speed). Diagonal normalization still applies.
- `SwimState` is entered from `WalkState`/`IdleState` on first contact with a water tile, provided `PlayerState.has_upgrade("flippers")`. It is exited when the player returns to a non-water tile.
- Sword use is disabled in `SwimState` (matches ALTTP). Skill use (Fire Rod, Boomerang, etc.) is also disabled — swim is a traversal state, not a combat state.
- Without flippers, stepping onto a water tile is handled by the hazard rules from section 2.1: water deals 2 units of environmental damage (bypasses armor) and pushes the player back to `last_safe_position`.

**Verification** (in `debug_room.tscn`):
- Without Pegasus Boots: pressing dash button does nothing. Pick up boots from a test chest: dash works immediately, no equip step needed.
- Without Flippers: walking into a water tile deals 2 damage, bypasses armor, and pushes the player back (hazard behavior from section 2.1).
- With Flippers (acquired via test chest): walking into the same water tile transitions to `SwimState`. Movement continues at reduced speed (60% of ground speed). Sword and skill buttons are inert while swimming. Exiting to a non-water tile transitions back to `IdleState`/`WalkState` and restores full speed and ability access.
- Armor upgrade visibly reduces incoming damage (take a hit before/after, compare health change).
- Sword tier upgrade increases damage dealt to enemies (test with an enemy at known HP).
- Magic Halver upgrade: Lamp costs 4 magic before acquisition, 2 after. Fire Rod costs 8 before, 4 after. Re-acquiring the Half Magic item does not further reduce costs.
- Magic Halver is monotonic with the other upgrades: acquiring it alongside other upgrades in any order produces the same final state.

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

**Verification** (in `debug_room.tscn`):
- Tier 1 shield: arrow hitting front vanishes, damage is zero. Arrow hitting back damages player normally.
- Tier 2 shield: a fireball projectile is blocked. Tier 1 shield lets fireballs through.
- Tier 3 Mirror Shield: projectile reflects back at source and can damage the shooter.
- Holding `action_shield` widens the block arc (visible facing-lock + speed reduction).

### 3.8 Pause Subscreen

The subscreen is the pause-driven full-screen overlay that displays `PlayerState`. It is **not** an inventory management UI — ALTTP has no inventory management. It is a read-only character sheet plus a single point of interaction: picking which skill to equip to the B button.

- `get_tree().paused = true`
- Subscreen UI nodes use `process_mode = ALWAYS`

Layout:

- Top: one equipped skill slot and a selectable grid of owned skills
- Middle: upgrade gear display for sword, armor, shield, gloves
- Bottom: resource status such as heart pieces, bottles, and dungeon map/compass/keys for the current dungeon
- Cursor: yellow outline rectangle
- Item icons: generated from `icon_shape` and `icon_color`

**Verification:**
- Press `pause` → subscreen opens, game pauses (`get_tree().paused = true`). Press again → closes, resumes.
- Cursor moves with d-pad/arrows. Selecting a skill equips it.
- Upgrades show their tier in the gear display (e.g., sword tier 2 highlights 2 pips).
- Heart piece count is visible (e.g., `2/4`).

### 3.9 Phase 3 Deliverable

Acceptance criteria:

1. The player can pause, equip a skill from the skill grid, and use it in gameplay.
2. At least four skills are functional via `BaseItemEffect` scripts.
3. Ammo and magic consumption are enforced through `PlayerState.consume_skill_cost()`.
4. Acquiring an upgrade (e.g., Pegasus Boots) immediately enables the corresponding ability (e.g., dash) without manual equipping.
5. `PlayerState.get_upgrade()` correctly gates player states (dash, swim, lift).
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

**Verification:**
- Create at least 2x2 of the 4x4 grid for testing. Walking east from `overworld_0_0` scrolls smoothly to `overworld_1_0` over ~0.5s, player auto-walks into the new room.
- Scrolling back works identically in reverse. Player can re-cross boundaries repeatedly without getting stuck.
- Enemies in the previous room respawn on return.
- `SceneManager.current_screen_coords` updates correctly after each transition.

### 4.2 Interior and Cave Transitions

`Door` scene requirements:

- Trigger method: walk-in or `interact`, depending on door type
- Exported fields:
  - `target_room_id: StringName` — stable room identifier, never a raw scene path
  - `target_entry_point: StringName`
  - `transition_style: StringName`

`Door` emits `EventBus.room_transition_requested(target_room_id, target_entry_point)`. `SceneManager` is the canonical resolver: it maintains a `room_registry: Dictionary[StringName, String]` (room_id → scene path) built by scanning all `RoomData` resources at startup. All transitions — scroll-edge, door, and warp — go through `room_id`; never hardcode scene paths in gameplay code.

Transition styles:

- `fade`
- `iris`
- `instant` for debugging only

**Verification:**
- Place a door in an overworld room pointing to a test interior scene. Walking in triggers iris-out → scene load → iris-in. Player spawns at the correct `target_entry_point` marker.
- Another door in the interior pointing back to the overworld returns the player to the original room.
- Iris transition animates from the player's screen position, not from screen center.

### 4.3 Dungeon Structure

`DungeonData` resource:

```gdscript
class_name DungeonData extends Resource

@export var dungeon_id: StringName
@export var dungeon_name: String
@export var rooms: Dictionary
@export var starting_room: Vector2i
@export var boss_room: Vector2i
@export var boss_id: StringName
```

Notes:

- Dictionary keys can be `Vector2i` in memory, but save serialization should convert them to strings such as `"2,1"`
- Dungeon rooms use fade transitions rather than side-scroll transitions
- `DungeonData` does **not** track key counts. Small-key counts are runtime state on `PlayerState.dungeon_small_keys` (see section 1.3), and the number of keys physically placed in chests/drops is a level-design concern expressed by the chest placements themselves — the dungeon resource does not need a separate budget field.

Dungeon elements:

- `LockedDoor`: consumes one small key scoped to its containing room's `dungeon_id`
- `BossDoor`: requires the big key scoped to its containing room's `dungeon_id`
- `Chest`: opens once and persists
- `PushBlock`: pushes one tile and persists if puzzle design needs it
- `Switch`: toggles linked elements
- `PressurePlate`: reacts to player or block weight
- `Pit`: fall hazard or floor-drop trigger
- `ConveyorBelt`: continuous directional push

**LockedDoor** reads `dungeon_id` from its containing `Room` at `_ready()` (see section 1.7 dungeon scoping note). On interact, it calls `PlayerState.use_small_key(dungeon_id)`; if that returns `true` it opens and sets its persist flag. A door in a Dungeon 1 room will always call `use_small_key(&"dungeon_01")`, even if the scene is copy-pasted into a Dungeon 2 room (the `dungeon_id` is re-inherited from the new parent at `_ready()`).

**BossDoor** likewise reads `dungeon_id` from its containing `Room` and checks `GameManager.get_flag("%s/has_big_key" % dungeon_id)`. Big keys are per-dungeon `GameManager` flags (see section 1.3), not a resource on `PlayerState` — BossDoor does not consume the flag, it just gates on it.

**Verification** (in a test dungeon with 2+ rooms):
- LockedDoor: walking into it without a key does nothing. With a key, consumes 1 and opens. The door stays open on room re-entry (persistent).
- **Cross-dungeon key scoping**: set `PlayerState.dungeon_small_keys = {"dungeon_01": 5, "dungeon_02": 0}` via a debug command, then attempt to open a LockedDoor in a room whose `dungeon_id = &"dungeon_02"`. The door does not open despite the 5 Dungeon 1 keys — `use_small_key(&"dungeon_02")` returns `false` and the Dungeon 1 pool is not consulted or decremented. Verify `PlayerState.dungeon_small_keys` is unchanged afterward.
- **LockedDoor reparenting**: copy a working LockedDoor scene from a Dungeon 1 room into a Dungeon 2 room. Without editing the door, open the project: the door now correctly consumes Dungeon 2 keys because `dungeon_id` is inherited from the new parent room at `_ready()`.
- PushBlock: player pushes block one tile in facing direction. Block position persists via `GameManager` flag.
- Switch: sword hit toggles it, linked door opens/closes accordingly. Persists across room transitions.
- PressurePlate: weight from player or block activates it; weight removed deactivates (unless sticky variant).
- Chest: opening it triggers ItemGetState and sets the persist flag. Re-entering the room shows the chest already open.

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

**Verification:**
- Activating Magic Mirror in a Dark World test room runs a swirl transition and places the player at the mirrored coordinates in the Light World.
- The Dark World has a visibly different color grading (purple shift, desaturated).
- Without Moon Pearl: entering Dark World visibly transforms the player shape. With Moon Pearl: player stays normal.
- `GameManager.world_type` transitions correctly on Mirror/portal use. (Save/load round-trip of world type is verified in Phase 6 section 6.6, not here — save system does not exist yet in Phase 4.)

### 4.5 Phase 4 Deliverable

Acceptance criteria:

1. A 4x4 overworld scrolls correctly between adjacent screens.
2. At least two interiors or caves can be entered and exited.
3. One dungeon with at least four rooms includes a key, locked door, chest, and push-block or switch puzzle.
4. Light/Dark World switching works for at least a 2x2 subset.

---

## Phase 5: First Dungeon Playthrough

**Milestone**: "First Dungeon Playable"

Phase 5 is the first time all prior systems converge inside a single dungeon: navigation, locks and keys, push blocks and switches, regular enemies, chests, map/compass/big key, and the dungeon reward. Bosses are deliberately **not** in this phase — boss architecture and individual bosses (Armos Knights, Moldorm, etc.) are deferred to Phase 9, because building a good boss depends on almost every system in the game (including magic, lifting, advanced enemies) and mixing boss construction into a phase that is really about validating dungeon flow would bloat the phase and delay the first end-to-end playthrough.

Instead, Phase 5 uses a **placeholder completion trigger** in the room that will eventually become the boss room: a pedestal holding the dungeon's reward (pendant or crystal). Walking up to the pedestal and pressing `interact` grants the reward, sets the completion flag, spawns the warp tile, and closes out the dungeon. Phase 9 replaces the pedestal with a real boss; everything downstream of the completion trigger (flag, heal, warp tile) stays identical.

### 5.1 Dungeon Completion Flow

The dungeon built in Phase 5 has no boss yet. Its final room — the future boss room — contains a **reward pedestal**, a simple `Interactable` holding the dungeon's pendant or crystal. Walking up and pressing `interact` triggers the completion flow.

```gdscript
# scenes/rooms/components/reward_pedestal.gd
# Phase 5 placeholder; Phase 9 replaces this with a real boss encounter.
extends Node2D

@export var dungeon_id: StringName           # e.g., &"dungeon_01"
@export var reward_flag: StringName          # e.g., &"pendants/courage"

func _on_interact() -> void:
    GameManager.set_flag(reward_flag, true)
    GameManager.set_flag(&"%s/complete" % dungeon_id, true)
    PlayerState.heal(PlayerState.max_health)
    EventBus.item_get_requested.emit(_build_reward_item())
    # After ItemGetState closes, spawn warp tile back to dungeon entrance
```

On pedestal interact:

1. Set the reward flag (`pendants/courage`, `crystals/1`, etc.) via `GameManager.set_flag()`
2. Set the dungeon completion flag (`dungeon_01/complete`)
3. Fully heal player via `PlayerState.heal(PlayerState.max_health)`
4. Emit `EventBus.item_get_requested` with the pendant/crystal as an `ItemData` — runs the standard `ItemGetState` presentation
5. After `ItemGetState` closes, spawn the warp tile that returns the player to the dungeon entrance
6. Pedestal marks itself consumed (persist flag under `{room_id}/pedestal`) so it doesn't re-trigger on room re-entry

**Verification** (in the first dungeon):
- Navigate from dungeon entrance through all rooms to the reward pedestal room (uses keys, blocks, switches, enemies from Phases 2–4).
- Interact with the pedestal → reward item presentation plays via `ItemGetState`.
- After dismissal, `GameManager.get_flag("dungeon_01/complete")` returns true and the reward flag is set.
- Player is fully healed.
- Warp tile appears and returns player to the dungeon entrance.
- Re-entering the dungeon: pedestal is already consumed, no re-trigger.

> **Phase 9 retrofit**: when bosses land, `reward_pedestal` is replaced by a boss scene in the same room. The boss's `end_encounter()` runs the same completion steps (flag, heal, reward item, warp tile) plus a heart container drop. Everything downstream of the completion trigger stays identical, so the Phase 5 → Phase 9 swap touches only the boss room's contents.

### 5.2 Phase 5 Deliverable

Acceptance criteria:

1. One dungeon can be entered, navigated end-to-end, and completed via the reward pedestal.
2. All prior-phase systems are exercised inside the dungeon: locked doors (small keys), BossDoor (big key), push blocks, switches, chests, regular enemies, map, compass, and the pedestal reward.
3. Completion flagging (`dungeon_NN/complete` and the reward flag), player heal, `ItemGetState` reward presentation, and exit warp all fire in one continuous run.
4. Re-entering the completed dungeon preserves all persistent state (consumed chests, pushed blocks, flipped switches, consumed pedestal).

> **Not in scope**: bosses (Phase 9), cutscene choreography (Phase 6.3), save/load (Phase 6.6). The Phase 5 dungeon is playable end-to-end without any of these.

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

**Verification:**
- Take damage — lost heart visibly flashes white before becoming empty.
- Collect 10 rupees — counter ticks up digit by digit, not instantly.
- Switch skills via subscreen — equipped skill slot flashes briefly.
- HUD remains readable over the brightest and darkest rooms in the game.

### 6.2 Dialog System

Dialog box requirements:

- Bottom-of-screen panel
- Typewriter effect
- `interact` advances or fast-forwards text
- Supports multi-page line arrays

Triggered through:

- `EventBus.dialog_requested(lines)`

**Verification:**
- Place a test sign in `debug_room.tscn`. Pressing `interact` opens the dialog box with typewriter animation.
- Pressing `interact` during typewriter completes the current page instantly. Pressing again advances to next line.
- Multi-page text arrays work: `["Page 1", "Page 2", "Page 3"]` shows all three in sequence.
- Dialog closing emits `EventBus.dialog_closed` exactly once.

### 6.3 Cutscene System

Phase 6 introduces a lightweight cutscene sequencer because several scripted sequences need to coordinate camera, movement, dialog, SFX, and effects in a timed order — the opening sequence, the master sword pull, NPC story beats, dungeon entrance flyovers, and (eventually) the boss intros and outros added in Phase 9. Neither `ItemGetState` nor the Dialog System (6.2) can handle this on their own. The Cutscene System is placed in Phase 6 specifically because it depends on the Dialog System — the `Cutscene.dialog()` primitive awaits `EventBus.dialog_closed` to compose text beats into a timed sequence.

The Cutscene System ships before bosses (Phase 9) deliberately: when bosses arrive, they use these primitives directly for intro and defeat choreography. No ad-hoc inline sequencing is ever needed on boss controllers because the autoload is already there.

**Design: coroutine-based (not AnimationPlayer).** Each cutscene is a GDScript coroutine using `await`. No timeline UI, no method call tracks — just a readable sequence of steps. This is chosen over AnimationPlayer because cutscenes here are short (5–15 steps) and linear; a script is more maintainable than a timeline with method call tracks and signal wiring.

Godot has no native Level Sequencer equivalent. This system is the project's lightweight substitute.

**`Cutscene` autoload** — helper that exposes the primitive operations cutscenes are built from:

```gdscript
# autoloads/cutscene.gd
extends Node

var is_playing: bool = false

signal cutscene_started
signal cutscene_finished

func start() -> void:
    is_playing = true
    cutscene_started.emit()
    # Player script listens and transitions to CutsceneState (input disabled)

func finish() -> void:
    is_playing = false
    cutscene_finished.emit()
    # Player script listens and returns control

# --- Primitives (all awaitable) ---

func wait(seconds: float) -> void:
    await get_tree().create_timer(seconds).timeout

func move_entity(entity: Node2D, target: Vector2, duration: float) -> void:
    var tween := create_tween()
    tween.tween_property(entity, "position", target, duration)
    await tween.finished

func camera_pan(camera: Camera2D, target: Vector2, duration: float) -> void:
    # Temporarily detach camera from follow target, tween position, restore on finish
    ...

func camera_shake(intensity: float, duration: float) -> void:
    EventBus.screen_shake_requested.emit(intensity, duration)
    await wait(duration)

func dialog(lines: PackedStringArray) -> void:
    EventBus.dialog_requested.emit(lines)
    await EventBus.dialog_closed

func sfx(sfx_name: StringName) -> void:
    AudioManager.play_sfx(sfx_name)

func fade_to_black(duration: float) -> void:
    # Tween TransitionOverlay alpha 0→1
    ...

func fade_from_black(duration: float) -> void: ...

func flash(color: Color, duration: float) -> void: ...
```

**Player state integration:** when `Cutscene.start()` fires, the player's state machine transitions to a new `CutsceneState`. Input is disabled; the player remains in whatever pose was active. The cutscene script can move the player via `move_entity()` or call custom methods. When `Cutscene.finish()` fires, the player returns to `IdleState`.

**Writing a cutscene:** each cutscene is a `.gd` file under `scenes/cutscenes/` with a `play()` function. The source that triggers it (chest, NPC, boss room, room trigger) calls the cutscene's `play()` and optionally awaits its completion.

Example — a Sahasrahla-style NPC story beat (`scenes/cutscenes/sahasrahla_intro.gd`), exercising camera pan, dialog, and SFX together:

```gdscript
class_name SahasrahlaIntroCutscene extends RefCounted

static func play(npc: NPC, player: Player, camera: Camera2D) -> void:
    Cutscene.start()
    await Cutscene.wait(0.2)
    await Cutscene.camera_pan(camera, npc.position, 0.4)
    Cutscene.sfx(&"npc_appear")
    await Cutscene.wait(0.3)
    await Cutscene.dialog(PackedStringArray([
        "Ah, you must be the one...",
        "The legend speaks of a hero clad in green.",
        "Find the three pendants.",
    ]))
    await Cutscene.camera_pan(camera, player.position, 0.4)
    await Cutscene.wait(0.2)
    Cutscene.finish()
```

Boss intro and defeat cutscenes (Armos Knights intro, the shared `boss_defeat.gd` used by every boss) follow the exact same pattern and are documented with their bosses in Phase 9 (section 9.2). Phase 6 only needs the autoload and a non-boss test cutscene to verify the primitives.

**Directory:**

```
res://
  autoloads/
    cutscene.gd                    # The Cutscene autoload
  scenes/
    player/
      states/
        cutscene_state.gd          # Player state for cutscene lockout
    cutscenes/
      sahasrahla_intro.gd          # Phase 6 example
      opening_sequence.gd          # Phase 6
      master_sword_pull.gd         # Phase 7+
      armos_intro.gd               # Phase 9 (boss)
      boss_defeat.gd               # Phase 9 (shared boss outro)
      zelda_telepathy.gd           # future
```

**When to use cutscenes vs other systems:**

| Scenario | System |
|---|---|
| Player picks up a key item | `ItemGetState` (specific presentation pattern) |
| NPC says a line | `EventBus.dialog_requested` (just text, no camera/movement) |
| NPC story beat with camera movement | Cutscene |
| Chest-triggered story moment | Cutscene |
| Dungeon entrance flyover | Cutscene |
| Game opening sequence | Cutscene |
| Boss intro/outro (Phase 9) | Cutscene |
| Room-to-room scroll | `SceneManager` (deterministic transition) |

The cutscene system is only used when multiple subsystems (camera, movement, dialog, SFX, effects) need to be coordinated in a timed sequence.

**Verification** (in `cutscene_test.tscn`):
- A 5-step test cutscene (wait → camera pan → dialog → shake → wait) runs end to end with `await` on each primitive.
- Player input is blocked while `Cutscene.is_playing` is true, restored on finish.
- `cutscene_started` and `cutscene_finished` signals emit at the right moments.
- Camera returns to following the player after `camera_pan()` completes.
- Dialog awaits `EventBus.dialog_closed` before resuming the cutscene.
- The Sahasrahla test cutscene plays end-to-end (camera pan → dialog → camera return).

### 6.4 Shaders, Effects & Juice

Phase 6 is when all 5 shaders, all particle types, squash/stretch animation, screen shake, and trail effects described in the **Visual Direction** section are implemented and wired up. These effects are not cosmetic afterthoughts — they are what makes primitive shapes feel like a real game.

Specifically, Phase 6 must deliver:
- All shaders functional (water, damage flash, screen transition, dark world palette, lighting overlay, post-process)
- Post-process bloom working in dark rooms and on magic/light sources
- Color grading presets applied per biome with smooth transitions between rooms
- All particle effects for combat (sword impact, enemy death, bomb explosion, grass cut)
- All particle effects for environment (ambient per-biome, water entry/exit splash, continuous ripple behind the player in `SwimState`, chest sparkle)
- `SwimState` draw tweak: player's `_draw()` renders a smaller body profile (lower half masked by the water tile surface) while swimming
- Squash/stretch on player attacks, landings, and enemy hit reactions
- Screen shake hooked up to all triggers (damage, explosions, boss events)
- Sword arc trail and motion lines on fast-moving entities
- Per-room `CanvasModulate` lighting applied to all existing rooms
- Torch `PointLight2D` flicker in dungeon rooms

Note: effects should be added incrementally as systems are built in earlier phases (e.g., `FlashComponent` in Phase 2, dash dust in Phase 1). Phase 6 is the pass where everything is polished, consistent, and nothing is missing.

**Verification** (walk through the whole game):
- Every shader from the Visual Direction section is visibly active in at least one context.
- Bloom visibly glows on torches, magic projectiles, and collectibles in dark rooms.
- Color grading smoothly transitions between adjacent biomes (no hard cuts).
- Every combat interaction produces particles (sword hit, enemy death, bomb explosion).
- Damage → screen shake fires; bomb explosion shake is visibly stronger.
- Player squashes on sword swing and landing.
- Torches in dungeons flicker with random energy.
- Entering water with Flippers: splash particle burst on entry, continuous ripple trail behind the player while swimming, smaller body profile visible; exit splash on return to land.

### 6.5 Title Screen

Minimum title screen features:

- New Game
- Continue
- Options placeholder
- Animated background treatment

**Slot-select screen** (shared by New Game and Continue):

- Displays 3 slots vertically. Each slot shows: play time, heart count, last save timestamp, or "Empty" if unused.
- **New Game**: selecting an occupied slot prompts "Overwrite? Yes / No" before clearing it. Selecting an empty slot starts immediately.
- **Continue**: selecting an occupied slot loads it. Empty slots are grayed out and unselectable. Each occupied slot has a secondary "Delete" option (e.g., hold interact or a dedicated button) that prompts "Delete save? Yes / No" before calling `SaveManager.delete_save(slot)`.
- After slot select, the screen transitions out and gameplay begins (New Game) or restores (Continue).

`Continue` should be disabled or hidden when no save file exists. Because the Save and Load system (6.6) lands after the Title Screen in Phase 6, the Title Screen is built first with `Continue` disabled unconditionally, and is wired to the `SaveManager` API in 6.6 once that lands. This ordering keeps the Title Screen implementable against stable `SaveManager` stub methods from Phase 1 and lets both systems be verified end-to-end together in 6.6.

**Verification:**
- Launching the game boots to the title screen, not straight into gameplay.
- New Game starts a fresh run (empty `PlayerState`, empty flags, spawn at designated start room).
- Continue is hidden/disabled in 6.5 (no save system yet); becomes functional after 6.6 lands.
- Animated background plays smoothly without stuttering.

### 6.6 Save and Load

The save system lands at the end of Phase 6 because the full set of serializable state is only known after Phases 3–5 have added skills, upgrades, dungeon progress, cutscene flags, and world type. Building it any earlier means revisiting serialization every phase; building it here means writing `serialize()`/`deserialize()` once against the final shape of `PlayerState` and `GameManager`. The `SaveManager` autoload stub from Phase 1 becomes functional here and is wired into the Title Screen's Continue flow.

**Save data** (`user://save_{slot}.json`):

```json
{
  "schema_version": 1,
  "slot": 1,
  "timestamp_utc": "2026-04-04T10:00:00Z",
  "play_time_seconds": 3600,
  "player": {
    "room_id": "light_overworld_2_1",
    "position": [128, 112],
    "facing": [0, 1]
  },
  "world_type": "light",
  "player_state": {},
  "flags": {}
}
```

`player_state` is the full serialized state of the `PlayerState` autoload (owned skills, upgrades, resources, bottles, small keys, health, magic, heart pieces). `flags` is the full `GameManager.flags` dictionary (includes per-dungeon booleans for big key, map, compass, pendants, and crystals). Both managers expose `serialize() -> Dictionary` and `deserialize(data: Dictionary)` methods.

**JSON type serialization**: Godot's built-in `JSON.stringify()` / `JSON.parse_string()` only support basic types (strings, numbers, bools, arrays, dicts). Godot-specific types must be converted manually in `serialize()` / `deserialize()`:

| Godot Type | JSON Representation | Example |
|---|---|---|
| `Vector2` | `[x, y]` array | `[128, 112]` |
| `Vector2i` | `[x, y]` array | `[2, 1]` |
| `Color` | `[r, g, b, a]` array | `[1.0, 0.0, 0.0, 1.0]` |
| `StringName` | `String` | `"bow"` (auto-converted by JSON) |
| `ItemData` reference | `String` (the item's `id`) | `"bow"` — rehydrated via `ItemRegistry.get(id)` on load |

Keep all save data in JSON-safe primitives. Do not use `var_to_str()` / `str_to_var()` — they work but produce Godot-specific syntax that is fragile across engine versions and not human-readable.

**`ItemData` references are serialized by id, not by value.** The Resource itself is never written into the save file — only its `id: StringName` is. On load, `PlayerState.deserialize()` walks the id list and calls `ItemRegistry.get(id)` (see section 1.3) to rehydrate each entry back to a full `ItemData` reference. This keeps the save file small, allows game patches to update item balance without invalidating old saves, and sidesteps the fact that `ItemData.use_script` (a Script reference) cannot be represented in JSON at all.

Concretely, `PlayerState.serialize()` produces something like:

```json
"player_state": {
  "equipped_skill_id": "bow",
  "owned_skills": ["bow", "hookshot", "lamp"],
  "upgrades": {"sword": 2, "boots": 1, "flippers": 1},
  "current_health": 8,
  "max_health": 12,
  "current_magic": 16,
  "max_magic": 128,
  "heart_pieces": 2,
  "rupees": 145,
  "arrows": 20,
  "bombs": 10,
  "dungeon_small_keys": {"dungeon_01": 2, "dungeon_02": 0},
  "bottle_count": 2,
  "bottles": [4, 0, 0, 0]
}
```

Only SKILL items appear in `owned_skills` — UPGRADE and RESOURCE items are consumed at acquisition time (see section 3.3) and never stored as `ItemData` references.

**Unknown-id handling on load:** if a save file references an id that `ItemRegistry.get()` returns `null` for (item was removed, renamed, or the save predates current content), `PlayerState.deserialize()` logs a warning like `[PlayerState] Skipping unknown skill id: "old_cane"` and continues. The save loads; the unknown skill is simply not granted. This prevents a single stale id from bricking a save and makes content removal/renaming a soft-fail instead of a hard crash. Renaming an `id` is therefore still a breaking change — treat it like a schema migration and either bump `schema_version` or accept that affected players lose that skill on first load.

**Save system requirements:**

- 3 save slots
- Slot metadata for title screen UI: play time, last save timestamp, player health, heart count
- `schema_version` field so future changes can migrate old saves
- Save triggers: save points in the world (beds, statues, dungeon entrance markers) and the Game Over "Save and Quit" option (see section 8.2).
- Load from title screen "Continue" → slot select → load (wires into the Title Screen built in 6.5)

**SaveManager public methods:**

- `save_game(slot: int) -> void` — serializes GameManager + PlayerState + player position to JSON
- `load_game(slot: int) -> void` — deserializes and restores all state, triggers room load via SceneManager
- `get_slot_metadata(slot: int) -> Dictionary` — for title screen display (returns empty dict if slot unused)
- `has_save(slot: int) -> bool`
- `delete_save(slot: int) -> void`

Because `PlayerState` and `GameManager` are the only autoloads holding persistent state, the save system captures everything by serializing their full dictionaries. Phase 7 (additional dungeons, NPCs) and Phase 8 (new mechanics) add no save code — they just need to ensure new state lives in `GameManager` flags or `PlayerState`.

**Verification:**
- **Unit test** (`test_save_serialization.gd`): `PlayerState.serialize()` → `deserialize()` round-trip preserves all fields. Same for `GameManager`. Vector2 values survive as `[x, y]` arrays. StringName keys become strings and convert back. `owned_skills` survives the round trip: `[bow, hookshot]` → JSON `["bow", "hookshot"]` → rehydrated via `ItemRegistry.get()` back to the same `ItemData` references.
- **Unit test**: `PlayerState.deserialize()` with an unknown skill id (e.g., `"nonexistent_cane"`) logs a warning and continues — other fields still load correctly, the unknown skill is not granted, no crash.
- **Debug scene**: save game → close editor → reopen editor → load game → player position, health, flags, and owned skills all restored.
- **Title screen integration**: fresh install → Continue is disabled. Play + save → return to title → Continue is enabled and loads the correct slot.
- Loading a save with a different `schema_version` logs a warning (migration hook).
- `has_save(slot)` returns false for an unused slot, true after saving.
- Full game state — skills, upgrades, resources, bottles, small keys, health, magic, heart pieces, dungeon flags, pendants, crystals, world type, current room — all round-trip through save/load with no loss.

### 6.7 Phase 6 Deliverable

Acceptance criteria:

1. HUD is polished with animations (heart flash, rupee tick, item highlight).
2. Dialog system works end-to-end (triggered by NPCs, signs, item acquisition).
3. `Cutscene` autoload functional with primitives (wait, camera pan/shake, dialog, fade, flash, move_entity, sfx); verified via a non-boss test cutscene (e.g., the Sahasrahla NPC intro). Boss intros/outros are built on this in Phase 9.
4. All shaders, particles, squash/stretch, screen shake, and trails from the Visual Direction section are implemented and consistent.
5. Title screen with New Game / Continue flow.
6. Save and load fully functional — 3 slots, `schema_version`, round-trip of all `PlayerState` and `GameManager` state, wired into the Title Screen's Continue button.
7. The project feels coherent and polished despite using primitive art.

---

## Phase 7: Expanded Content

**Milestone**: "Full Game Loop"

### 7.1 Additional Dungeons

- Dungeon 2: conveyor and pit-heavy spaces
- Dungeon 3: dark rooms, moving platform or traversal-heavy spaces

Each dungeon should include:

- Entrance and completion loop
- 6-10 rooms
- Map, compass, big key
- 2-4 small keys
- Reward pedestal in the final (future boss) room — same pattern as Phase 5 (section 5.1). Phase 9 replaces the pedestal with a real boss (Dungeon 2 boss TBD, Dungeon 3 gets Moldorm).
- Heart Container reward (granted by the pedestal in Phase 7; by the boss's `end_encounter()` in Phase 9)

**Verification:**
- Each dungeon can be entered, completed end-to-end, and exited via warp tile.
- Map/compass/big key work per dungeon (map reveals minimap, compass reveals key chest location).
- Interacting with each dungeon's reward pedestal sets its completion flag, grants the reward item via `ItemGetState`, fully heals the player, and spawns the warp tile.

### 7.2 Heart Pieces

Four pieces combine into one heart container.

Sources (in Phase 7):

- Optional caves
- Mini-puzzles
- NPC rewards
- Hidden chests
- Future mini-games if added

> **Phase pacing note**: full heart containers are the traditional ALTTP boss reward, but bosses don't land until Phase 9. Through Phase 7 and Phase 8, every heart container Link gains comes from combining 4 heart pieces — there is no direct `+1 container` source yet. This caps the achievable `max_health` in Phases 7–8 playtesting at `6 + 2 * floor(total_heart_pieces_placed / 4)`. When designing Phase 7's overworld and dungeons, make sure there are enough heart pieces placed to give the player a reasonable ceiling for Phase 8 playtesting (target: 10–14 hearts by end of Phase 8). Phase 9 then adds the 3 dungeon boss heart container drops on top, pushing the ceiling toward the full 20-heart cap in the retrofit.

**Verification:**
- Collecting 4 heart pieces increases max health by 2 (verified by HUD).
- Heart piece count resets to 0 after the 4th piece.
- Heart piece pickups persist — already-collected ones don't respawn on room re-entry.
- End-of-Phase-7 playtesting: a player who collects every placed heart piece reaches at least 10 hearts of max health with no boss drops.

### 7.3 NPC System

NPC scene expectations:

- Static or wandering movement
- Primitive visual shape
- Interact area
- `dialog_lines`
- Optional visibility or dialog gating by flag

**Verification:**
- Test NPC with `dialog_lines` shows correct text on `interact`.
- NPC with a `required_flag` is invisible until the flag is set (set via debug hotkey, NPC appears).
- Wandering NPC variant moves randomly within its assigned area.

### 7.4 Destructible Objects and Baseline Lifting

Phase 7 introduces the destructibles the player can interact with in the overworld and dungeons, along with the baseline lift/carry/throw system that lets Link pick up light objects bare-handed — matching ALTTP, where pots, signs, and small bushes are liftable from the start of the game. The `gloves` upgrade (Phase 8.1) extends the weight cap but is **not** required for any of the baseline behavior below.

**Object weight categories:**

Each destructible/liftable declares an `@export var weight: int` matching the `gloves` upgrade tier required to lift it:

| Weight | Examples | Required `gloves` tier |
|---|---|---|
| 0 (LIGHT) | Pots, signs, small bushes, skulls (small) | 0 — bare hands |
| 1 (MEDIUM) | Skull rocks, light grey stones | 1 — Power Glove |
| 2 (HEAVY) | Dark boulders, large statues | 2 — Titan's Mitt |

Phase 7 ships weight-0 objects only. Weight-1 and weight-2 objects can be authored in Phase 7 but will be un-liftable until Phase 8.1 grants gloves; design-wise, place them as future-gated obstacles.

**Baseline lift/carry/throw flow** (`LiftState` → `CarryState` → `ThrowState`):

1. `interact` on a weight-0 object in front of the player triggers `LiftState` — brief lift animation, object tweens from its position to above the player's head.
2. `CarryState` — player moves at reduced speed with the object above their head. Sword is disabled while carrying. Walking over a pit or entering a transition drops the carried object.
3. `ThrowState` — triggered by `action_sword` or `action_item` while carrying. Object becomes a simple projectile in `player.facing_direction`, shatters on wall/enemy contact, spawns loot per its `LootTable`.

Per-object behaviors:

- **Bush**: destroyable by sword, dash (Pegasus Boots), or throw. Also liftable (weight 0) if the player walks up to it and presses `interact` instead of slashing. Spawns loot from its table.
- **Pot**: liftable (weight 0), not sword-destroyable. Shatters on throw impact or when dropped from a height.
- **Skull**: liftable (weight 0), throw-destroyable, can be used to weigh down pressure plates.
- **Sign**: liftable (weight 0), shatters on throw. Displays its `dialog_lines` when examined before lifting.

**Verification:**
- Sword destroys bush → particles fire, loot drops per table.
- Dash destroys bush (Pegasus Boots).
- `interact` on a pot with no gloves: pot lifts, drawn above player head, player enters `CarryState`. Throw shatters the pot on impact and spawns loot.
- `interact` on a weight-1 skull rock with no gloves: nothing happens (log or subtle "can't lift" cue). With Power Glove (Phase 8.1): lifts successfully.
- Entering a room transition or pit while carrying: object is dropped.
- Destructibles do not respawn on room re-entry if they have a `persist_id`.

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

**Verification:**
- All 8x8 screens load cleanly via headless smoke check.
- Each biome has its own color grading and distinct tile palette.
- Walking across biome boundaries smoothly transitions the color grading uniform.
- Save/load works from any screen in any biome.

### 7.6 Phase 7 Deliverable

Acceptance criteria:

1. Three dungeons are completable via their reward pedestals (bosses retrofit in Phase 9).
2. Overworld includes NPCs, optional rewards, and destructible interactions.
3. Save/load (built in Phase 6) handles all Phase 7 content — new dungeons, NPCs, heart pieces, expanded overworld — without modification to the SaveManager.

---

## Phase 8: Final Systems and Coverage

**Milestone**: "Feature Complete"

### 8.1 Glove Upgrades (Power Glove and Titan's Mitt)

The baseline lift/carry/throw system was introduced in Phase 7.4. Bare-handed, Link can already lift weight-0 objects (pots, signs, small bushes, skulls). Phase 8.1 adds the two `gloves` upgrade tiers that extend the weight cap to previously un-liftable objects in the world.

**Tier rules:**

- `gloves` tier 0 (baseline, no item): weight 0 only — pots, signs, small bushes, skulls. Already working from Phase 7.
- `gloves` tier 1 (Power Glove): adds weight 1 — skull rocks, light grey stones.
- `gloves` tier 2 (Titan's Mitt): adds weight 2 — dark boulders, large statues.

`LiftState.enter()` checks `object.weight <= PlayerState.get_upgrade("gloves")`. If the check fails, the state machine bounces back to Idle and plays a "can't lift" cue (subtle grunt SFX + brief shake). This is a soft fail, not a hard block.

**Authoring conventions:**

- Weight-1 and weight-2 obstacles authored in Phase 7 become traversable in Phase 8.1 automatically — no scene edits needed, just the `gloves` upgrade acquisition.
- Do not write special-case code in the player state machine for "after gloves" — all checks go through `get_upgrade("gloves")` against `object.weight`.

**Verification:**
- Without gloves: `interact` on a pot (weight 0) lifts it successfully (Phase 7 behavior still works).
- Without gloves: `interact` on a skull rock (weight 1) fails with a "can't lift" cue — nothing lifts.
- After acquiring Power Glove via `PlayerState.acquire(power_glove_item)`: `interact` on the same skull rock now lifts it. Throwing launches it and destroys it on impact.
- With only Power Glove: `interact` on a dark boulder (weight 2) still fails.
- After acquiring Titan's Mitt: dark boulder lifts successfully.
- `PlayerState.get_upgrade("gloves")` returns 2 after Titan's Mitt is acquired; re-acquiring Power Glove leaves it at 2 (monotonic upgrade rule from section 3.3).

### 8.2 Game Over

Flow:

1. Player health reaches zero
2. Play death animation and transition
3. Show game over screen
4. Offer Continue or Save and Quit

Continue behavior:

- Respawn at dungeon entrance or designated overworld safe point
- Restore to 3 hearts

**Verification:**
- Take lethal damage: death animation plays, game over screen appears.
- Continue → player respawns at dungeon entrance (if in dungeon) or overworld safe point (if outside).
- Health restored to 3 hearts, not full max.
- Save and Quit → writes save, returns to title screen.

### 8.3 Advanced Enemies

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

On Engulf: player's state machine is forced into a special trapped state (`TrappedState`). If engulf duration expires before escape, calls `PlayerState.reduce_upgrade(&"shield", 1)` — this is one of the few cases where an upgrade tier decreases (see section 3.3 monotonicity note).

> **Note**: Moldorm (Dungeon 3 mini-boss) was previously listed here because it shares the "chain of segments" architectural flavor with advanced enemies, but it is a boss — its construction, phase behavior, and encounter flow are covered in Phase 9 (section 9.3). Phase 8.3 is strictly regular advanced enemies.

**Verification:**
- Wizzrobe: cycles through its 5 states correctly, only takes damage during Appear/Telegraph/Fire.
- Like-Like: engulfs player on contact, mashing `action_sword` escapes, timeout drops shield tier.

### 8.4 Audio Hookup Coverage

All major systems should already call `AudioManager` even if assets are absent.

Coverage list:

- BGM: overworld biomes, dungeons, bosses, title, game over, caves, Dark World
- SFX: sword swing and hit, shield block, pickups, chest open, door unlock, bomb place and explode, arrow fire, hookshot, player hurt and death, enemy hurt and death, menu move and select, text blip, dash, push block, switch toggle, fall, transitions, item fanfare (major), item fanfare (minor)

Asset convention:

- `res://audio/bgm/{name}.ogg`
- `res://audio/sfx/{name}.ogg`

**Verification:**
- Grep the codebase for `AudioManager.play_sfx` / `play_bgm` calls and cross-reference with the coverage list above. Every entry in the list has at least one call site.
- Dropping a placeholder `.ogg` at the conventional path plays it instead of logging.
- No crashes occur if the file is missing — it just logs.

### 8.5 Phase 8 Deliverable

Acceptance criteria:

1. Glove-upgraded lifting (Power Glove and Titan's Mitt weight tiers) works in normal gameplay, extending the baseline Phase 7 lift system. Previously-unreachable weight-1 and weight-2 obstacles authored in Phase 7 become traversable without scene edits.
2. Game Over flow ships: death animation, game over screen, Continue (respawn at safe point with 3 hearts) and Save and Quit (writes save, returns to title) both work.
3. Advanced enemies (Wizzrobe, Like-Like) meaningfully exercise the systems added in Phases 3, 7, and 8 — Wizzrobe's magic projectiles hit the player, Like-Like's engulf drops shield tier on timeout, etc.
4. Audio coverage is documented and every `AudioManager` call site matches the coverage list.

---

## Phase 9: Bosses

**Milestone**: "Bosses Complete"

Bosses land last because a good boss exercises nearly every system in the game: combat, dungeons, skills, upgrades, cutscenes, dialog, advanced enemies, magic, lifting, swimming. Attempting bosses any earlier would either produce shallow placeholder encounters or force the phase to drag in half-built dependencies. Arriving here in Phase 9, bosses can use the full toolkit: the Cutscene system from 6.3 for intros/outros, dialog from 6.2 for any pre-fight text, magic-consuming skills from Phase 3 (Fire Rod, Ice Rod, Magic Powder, Lamp), swim traversal from Phase 3 (flippers upgrade), glove-upgraded lifting from 8.1, and the advanced enemy behavior patterns from 8.3 as reference points for boss state machines.

Phase 9 also **retrofits** bosses into dungeons already built in Phases 5 and 7. Each dungeon has a reward pedestal placeholder in its boss room (see section 5.1); Phase 9 replaces the pedestal with a real boss scene whose `end_encounter()` runs the same completion steps plus a heart container drop. Everything downstream of the completion trigger (flag, heal, reward, warp tile) stays identical, so the retrofit touches only the boss rooms' contents.

### 9.1 Boss Architecture

Bosses are **not extensions of the enemy system**. Each boss is a bespoke scene with its own structure, because boss encounters vary too much to share a base scene (multi-entity formations, segment chains, teleporters, etc.).

What bosses share is a **`base_boss.gd` script** (extends `Node2D`, not `CharacterBody2D`) that provides:

- `phase: int` — current phase, changed by the boss's own logic
- `total_health: int` / `current_health: int` — aggregate HP (may be split across sub-entities)
- `_on_phase_change(new_phase)` — virtual. Called automatically when `phase` changes. Triggers brief invulnerability, particle flourish, and screen shake.
- `start_encounter()` — called when player enters boss room. Locks camera to room bounds, closes boss door, starts BGM, plays intro cutscene.
- `end_encounter()` — called on defeat. Plays defeat cutscene, spawns heart container, sets dungeon completion flag and reward flag, fully heals player, spawns warp tile. Replaces the Phase 5 reward pedestal's completion flow for the boss's dungeon.
- `BossHealthBar` — a `Control` child that draws at the top of the screen. Updated via signal.

Each boss scene owns its own `StateMachine` with **boss-specific states** (not Patrol/Chase/Attack). The state machine drives phase behavior. Because bosses arrive after Phase 6.3 (Cutscene System), intros and outros run through the Cutscene autoload's `await` primitives — no ad-hoc inline sequencing is needed.

**Verification:**
- Create a minimal test boss with a scripted phase change at 50% HP. Phase change fires `_on_phase_change()`, triggers the brief invulnerability window, particle flash, and screen shake.
- `start_encounter()` locks camera and closes the boss door (verify with a test room).
- BossHealthBar appears on encounter start and updates as HP drops.
- `end_encounter()` runs the same completion flow as the Phase 5 reward pedestal, plus the heart container drop and defeat cutscene.

### 9.2 Armos Knights (Dungeon 1)

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

**Intro cutscene** (`scenes/cutscenes/armos_intro.gd`):

```gdscript
class_name ArmosIntroCutscene extends RefCounted

static func play(boss: ArmosKnights, player: Player, camera: Camera2D) -> void:
    Cutscene.start()
    await Cutscene.wait(0.3)
    await Cutscene.camera_pan(camera, boss.position, 0.5)
    await Cutscene.wait(0.4)
    boss.play_awaken_animation()   # knights rise from ground
    await Cutscene.wait(0.8)
    Cutscene.sfx(&"boss_roar")
    await Cutscene.camera_shake(2.0, 0.3)
    await Cutscene.camera_pan(camera, player.position, 0.5)
    await Cutscene.wait(0.2)
    Cutscene.finish()
    boss.begin_combat()
```

**Defeat cutscene** (`scenes/cutscenes/boss_defeat.gd`) — reusable across all bosses:

```gdscript
static func play(boss: BaseBoss, camera: Camera2D) -> void:
    Cutscene.start()
    await Cutscene.camera_shake(3.0, 0.6)
    Cutscene.sfx(&"boss_explode")
    await Cutscene.flash(Color.WHITE, 0.4)
    boss.spawn_death_particles()
    var heart_container := boss.spawn_heart_container()
    await Cutscene.wait(0.5)
    boss.queue_free()
    await Cutscene.wait(0.6)
    Cutscene.finish()
```

**Retrofit into Dungeon 1**: in Phase 5 the final room contained a reward pedestal. In Phase 9, the pedestal is removed and the ArmosKnights scene is placed in the same room. The dungeon completion flow is unchanged downstream — same flag keys (`dungeon_01/complete`, `pendants/courage`), same player heal, same warp tile — just triggered by `end_encounter()` instead of pedestal interact.

**Verification** (playable end-to-end in the dungeon 1 boss room):
- Entering the boss room runs the intro cutscene, locks the camera, closes the boss door, starts boss BGM.
- All 6 knights spawn and hop in formation. Hitting one deals damage (tracked individually).
- Killing 5 knights triggers the Phase 2 transition: remaining knight flashes red and speeds up.
- Jump attack telegraphs with shadow indicator before landing.
- Defeating the last knight runs the defeat cutscene, spawns heart container, sets `dungeon_01/complete` + `pendants/courage`, heals player, spawns warp tile.

### 9.3 Moldorm (Dungeon 3)

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

Moldorm is a good second boss example because it exercises a different architectural pattern from Armos Knights: a chain of segments with a single vulnerable point, rather than a formation of independent units. Its phase 2 transition is a continuous speed ramp rather than a discrete visual change.

**Retrofit into Dungeon 3**: same as Armos — the Dungeon 3 reward pedestal is replaced with the Moldorm scene, `end_encounter()` runs the completion flow that was previously on the pedestal.

**Verification:**
- Only the tail segment takes damage; hits on body segments clink (no damage).
- Body segments follow the head correctly via position history queue.
- Speed visibly increases past 50% HP (phase 2 transition).
- Defeating Moldorm runs the shared defeat cutscene and completes Dungeon 3.

### 9.4 Boss Design Guidelines

Future bosses follow the same pattern — bespoke scene, `base_boss.gd` script, own state machine, cutscene-driven intro/outro:

- **Dungeon 2 boss**: Could be a single large entity with projectile-pattern phases. Scene root is a `Node2D` with `BaseBoss` script containing one `CharacterBody2D` child for movement and collision (no additional sub-entities needed). Good showcase for the projectile system built in Phase 2.6.
- Each boss should have at least 2 phases with a visible transition (flash, shake, color change).
- Intros and outros always run through the `Cutscene` autoload — never ad-hoc inline sequencing. Shared defeat cutscene (`boss_defeat.gd`) handles the universal steps (shake, flash, explosion, heart container); per-boss intros can be unique.
- Boss state machines should lean on systems that already exist from Phases 6–8: dialog lines in cutscenes for talking bosses, magic-reactive behavior for bosses that should respond to Fire/Ice Rod, lift-and-throw interactions for bosses with liftable components.
- Because Phase 9 arrives after all gameplay systems, there is no reason to dodge mechanics — a boss can freely require dashing, swimming, lifting, or magic as part of its solution.

### 9.5 Phase 9 Deliverable

Acceptance criteria:

1. `base_boss.gd` script exists with phase-change, encounter-start, and encounter-end hooks.
2. Armos Knights boss scene is fully playable: intro cutscene, Phase 1 formation hopping, Phase 2 solo knight, defeat cutscene, heart container drop, dungeon 1 completion flow triggered via `end_encounter()`.
3. Moldorm boss scene is fully playable: head+segments+tail construction, tail-only vulnerability, speed ramp, defeat cutscene, dungeon 3 completion flow triggered via `end_encounter()`.
4. Reward pedestals from Phases 5 and 7 are replaced by boss scenes in dungeons that ship with bosses. Remaining dungeons (if any are designed with non-boss reward pedestals as a deliberate choice) still function via the Phase 5 pedestal path.
5. All bosses use the shared `Cutscene.*` primitives for intros/outros — zero inline ad-hoc sequencing in boss scripts.
6. All boss persistence works: a defeated boss stays defeated on room re-entry via `{room_id}/{persist_id}` flags.

---

## Architecture Reference

### Signal Flow: Player Takes Damage

```text
Enemy hitbox overlaps player hurtbox
  -> HurtboxComponent validates invincibility and source team
  -> HurtboxComponent emits hurt(hit_data)
  -> Player receives hit_data
  -> Armor and shield rules modify or reject hit
  -> PlayerState.apply_damage(final_damage)
       -> mutates PlayerState.current_health
       -> emits EventBus.player_health_changed(current, max)
       -> if current_health <= 0, emits EventBus.player_died
  -> FlashComponent.flash()
  -> KnockbackComponent.apply(direction, force)
  -> StateMachine.transition_to("knockback")
  -> AudioManager.play_sfx("player_hurt")
  -> EventBus.screen_shake_requested(intensity, duration)
```

Note: the player does **not** have a `HealthComponent` node. Its health state lives on the `PlayerState` autoload so it survives room transitions and is serialized by `SaveManager` without a node-lifecycle dependency. Enemies do have a `HealthComponent` child because they are transient — spawned per room, freed on death, with no persistence. The hurt handler is polymorphic: the player's handler calls `PlayerState.apply_damage()`, while `BaseEnemy._on_hurtbox_hurt()` calls its child `HealthComponent.take_damage()`.

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

Player states extend `BasePlayerState` (types `actor` as `Player`). Enemy states extend `BaseEnemyState` (types `actor` as `BaseEnemy`). Each enemy type has its own state scripts — only `StunnedState` is shared across enemies. Boss states extend `State` directly since bosses use `BaseBoss` (Node2D), not `BaseEnemy` (CharacterBody2D). `BasePlayerState` / `BaseEnemyState` are thin subclasses of `State` that exist only to give `actor` a typed reference — they are distinct from the `PlayerState` autoload (which holds the player character sheet).

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

Skill (Bow):
```gdscript
[gd_resource type="Resource" script_class="ItemData"]

[resource]
id = &"bow"
display_name = "Bow"
item_type = 0  # SKILL
icon_color = Color(0.6, 0.4, 0.2, 1.0)
magic_cost = 0
ammo_type = &"arrows"
ammo_cost = 1
use_script = preload("res://scenes/items/effects/bow_effect.gd")
```

Upgrade (Pegasus Boots):
```gdscript
[gd_resource type="Resource" script_class="ItemData"]

[resource]
id = &"pegasus_boots"
display_name = "Pegasus Boots"
item_type = 1  # UPGRADE
icon_color = Color(0.6, 0.3, 0.1, 1.0)
upgrade_key = &"boots"
tier = 1
```

Resource (Blue Rupee):
```gdscript
[gd_resource type="Resource" script_class="ItemData"]

[resource]
id = &"rupee_blue"
display_name = "Blue Rupee"
item_type = 2  # RESOURCE
icon_color = Color(0.2, 0.3, 0.9, 1.0)
resource_key = &"rupees"
resource_amount = 5
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
| 1 | Link Walks Around a Room | Movement, room loading, player, HUD (hearts, rupees, skill slot), autoloads |
| 2 | Link Fights Enemies | Combat components, enemy archetypes, drops |
| 3 | Link Has Equipment | Skills, upgrades, resources, subscreen |
| 4 | Explorable Overworld | Screen transitions, dungeon structure, world switching |
| 5 | First Dungeon Playable | Dungeon navigation end-to-end, non-boss reward pedestal completion |
| 6 | Feels Like a Game | HUD polish, dialog, cutscene system, shader/particle polish pass, title screen, save/load |
| 7 | Full Game Loop | Additional dungeons, NPCs, heart pieces, expanded overworld |
| 8 | Feature Complete | Glove upgrades (Power Glove/Titan's Mitt), game over, advanced enemies, audio coverage audit |
| 9 | Bosses Complete | Boss architecture, Armos Knights, Moldorm, boss retrofit into Phases 5 and 7 dungeons |

Rules for phase completion:

1. No phase should require throwing away previous systems.
2. Every phase must leave the game in a runnable state.
3. New content should plug into existing resources and managers instead of bypassing them.
4. If a shortcut is taken for milestone speed, it must be written down in the spec or tracked as explicit tech debt.
