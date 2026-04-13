# SPEC.md

## Title

Mega Man X (1993) Mechanics-First Remake in Godot 4.6

## Summary

This project will recreate the feel, control, combat, and progression structure of *Mega Man X* (1993) in Godot 4.6 as a 2D side-scrolling action platformer. The remake is mechanics-first, not pixel-perfect. The priority is to reproduce responsive movement, combat pacing, stage flow, enemy and boss interactions, and progression beats while using a modern, maintainable Godot architecture.

The project will begin and remain placeholder-first until production assets exist. Placeholder visuals, animation hooks, VFX hooks, SFX, and music placeholders must be supported from day one. Core gameplay logic must never depend on final sprite sheets, final sound files, or specific presentation assets.

This document is an implementation spec. It defines scope, architecture, feature requirements, stable gameplay contracts, milestone boundaries, and acceptance criteria so future implementation work can proceed without making new product decisions.

## Vision And Constraints

### Project goals

- Recreate the feel and mechanics of *Mega Man X* in Godot.
- Prioritize movement, combat, boss interactions, stage flow, and progression over audiovisual fidelity.
- Preserve the recognizable campaign structure of the original game while allowing practical implementation tradeoffs.
- Build systems so placeholder assets can be replaced later without gameplay rewrites.
- Follow Godot best practices for scene composition, Resources-based tuning, clear system ownership, and minimal global state.

### Non-goals

- Pixel-perfect art or animation recreation.
- Exact SNES frame data or emulator-level parity.
- Shipping with final-quality art, audio, or VFX in early phases.
- Building every stage and boss before the foundation and vertical slice are proven.
- Adding platform targets or features outside the core single-player PC experience during early development.

### Fidelity rules

- The remake should preserve the original game's mechanics and progression intent where those mechanics shape the play feel.
- When exact replication conflicts with clarity, maintainability, or placeholder-first development, choose the cleaner implementation that preserves feel.
- Do not add modern movement assists such as coyote time, jump buffering, aim assist, or overly generous collision forgiveness by default. These can be added later only if playtesting proves they improve the intended feel.
- Preserve the original campaign beat that X gains key upgrades through progression, including dash unlock gating in the campaign flow.

### Production constraints

- Placeholder assets are required during all early milestones.
- Systems must be reusable and data-driven enough to scale from one vertical slice to the full game.
- Global managers must stay intentionally small.
- Final art and audio production must be treated as a swap-in pass, not a prerequisite for gameplay implementation.

## Scope Of The Full Remake

The full remake target includes the core single-player campaign structure of *Mega Man X*:

- Intro stage.
- Stage select flow for the Maverick stages.
- Maverick stage gameplay loop with bosses and weapon rewards.
- Upgrade collection and progression systems.
- Fortress or endgame sequence and final boss flow.

This spec does not require content-complete design breakdowns for every stage or boss move list yet. It does require that the architecture can support the full campaign structure without rework.

## Architecture Principles

### Overall approach

- Build the game as a 2D side-scroller using reusable scenes and scripts.
- Keep gameplay state and gameplay rules separate from presentation.
- Prefer composition over deep inheritance trees.
- Prefer small, purpose-specific nodes and scripts over one large "gameplay god object."

### Godot implementation defaults

- Use `CharacterBody2D` for the player and for enemies or bosses that rely on kinematic platforming movement.
- Use `Area2D` and dedicated collision shapes for hitboxes, hurtboxes, pickups, and trigger volumes.
- Use Godot `Resource` assets for tunable gameplay data such as player tuning, weapon data, enemy stats, boss weakness tables, drops, and stage metadata.
- Use signals or equivalent semantic event dispatch for cross-system notifications such as damage events, checkpoint activation, boss intro, and audio triggers.
- Keep autoloads limited to systems that genuinely need global lifetime, such as scene flow, audio routing, save/progression, and optional input abstraction.

### Data and tuning

- Values likely to change during feel tuning must live in data resources or clearly isolated configuration constants.
- Runtime state must be separate from authored configuration data.
- Boss weaknesses, upgrade unlock flags, checkpoint data, and stage metadata must be serializable for save/load.

### System boundaries

- Player locomotion, player combat, health and damage, progression, stage flow, UI, audio, and presentation should be independent systems with clear contracts.
- UI displays gameplay state but does not own gameplay decisions.
- Presentation scenes should react to gameplay state rather than contain gameplay authority.
- Enemy and boss behavior code should depend on shared combat and damage contracts instead of bespoke branches for each entity.

### Asset swap readiness

- Gameplay logic must not depend on sprite dimensions, sprite counts, sound filenames, or animation clip names that only final assets would provide.
- Collision shapes, hitboxes, hurtboxes, and gameplay anchors must be authored independently from final visuals.
- Presentation should be driven by semantic states such as `idle`, `run`, `jump`, `dash`, `hurt`, `charge_small`, and `charge_full`.

## Recommended Project Structure

The implementation should grow toward a structure similar to this:

- `scenes/`
- `scripts/`
- `data/`
- `ui/`
- `assets/placeholders/`
- `audio/`
- `autoloads/`
- `tests/` if automated testing is added

Suggested internal grouping:

- `scenes/player`, `scenes/enemies`, `scenes/bosses`, `scenes/stages`, `scenes/ui`
- `scripts/components`, `scripts/systems`, `scripts/resources`, `scripts/state`
- `data/player`, `data/weapons`, `data/enemies`, `data/bosses`, `data/stages`

Exact folder names can evolve, but scene, script, UI, data, and placeholder assets should remain clearly separated.

## Implementation Sketches

The following examples are not final production code. They are reference sketches that show the intended direction for the architecture and the level of separation expected between systems.

### Example player scene composition

The player should be composed from focused child nodes instead of one script owning every responsibility.

```text
Player.tscn
- Player (CharacterBody2D)
  - CollisionShape2D
  - VisualRoot (Node2D)
    - PlaceholderSprite or AnimatedSprite2D
  - Hurtbox (Area2D)
    - CollisionShape2D
  - ShotOrigin (Marker2D)
  - WallCheckLeft (RayCast2D)
  - WallCheckRight (RayCast2D)
  - GroundCheck optional if needed
  - CameraAnchor (Marker2D)
```

Recommended script ownership:

- `Player.gd` owns locomotion state, motion integration, and high-level action routing.
- `PlayerCombat.gd` or a child combat component owns weapon firing, charge timing, and projectile spawning.
- `Hurtbox.gd` receives hit events and forwards valid damage to the player health or state system.
- A presentation script owns animation-state switching and visual-only reactions.

### Example data-driven tuning resource

Player tuning should live in a `Resource` so feel iteration does not require editing controller logic.

```gdscript
class_name PlayerTuning
extends Resource

@export var run_speed: float = 220.0
@export var ground_accel: float = 1800.0
@export var ground_decel: float = 2200.0
@export var air_accel: float = 1200.0
@export var jump_velocity: float = -360.0
@export var gravity_scale: float = 1.0
@export var dash_speed: float = 340.0
@export var dash_duration: float = 0.18
@export var wall_slide_speed: float = 70.0
@export var wall_jump_velocity: Vector2 = Vector2(240.0, -320.0)
@export var invulnerability_time: float = 1.0
```

The player scene should reference one tuning resource instance, and the runtime controller should read values from it rather than store duplicate copies in code.

### Example player controller shape

The locomotion script should be state-aware, but it does not need to be a giant inheritance tree or an overly abstract framework.

```gdscript
extends CharacterBody2D

@export var tuning: PlayerTuning
@export var can_dash_from_start := false

var facing := 1
var locomotion_state: StringName = &"idle"
var dash_unlocked := false

func _physics_process(delta: float) -> void:
    var move_input := Input.get_axis("move_left", "move_right")
    var jump_pressed := Input.is_action_just_pressed("jump")
    var dash_pressed := Input.is_action_just_pressed("dash")

    _update_facing(move_input)
    _apply_horizontal_movement(move_input, delta)
    _apply_gravity(delta)
    _handle_jump(jump_pressed)
    _handle_dash(dash_pressed)

    move_and_slide()
    _update_locomotion_state()
```

Implementation direction:

- Player movement stays in `_physics_process`.
- Input is read through semantic actions only.
- Dash unlock rules are resolved through progression state, not hardcoded stage logic.
- Presentation should observe `locomotion_state` and `facing` instead of recomputing gameplay state from animations.

### Example hit and damage contract

Damage should move through a shared payload so player attacks, enemy attacks, contact damage, and boss weakness checks all speak the same language.

```gdscript
class_name HitData
extends RefCounted

var source: Node
var team: StringName
var weapon_id: StringName
var damage: int
var knockback: Vector2
```

```gdscript
class_name Hurtbox
extends Area2D

signal hit_received(hit: HitData)

@export var owner_team: StringName

func receive_hit(hit: HitData) -> void:
    if hit.team == owner_team:
        return

    hit_received.emit(hit)
```

This is intentionally simple. The actual implementation may add flags like `ignores_iframes`, `hit_pause_scale`, or `damage_kind`, but all damageable entities should still receive one consistent hit payload shape.

### Example weapon definition shape

Weapons should be represented by data plus reusable behavior hooks rather than giant `match` statements inside the player script.

```gdscript
class_name WeaponData
extends Resource

@export var weapon_id: StringName
@export var display_name: String
@export var energy_cost: int = 0
@export var projectile_scene: PackedScene
@export var base_damage: int = 1
@export var supports_charge := false
```

At runtime, `PlayerCombat` should read the equipped `WeaponData`, spawn the configured projectile scene if needed, and emit semantic events like `player_shoot` or `buster_charge_full` for presentation and audio.

## Feature Requirements

### 1. Input And Control Layer

The project needs a stable input abstraction before movement and combat are implemented.

#### Required input actions

- Move left and right.
- Jump.
- Dash.
- Shoot.
- Weapon cycle or weapon select.
- Pause.
- Menu confirm and cancel.

#### Device support

- Keyboard support is required from the start.
- Gamepad support is required from the start because the target play feel depends on controller-friendly input.
- Rebinding is not required for the first vertical slice, but the input action map must be organized so rebinding can be added later without changing gameplay code.

#### Design requirements

- Gameplay systems should read semantic input actions, not hardcoded keys or buttons.
- Menu input and gameplay input should be separable so pause and stage-select flows remain clean.

### 2. Core Player Controller

The player controller must reproduce the core feel of X-style movement at a mechanics level.

#### Required movement capabilities

- Ground movement with tuned acceleration and deceleration.
- Jumping with controllable jump height or equivalent variable-jump behavior.
- Air control that preserves intentional movement without becoming floaty.
- Dash with full state integration.
- Wall slide and wall jump.
- Facing direction updates and turn behavior that support responsive combat.
- Stable transitions between idle, run, jump, fall, dash, wall slide, hurt, and death states.

#### Survivability and interaction

- Damage intake with knockback.
- Temporary invulnerability after damage.
- Death handling and respawn behavior.
- Collision against terrain, moving platforms, and stage hazards.
- Ladder support is part of the full game architecture, but it is not required in Phase 1 unless the first stage slice needs it.

#### Campaign gating decision

- The movement system must support dash from Phase 1 for tuning and testing.
- In campaign progression, dash should be gated behind the intro-stage upgrade event by default, matching the original progression beat.
- Test scenes and debug stages may enable dash from the start to speed iteration.

#### Design requirements

- Movement tuning must be data-driven or otherwise isolated for fast iteration.
- Core movement logic must not depend on final animation assets.
- Movement state must be readable by combat, UI, audio, and presentation systems.

### 3. Player Combat

The player combat system must support the base buster loop first and remain extensible for Maverick weapons later.

#### Required combat capabilities

- Basic buster firing.
- Charge accumulation with at least neutral, partial-charge, and full-charge states.
- Charged shot release behavior.
- Projectile spawning, ownership, travel, lifetime, despawn, and collision.
- Distinction between player projectiles, enemy projectiles, and contact damage.

#### Extensibility requirements

- Weapon switching model for future boss weapons.
- Weapon energy model for non-buster weapons.
- Expandable weapon definitions using shared data and shared behavior contracts.
- Hooks for destructible world objects and breakable entities.

#### Combat behavior requirements

- The player must be able to fire while grounded and airborne.
- Charge state feedback must exist even with placeholder visuals and placeholder audio.
- The system must support boss weakness calculations without special-case boss code in the player weapon logic.

#### Design requirements

- Weapon logic must remain separate from locomotion logic.
- Damage delivery must go through a shared hit and damage contract.
- Combat events must emit semantic feedback hooks for UI, audio, VFX, and camera effects.

### 4. Health, Damage, And Collision Rules

Combat needs a stable shared contract before enemy and boss content scales up.

#### Required shared rules

- A consistent damage payload or hit description that includes at least source, damage amount, damage type or weapon identity, knockback intent, and team ownership.
- Distinct collision layers or collision groups for terrain, player body, enemy body, player projectiles, enemy projectiles, hurtboxes, hitboxes, pickups, and triggers.
- Clear ownership rules so entities cannot damage allies unless explicitly intended.

#### Required outcomes

- Hurt reactions.
- Invulnerability windows where applicable.
- Death callbacks.
- Drop spawning hooks.
- Feedback events for UI, audio, and presentation.

### 5. Enemy Framework

The project needs a reusable enemy framework rather than one-off enemy implementations.

#### Shared enemy contract

- Health and death handling.
- Hurt reactions.
- Contact damage.
- Projectile or attack behavior support.
- Optional drop behavior.
- Spawn, off-screen suspension, and despawn rules tied to stage flow.

#### Behavior model

- Enemies should use a clear behavior model such as state machines or modular action patterns.
- The framework must support simple enemies, patrol enemies, turrets, flying enemies, and encounter-specific enemies.
- Enemy-specific behavior should reuse the shared health, damage, and drop systems.

#### Presentation requirements

- Placeholder visuals must communicate facing, attack state, hurt state, and death state clearly.
- Hit flash, death feedback, and spawn effects must exist as semantic hooks even if the first pass uses simple color flashes or temporary shapes.

### 6. Boss Framework

Bosses need a dedicated encounter framework layered on top of the shared enemy and combat systems.

#### Boss encounter requirements

- Boss intro sequence hook.
- Boss arena activation and lock-in flow.
- Boss health bar support.
- Multi-phase or state-driven attack behavior.
- Boss defeat sequence and reward flow.

#### Combat requirements

- Weakness and resistance support for special weapons.
- Shared damage handling compatible with the global combat contract.
- Explicit boss state transitions for intro, active combat, recovery or stagger if used, defeat, and post-fight reward resolution.

#### Reward requirements

- Boss defeat must update progression data.
- Boss reward flow must support weapon unlocks and stage-clear resolution.

### 7. Stage, Camera, And World Systems

The world layer must support traversal, encounter orchestration, and readable camera behavior.

#### Stage requirements

- Stage scenes with clear entry and exit flow.
- Spawn points and checkpoints.
- Hazards such as pits, spikes, damage volumes, and moving threats.
- Moving platforms and reusable environment interaction patterns.
- Event triggers for encounters, boss intros, gates, tutorials, scripted transitions, and stage completion.

#### Camera requirements

- A side-scrolling gameplay camera with stable follow behavior.
- Camera constraints and zone overrides for traversal and boss encounters.
- Room-lock behavior for boss arenas and other set-piece encounters.
- Support for camera shake hooks driven by gameplay events.

#### Authoring requirements

- Stages should be built from reusable gameplay building blocks where practical.
- Stage-specific scripting should remain simple and explicit.
- Intro stage support is required because it drives dash upgrade progression.

### 8. Progression And Game Flow

The game-wide progression layer must support both single-stage play and campaign continuity.

#### Front-end flow

- Title screen.
- Main menu.
- Intro stage entry.
- Stage select flow after intro stage completion.
- Pause flow.
- Stage completion flow.
- Endgame or fortress flow after the Maverick progression loop is satisfied.

#### Progression systems

- Intro-stage dash unlock gating.
- Boss defeat tracking.
- Weapon unlock tracking.
- Armor upgrade tracking.
- Heart tank tracking.
- Sub tank ownership and fill state tracking.
- Save and load of long-term progression.

#### Save model decision

- Use one local save profile for the initial implementation.
- Save data must include defeated bosses, unlocked weapons, collected upgrades, health expansion state, sub tank ownership and fill state, and relevant campaign progression flags.
- Checkpoints are stage-session state and should not be treated as permanent long-term save data unless a later feature explicitly expands save behavior.

#### Retry model decision

- Early development and the first vertical slice will use immediate retry from checkpoint or stage start instead of replicating the original life economy in full detail.
- Lives and continues are not required for the first implementation milestones.
- If a classic lives system is added later, it must be layered on top of the existing stage retry flow rather than entangled with core movement or combat logic.

### 9. UI And Feedback

UI should present gameplay state clearly while remaining decoupled from gameplay logic.

#### Required UI areas

- Title and main menu UI.
- Player HUD for health.
- Weapon energy display when non-buster weapons are active.
- Boss health display.
- Pause menu.
- Stage select UI.
- Save or profile UI if needed for the single-profile flow.

#### Feedback systems

- Hit flashes.
- Charge indicators.
- Damage feedback.
- Screen shake hooks.
- Placeholder animation and VFX support for movement and combat states.
- Stage clear and weapon unlock feedback hooks.

#### Design requirements

- UI widgets should observe gameplay state rather than own gameplay decisions.
- Feedback triggers should use semantic events so they remain stable when assets change later.

### 10. Audio System

An audio system is required even before real assets exist.

#### Audio architecture requirements

- Separate routing for music and sound effects.
- Semantic event-driven playback API for gameplay and UI events.
- Support for placeholder clips and placeholder music loops.
- Category-based volume control.
- Support for scene-local effects and cross-scene music control.

#### Required semantic events

- `player_jump`
- `player_dash`
- `player_shoot`
- `buster_charge_start`
- `buster_charge_full`
- `player_hurt`
- `enemy_defeat`
- `boss_intro`
- `boss_defeat`
- `checkpoint_activated`
- `stage_clear`
- `menu_confirm`
- `menu_cancel`

#### Design requirements

- Gameplay code must trigger audio by meaning, not by file path.
- Replacing placeholder clips with final assets must not require gameplay rewrites.
- Missing placeholder clips must fail gracefully without breaking gameplay.

#### Recommended implementation approach

- Implement audio as an autoload such as `AudioManager`.
- Use Godot audio buses for at least `Master`, `Music`, and `SFX`.
- Map semantic event IDs to placeholder `AudioStream` assets through data, not hardcoded branches spread across gameplay code.
- Allow both one-shot SFX playback and persistent music playback through separate methods.

#### Example audio manager shape

```gdscript
extends Node

var sfx_events: Dictionary = {}
var music_events: Dictionary = {}

func play_sfx(event_name: StringName) -> void:
    var stream: AudioStream = sfx_events.get(event_name)
    if stream == null:
        return

    var player := AudioStreamPlayer.new()
    player.bus = "SFX"
    player.stream = stream
    add_child(player)
    player.finished.connect(player.queue_free)
    player.play()

func play_music(track_name: StringName) -> void:
    var stream: AudioStream = music_events.get(track_name)
    if stream == null:
        return

    $MusicPlayer.stream = stream
    $MusicPlayer.play()
```

Example gameplay usage:

```gdscript
if Input.is_action_just_pressed("jump") and is_on_floor():
    velocity.y = tuning.jump_velocity
    AudioManager.play_sfx(&"player_jump")
```

This is the intended dependency direction: gameplay emits a semantic request, and the audio system decides what stream to play, on what bus, and how to handle missing placeholders.

### 11. Placeholder Asset Pipeline

Placeholder-first development is part of the spec, not a temporary workaround.

#### Placeholder requirements

- Use clearly named placeholder sprites, shapes, animations, VFX markers, and audio placeholders.
- Keep placeholder asset naming stable across systems.
- Build animation and state hookups around semantic states, not asset-specific assumptions.
- Keep collision shapes, hurtboxes, and hitboxes authored independently from final art.
- Use simple, readable color and shape language so placeholder entities are visually distinguishable during gameplay testing.

#### Swap-readiness requirements

- A future art or audio pass must be able to replace placeholders without changing gameplay behavior.
- Character, enemy, projectile, UI, and stage placeholders must all follow consistent naming and scene conventions.
- Presentation-facing scenes should be swappable while preserving the same gameplay node contracts.

## Public Gameplay Contracts

The implementation should preserve the following high-level contracts so systems remain reusable and replaceable.

### Player state contract

The player system should expose:

- Current locomotion state.
- Facing direction.
- Health state and invulnerability state.
- Charge state.
- Equipped weapon.
- Upgrade capability flags such as dash and armor unlocks.

### Weapon contract

Each weapon definition should provide or describe:

- Weapon identity.
- Fire behavior.
- Charge behavior if applicable.
- Energy cost.
- Damage profile.
- Projectile or hit behavior.
- Compatibility with weakness and resistance checks.

### Damageable contract

Enemies, bosses, destructibles, and optionally the player should share a damage intake contract that supports:

- Receiving hit data.
- Evaluating weakness or resistance modifiers.
- Triggering hurt and death callbacks.
- Emitting feedback hooks for UI, audio, VFX, and camera systems.

### Audio contract

Gameplay systems should emit semantic events rather than direct file references. The audio layer owns clip lookup, category routing, and fallback behavior.

### Save and progression contract

The progression layer should be able to track:

- Defeated bosses.
- Unlocked weapons.
- Collected upgrades.
- Health capacity upgrades.
- Sub tank ownership and fill state.
- Dash unlock state.
- Relevant campaign progression flags.

### Stage contract

Each stage should define:

- Player spawn point.
- Checkpoint data.
- Boss arena trigger data if applicable.
- Stage-clear trigger.
- Stage-specific event hooks.
- Stage metadata needed for progression and scene flow.

## Milestones

### Phase 1: Foundation

Build the reusable technical foundation required for repeatable feature work.

- Establish project structure for scenes, scripts, data, UI, audio, and placeholders.
- Define the input action map and baseline device support.
- Implement the player controller with run, jump, fall, wall interaction, dash support, damage, death, and respawn.
- Implement the base combat system with basic buster fire and charge states.
- Create the shared health, damage, hit, and collision conventions.
- Create reusable enemy and boss skeletons.
- Create the gameplay camera foundation and boss-room constraint support.
- Create the audio manager and semantic event routing with placeholder support.
- Create the initial HUD shell.
- Define placeholder asset conventions and swap rules.

### Phase 2: Vertical Slice

Build one playable end-to-end slice that proves the architecture.

- Create one complete stage slice with traversal, hazards, checkpoints, and stage completion flow.
- Add at least one reusable enemy family.
- Add one boss encounter using the boss framework.
- Connect player, combat, enemies, boss, HUD, progression hooks, camera, and audio end-to-end.
- Validate death, respawn, boss defeat, dash unlock gating, and stage clear flow using placeholders only.

### Phase 3: Full Game Systems

Expand from the vertical slice into the campaign-wide structure.

- Build title flow, intro stage flow, and stage select flow.
- Add special weapon switching and energy usage.
- Add boss weakness tables.
- Add armor upgrades, heart tanks, and sub tanks.
- Add save/load progression.
- Expand reusable stage authoring patterns for multiple stages.
- Build enough endgame flow to support fortress progression and final boss sequencing.

### Phase 4: Completion And Polish

Finish the full remake content and improve overall feel.

- Add the remaining stages and bosses.
- Tune movement, combat, camera, and boss pacing across the whole game.
- Improve placeholder feedback or replace it with production assets.
- Improve readability, usability, and accessibility where practical.
- Perform optimization, bug fixing, and content consistency passes.

## Out Of Scope For Initial Implementation

- Pixel-perfect audiovisual recreation.
- Exact emulation of every SNES-era timing detail.
- Final art production, final audio production, and full polish before core systems are proven.
- Multiplayer and online features.
- Modding support.
- Mobile support.
- General-purpose editor tooling beyond what directly supports this game.

## Validation And Acceptance Scenarios

The implementation should be considered on track when the following scenarios are possible.

### Mechanics baseline

- The player can run, jump, wall jump, dash, shoot, charge, take damage, die, and respawn reliably.
- Core movement and combat values can be tuned without rewriting major systems.
- The player controller works with keyboard and gamepad through the same action map.

### Placeholder-first workflow

- Placeholder art and audio can be swapped without rewriting gameplay logic.
- Core collisions and behaviors remain stable when presentation assets change.
- Presentation scenes can be updated without changing movement, combat, or progression code.

### Vertical slice validation

- One stage slice can be played from start to boss clear using only placeholder assets.
- The slice includes traversal, hazards, checkpoints, at least one enemy family, one boss, death and respawn, and stage completion.
- The intro-stage upgrade flow can unlock dash for campaign progression while debug scenes can still test dash immediately.

### Progression validation

- Boss defeat updates progression state and unlock hooks.
- Save/load restores progression-related unlocks and collected upgrades correctly.
- Retry from checkpoint or stage start functions without relying on a lives system.

### Audio, camera, and UI validation

- Audio responds to gameplay and menu events through semantic triggers.
- The camera handles normal traversal, encounter locking, and boss arenas cleanly.
- The HUD reflects player health, weapon state, charge state, and boss health correctly.

### Extensibility validation

- Adding a new enemy, boss, weapon, or stage follows existing framework patterns rather than bespoke one-off implementations.
- Adding a new placeholder presentation asset does not require changes to gameplay contracts.

## Assumptions

- The project is a 2D side-scrolling action platformer in Godot 4.6.
- Mechanics fidelity is prioritized over pixel-perfect recreation.
- Placeholder-first development is a hard architectural requirement until production assets exist.
- The first implementation target is a vertical slice, not full-game content breadth.
- Dash is technically available in the player controller from Phase 1 but is campaign-gated by intro progression.
- The first save implementation uses a single local profile.
- The first retry model uses checkpoint or stage restart, not a full lives economy.
