# SPEC.md

## Purpose

This document is the high-level technical guide for `megaman-x`.

It is meant to help a game developer jump into the project quickly by answering:

- what the project is trying to preserve
- how the main systems are organized
- which files are the entry points for each subsystem
- where to tweak common gameplay values
- how to add or revise content safely
- how the project is expected to be tested

This document is not a milestone log or an exhaustive implementation dump. The codebase remains the source of truth for exact node trees, signal wiring, data fields, and current tuning values.

## Project Identity

`megaman-x` is a mechanics-first recreation of *Mega Man X* built in Godot `4.6`.

Current project assumptions:

- physics engine: Jolt Physics
- Windows renderer target: `d3d12`
- display target: `1280x720` (`16:9`)

Core goals:

- prioritize control feel, combat clarity, and readable stage flow
- preserve the campaign structure of intro stage, Maverick stages, Sigma Fortress stages, and final Sigma flow
- keep gameplay logic independent from placeholder art and audio
- keep direct stage iteration viable throughout development

## Quick Orientation

If you are new to the project, start with these files:

- `project.godot`: engine settings, autoload registration, project-wide config
- `autoloads/game_flow.gd`: runtime state, stage registry, front-end and campaign transitions
- `scripts/systems/runtime_shell.gd`: how `Main.tscn` mounts stages, HUD, overlays, and front-end screens
- `scripts/systems/stage_definition.gd`: the schema for stage metadata
- `scripts/stages/stage_controller.gd`: stage-local retry, checkpoint, cutscene, and stage-clear flow
- `scenes/player/Player.tscn`: player scene composition
- `scripts/player/player.gd`: locomotion state machine and progression-driven upgrades
- `scripts/player/player_combat.gd`: weapon firing, charge logic, and energy handling
- `scripts/enemies/enemy_base.gd`: shared enemy behavior
- `scripts/enemies/enemy_brain.gd`: simple enemy state machine driver
- `scripts/bosses/maverick_boss.gd`: shared Maverick boss framework
- `scripts/systems/cutscene_director.gd`: cutscene action runner
- `scripts/systems/dialogue_controller.gd`: dialogue playback and overlay mounting
- `autoloads/audio_manager.gd`: semantic audio event registration and playback
- `tests/smoke/phase_1_harness.gd`: main automated gameplay harness

## Design Pillars

### Mechanics First

- player movement and combat readability matter more than cinematic complexity
- gameplay feedback should come from explicit state changes, not hidden hacks
- placeholder assets are acceptable if they preserve good anchors, collisions, and timing

### Clear Ownership

- runtime flow belongs to runtime services and the runtime shell
- stage-local flow belongs to stages and stage controllers
- gameplay state lives in gameplay systems, not UI
- progression changes should route through progression-aware systems instead of one-off scene scripts

### Data-Driven Campaign

- stages, weapons, pickups, and dialogue should be authored through explicit data
- campaign order and unlock logic should come from stage data and progression facts
- avoid filesystem-driven discovery for core gameplay content

### Testable By Default

- stages should be runnable directly
- shared systems should be reusable enough to validate in isolation
- regression-prone gameplay should gain harness coverage when feasible

## Project Layout

Top-level structure:

- `autoloads/`: runtime services only
- `scenes/`: authored scenes
- `scripts/`: reusable gameplay and UI logic
- `data/`: resources for stages, weapons, dialogue, player tuning, and other authorable content
- `audio/`: authored audio assets and notes
- `assets/placeholders/`: placeholder art
- `tests/`: smoke tests, fixtures, and regression helpers

Rules:

- keep stable `res://` paths whenever possible
- prefer shared scripts for reusable behavior and data resources for authored differences
- preserve generated `.import` and `.godot` files unless a task explicitly requires changing them

## Runtime Architecture

### Main Runtime Flow

The runtime entry scene is `scenes/Main.tscn`.

The shell logic lives in `scripts/systems/runtime_shell.gd` and owns three responsibilities:

- mount the active gameplay stage
- mount persistent gameplay HUD
- mount overlay UI and front-end screens

The high-level runtime state lives in `autoloads/game_flow.gd`.

`GameFlow` is responsible for:

- title flow
- stage select
- stage requests
- cutscene transitions
- stage-clear transitions
- ending transitions
- stage registry and stage unlock queries

Rules:

- only one gameplay stage should be active at a time
- stage transitions should route through `GameFlow`, not ad hoc `change_scene` behavior
- stage selection, campaign unlocks, and loading order should come from `StageDefinition` resources, not from directory scanning

### Runtime Services

The project currently assumes only these autoloads:

- `GameFlow`
- `Progression`
- `SaveManager`
- `AudioManager`

Their intended ownership:

- `GameFlow`: runtime state and campaign routing
- `Progression`: persistent campaign facts
- `SaveManager`: save/load serialization
- `AudioManager`: semantic audio events and playback

Do not add new autoloads casually. If a new global service is truly needed, update this spec and `AGENTS.md` with the architectural reason.

## Stage Data And Stage Flow

### Stage Metadata

Stage metadata is defined by `scripts/systems/stage_definition.gd`, with authored resources under `data/stages/`.

A `StageDefinition` identifies:

- `stage_id`
- `display_name`
- `scene_path`
- `stage_group`
- `boss_id`
- `ordered_boss_ids` for multi-encounter stages
- `weapon_reward_id`
- stage-select visibility
- unlock prerequisites
- whether the stage should trigger ending flow on clear

Use stage data for:

- adding a new stage
- changing a stage's reward or unlock behavior
- changing which scene a stage loads
- changing boss encounter order for special stages

### Stage Controller

The stage-level flow owner is `scripts/stages/stage_controller.gd`.

`StageController` is responsible for:

- retry flow
- checkpoint activation
- current respawn point
- stage-local cutscene begin/end
- stage-clear begin
- cleanup of resettable or stage-clear-only objects

If you need to change:

- checkpoint behavior: start with `stage_controller.gd` and `scripts/stages/stage_checkpoint.gd`
- stage-clear timing: start with `stage_controller.gd`
- retry reset behavior: inspect the `stage_resettable` group and `reset_for_stage_retry` methods on stage actors

## Player Architecture

### Where To Start

Core player files:

- scene: `scenes/player/Player.tscn`
- locomotion: `scripts/player/player.gd`
- combat: `scripts/player/player_combat.gd`
- presentation: `scripts/player/player_presentation.gd`
- pickups and persistent upgrades: `scripts/player/pickup_receiver.gd`
- tuning schema: `scripts/player/player_tuning_data.gd`
- default tuning resource: `data/player/default_player_tuning.tres`
- weapon inventory: `scripts/player/weapon_inventory.gd`
- weapon catalog and data: `scripts/player/weapon_catalog.gd`, `scripts/player/weapon_data.gd`, `data/weapons/*.tres`

### Player Scene Composition

`Player.tscn` is intentionally component-oriented.

The important pieces are:

- `Player.gd` on the root body for locomotion and state
- `HealthComponent` for HP, damage, invulnerability, and death
- `Hurtbox` for damage intake routing
- `PlayerCombat` for firing, charge, cooldown, and weapon energy
- `PickupReceiver` for temporary and persistent pickup effects
- `PlayerSensor` for pickup overlap collection
- `CameraAnchor` for follow camera targeting
- `WallCheckLeft` and `WallCheckRight` for wall-slide and wall-jump detection

### Player Locomotion State Machine

The locomotion state machine lives in `scripts/player/player.gd`.

Current states:

- `IDLE`
- `RUN`
- `JUMP`
- `FALL`
- `DASH`
- `WALL_SLIDE`
- `HURT`
- `DEAD`

High-level behavior:

- `Player.gd` reads input, updates timers, resolves wall contact, applies gravity, and chooses the current locomotion state
- hurt and death temporarily override normal movement
- dash is a timed locomotion override
- wall slide is derived from wall contact plus directional input

If you want to change locomotion behavior:

- state transitions: edit `scripts/player/player.gd`
- movement numbers: edit `data/player/default_player_tuning.tres`
- available tuning fields: inspect `scripts/player/player_tuning_data.gd`
- visuals for locomotion states: edit `scripts/player/player_presentation.gd` and the textures assigned in `Player.tscn`

### Tuning Player Movement

The main movement tuning resource is `data/player/default_player_tuning.tres`.

The schema in `scripts/player/player_tuning_data.gd` includes:

- run speed
- acceleration and deceleration
- air control
- jump velocity
- gravity scale
- dash speed and dash duration
- wall slide speed
- wall jump force
- hurt duration
- death delay
- invulnerability time

Rule of thumb:

- if you want to change numbers, start in the `.tres`
- if you want to change behavior, start in `player.gd`

### Player Combat And Weapons

Combat logic lives in `scripts/player/player_combat.gd`.

Key responsibilities:

- maintain combat state
- read shoot input
- manage charge timing
- enforce cooldowns and projectile limits
- consume and restore weapon energy
- spawn projectiles from `ShotOrigin`

Important combat states:

- `READY`
- `FIRING`
- `CHARGING`
- `CHARGED`
- `COOLDOWN`
- `DISABLED`

Weapon flow:

- weapon order and unlocked state are managed by `WeaponInventory`
- weapon definitions live in `data/weapons/*.tres`
- `weapon_catalog.gd` provides the canonical catalog order used by inventory and progression

If you want to:

- tweak a weapon's cost, cooldown, damage, or projectile behavior: edit the relevant `data/weapons/*.tres`
- change charge thresholds or combat-state behavior: edit `scripts/player/player_combat.gd`
- change how unlocked weapons are tracked: inspect `WeaponInventory` and `Progression`

### Player Pickups And Progression Upgrades

Pickup application is handled by `scripts/player/pickup_receiver.gd`.

Use it when working on:

- heart tanks
- armor parts
- sub tanks
- temporary health or weapon refills
- save triggers tied to persistent pickups

`Player.gd` also applies progression-driven upgrades on spawn or progression changes, especially max HP increases from heart tanks.

## Enemy Architecture

### Where To Start

Core enemy files:

- base scene example: `scenes/enemies/Enemy_WalkerBasic.tscn`
- base behavior: `scripts/enemies/enemy_base.gd`
- AI driver: `scripts/enemies/enemy_brain.gd`
- enemy authored data: `scripts/enemies/enemy_data.gd`
- state base class: `scripts/enemies/states/enemy_state.gd`
- current states: `enemy_idle_state.gd`, `enemy_patrol_state.gd`, `enemy_dead_state.gd`
- temporary drops: `scripts/enemies/drop_spawner.gd`

### How Enemy AI Works

Enemy AI is intentionally simple and shallow:

- `EnemyBase` owns shared body movement, damage handling, contact damage, vision activation, defeat flow, and drop spawning
- `EnemyBrain` owns the current state node and transitions between idle, patrol, and dead
- each enemy state is a small node implementing `enter`, `exit`, and `physics_update`

Current wake/sleep behavior:

- the player entering `VisionArea` wakes the enemy
- leaving the area sleeps the enemy
- defeat moves the brain into the dead state

### How To Add A New Enemy Type

Recommended path:

1. Duplicate a working enemy scene such as `Enemy_WalkerBasic.tscn`.
2. Create or assign an `EnemyData` resource for the new enemy.
3. Adjust shared parameters like HP, contact damage, activation range, patrol speed, and drop scene in the data resource.
4. If the behavior can be expressed with existing states, reuse them.
5. If the behavior needs new logic, add a new `EnemyState`-derived script and wire it under `EnemyBrain`.
6. Only branch away from `EnemyBase` when the enemy genuinely does not fit the shared body/vision/contact model.

If you want to tweak:

- generic enemy numbers: edit the `EnemyData` resource
- wake/sleep or contact behavior: edit `enemy_base.gd`
- AI transitions: edit `enemy_brain.gd`
- per-state behavior: edit the state script

## Boss Architecture

### Where To Start

Boss-related files:

- shared boss behavior: `scripts/bosses/maverick_boss.gd`
- generic configurable boss wrapper: `scripts/bosses/generic_maverick_boss.gd`
- stage encounter driver: `scripts/stages/boss_encounter_controller.gd`
- reusable boss-stage wrapper: `scripts/stages/maverick_boss_stage.gd`
- current bespoke bosses: `chill_penguin_boss.gd`, `storm_eagle_boss.gd`, `flame_mammoth_boss.gd`
- current generic boss scene path: `scenes/bosses/GenericMaverickBoss.tscn`

### How Boss Flow Works

There are two layers:

- the boss actor controls phases, movement, attacks, and defeat
- the boss encounter/stage layer controls arena locking, HUD visibility, and handoff into stage clear

`MaverickBoss` currently provides:

- intro phase
- phase one and phase two combat loops
- projectile spawning
- contact damage
- phase change signaling
- defeat signaling

`BossEncounterController` provides:

- boss gate trigger activation
- arena barrier lock/unlock
- encounter active/completed state
- boss HUD data feed

`maverick_boss_stage.gd` wires the stage definition into the encounter, boss display name, and stage-clear handoff.

If you want to:

- tweak a boss's speeds, timings, colors, or attack numbers: edit the boss scene exports or the generic boss profile data in `generic_maverick_boss.gd`
- add a new boss that still fits the shared Maverick model: prefer the shared `MaverickBoss` + boss-stage path
- change arena or HUD behavior: inspect `boss_encounter_controller.gd` and `scripts/ui/boss_hud.gd`

## Dialogue And Cutscenes

### Where To Start

Dialogue and cutscene files:

- dialogue playback: `scripts/systems/dialogue_controller.gd`
- dialogue resource types: `scripts/systems/dialogue_sequence.gd`, `scripts/systems/dialogue_line.gd`
- dialogue UI: `scripts/ui/dialogue_box.gd`, `scenes/ui/DialogueBox.tscn`
- cutscene runner: `scripts/systems/cutscene_director.gd`
- example dialogue asset: `data/dialogue/test_stage_dash_capsule.tres`

### How The Dialogue System Works

Dialogue is resource-driven.

A dialogue sequence is a `DialogueSequence` resource containing:

- `sequence_id`
- `allow_skip`
- `lines`

Each line is a `DialogueLine` resource containing:

- `line_id`
- `speaker_id`
- `body_text`

`DialogueController`:

- loads `DialogueBox.tscn`
- mounts it on the runtime overlay
- advances on `menu_confirm`
- skips on `menu_cancel` when the sequence allows it
- emits sequence and line change signals

### How To Add Or Change Dialogue

Recommended path:

1. Create or edit a resource in `data/dialogue/`.
2. Add or edit `DialogueLine` entries in the `DialogueSequence`.
3. Trigger the sequence from a cutscene action using `CutsceneDirector` with a `show_text` action.
4. If the dialogue is tied to a stage object, inspect the stage-local script that starts the cutscene or dialogue flow.

Use `CutsceneDirector` when dialogue is part of a larger scripted flow such as:

- capsule interactions
- stage events
- camera handoffs
- progression unlocks

## Audio

### Where Audio Lives

Audio assets and notes live under `audio/`.

Current project note:

- placeholder playback is still generated in code for many events
- the default semantic event registration is currently in `autoloads/audio_manager.gd`

### How Audio Works

Gameplay and UI code should emit semantic events like:

- player shot
- player hurt
- charge start
- charge full
- stage clear

`AudioManager` owns:

- music event registration
- SFX event registration
- event existence queries
- playback routing

### How To Swap A Specific Sound

Right now, the default event table is defined in `autoloads/audio_manager.gd`.

If you want to replace a specific sound:

1. Identify the semantic event ID used by the calling gameplay script.
2. Add or load the desired `AudioStream` asset.
3. Register it against that event through `AudioManager`.
4. Keep the event ID stable so gameplay code does not need to know about asset filenames.

If the project later moves from generated placeholder streams to authored assets, preserve the semantic event API rather than rewriting gameplay callers to point at raw files.

## UI

### Where To Start

UI scenes and scripts:

- gameplay HUD: `scenes/ui/GameplayHUD.tscn`, `scripts/ui/gameplay_hud.gd`
- boss HUD: `scenes/ui/BossHUD.tscn`, `scripts/ui/boss_hud.gd`
- title: `scenes/ui/TitleScreen.tscn`, `scripts/ui/title_screen.gd`
- stage select: `scenes/ui/StageSelectMenu.tscn`, `scripts/ui/stage_select_menu.gd`
- stage clear: `scenes/ui/StageClearOverlay.tscn`, `scripts/ui/stage_clear_overlay.gd`
- ending: `scenes/ui/EndingScreen.tscn`, `scripts/ui/ending_screen.gd`

Rules:

- UI should observe gameplay state through signals, queries, or bound references
- gameplay HUD belongs to gameplay runtime states only
- overlay screens should not become the owner of gameplay logic

## Progression And Save

### Progression

Persistent campaign state lives in `autoloads/progression.gd`.

This is where to look for:

- defeated bosses
- unlocked weapons
- cleared stages
- collected persistent pickups
- heart tanks
- armor parts
- sub tanks
- dash unlock
- campaign completion checks

### Save

Save flow lives in `autoloads/save_manager.gd`.

Use it when changing:

- saved fields
- save versioning
- save path
- when the game writes a save

The project currently saves campaign facts, not room-level suspend state.

## Content Authoring Guidelines

### Stages

When adding or revising a stage:

- start with the relevant `StageDefinition` resource in `data/stages/`
- keep stage identity and unlock logic in stage data
- keep stage-local triggers and retry logic in the stage scene and controller
- prefer direct stage launch for iteration

### Weapons

When changing weapon behavior:

- authored values live in `data/weapons/*.tres`
- schema lives in `scripts/player/weapon_data.gd`
- catalog order lives in `scripts/player/weapon_catalog.gd`

### Pickups And Upgrades

When adding persistent upgrades:

- use stable IDs
- route collection through `PickupReceiver`
- update progression instead of storing per-stage custom flags
- ensure the pickup remains safe on replay after save/load

### Placeholder Assets

Placeholder assets should be easy to swap later.

Rules:

- keep collisions and anchors independent from art
- use stable asset names and paths
- do not let gameplay logic depend on placeholder-specific visuals

## Testing Procedure

### Validation Philosophy

Automated checks are agent-owned. Manual feel checks are user-owned.

Rules:

- prefer the narrowest useful validation first
- validate systems in the context where they are authored
- extend the harness when a behavior is regression-prone and repeatable
- keep direct stage launch working as an iteration path

### Standard Validation Order

Use this order unless a task clearly calls for something narrower:

1. Run a headless project boot check.
2. Run the relevant harness-backed automated check.
3. Run neighboring regression checks when shared flow is affected.
4. Leave feel, readability, pacing, and subjective presentation to manual validation.

### Console Workflow

Base smoke check:

```powershell
godot --path . --headless --quit
```

Harness entry point:

```powershell
godot --path . --headless -s res://tests/smoke/phase_1_harness.gd -- <mode>
```

Use harness-backed checks for:

- progression
- rewards
- retry flow
- stage flow
- boss activation and completion
- save/load
- regression fixes

## Documentation Maintenance

This spec should stay onboarding-oriented and architectural.

Rules:

- keep milestone history and delivery-phase notes out of this file
- keep exact implementation details in code, scenes, data, and tests
- record repo workflow details in `AGENTS.md`
- update this document when architecture, subsystem ownership, or content-authoring workflow changes in a meaningful way
