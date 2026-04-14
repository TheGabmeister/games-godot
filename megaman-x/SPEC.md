# SPEC.md

## Summary

Recreate *Mega Man X* (1993) in Godot 4.6 as a mechanics-first 2D action platformer.

This spec is intentionally architecture-first. It defines system ownership, runtime structure, scene boundaries, state machines, data responsibilities, and project rules. It should not serve as a code template.

Use placeholder visuals and placeholder audio early, but organize the project so final assets can replace them without changing gameplay logic.

The target campaign includes:

- `intro_highway`
- the 8 Maverick stages
- Sigma Fortress stages
- final Sigma fights
- boss weapons
- armor parts
- heart tanks
- sub tanks

## Project Layout

Use a consistent top-level structure from the start.

Recommended folders:

- `autoloads/` for the four runtime services only
- `scenes/player/` for player scenes
- `scenes/enemies/` for enemy scenes
- `scenes/bosses/` for boss scenes
- `scenes/stages/` for stage scenes and stage-local helpers
- `scenes/ui/` for menus, HUD, dialogue, and overlays
- `scripts/components/` for reusable gameplay components such as health, hurtboxes, projectiles, and checkpoints
- `scripts/player/` for player-specific logic
- `scripts/enemies/` for enemy-specific logic and AI states
- `scripts/bosses/` for boss-specific logic and phase controllers
- `scripts/systems/` for reusable runtime systems that are not autoloads
- `data/stages/` for `StageDefinition` resources
- `data/weapons/` for weapon data resources
- `data/dialogue/` for dialogue sequences and cutscene-adjacent text data
- `audio/` for placeholder and final audio assets
- `assets/placeholders/` for temporary art and effects

Rules:

- scenes live under `scenes/`, reusable logic under `scripts/`, and authorable data under `data/`
- stage-local content may live with the stage scene when it is not intended to be reused elsewhere
- use stable `res://` paths from the beginning so future asset swaps do not require path churn

## Runtime Services

Use these autoloads only:

- `autoloads/game_flow.gd`
- `autoloads/progression.gd`
- `autoloads/save_manager.gd`
- `autoloads/audio_manager.gd`

### Application shell

Use one non-autoload runtime shell scene to host the active game content.

Recommended structure:

```text
Main.tscn
- Main
  - WorldRoot
  - UIRoot
  - OverlayRoot
```

Responsibilities:

- `WorldRoot` holds the active stage scene
- `UIRoot` holds persistent gameplay UI such as HUD
- `OverlayRoot` holds modal layers such as pause, dialogue, and stage-clear overlays

Rules:

- `GameFlow` coordinates transitions, but the runtime shell owns actual scene instancing and teardown
- only one stage scene should be active in `WorldRoot` at a time
- runtime UI should be layered without adding more autoloads

State-to-scene mapping:

- `BOOT` initializes the runtime shell and then hands off to title flow
- `TITLE` shows the title menu in `UIRoot` with no active stage in `WorldRoot`
- `STAGE_SELECT` shows stage selection in `UIRoot` with no active stage in `WorldRoot`
- `IN_STAGE` loads one stage scene into `WorldRoot` and the gameplay HUD into `UIRoot`
- `PAUSED`, `CUTSCENE`, and `STAGE_CLEAR` are overlay states layered on top of `IN_STAGE`
- `ENDING` may use either a full-screen UI scene or a controlled ending sequence, but it is not a normal gameplay stage

Handoff contract:

- `GameFlow` decides the next runtime state and semantic destination
- the runtime shell resolves that destination into scene instances, loads them, and tears down the previous content
- stage lookup must come from explicit stage data or an explicit registry, never from filesystem discovery

### `GameFlow`

Purpose:

- own high-level runtime state
- own scene transitions
- coordinate boot, menus, stage entry, pause, cutscenes, and ending flow

Runtime states:

- `BOOT`
- `TITLE`
- `STAGE_SELECT`
- `IN_STAGE`
- `PAUSED`
- `CUTSCENE`
- `STAGE_CLEAR`
- `ENDING`

Rules:

- stage requests should flow through `GameFlow`
- stage scenes should not own the global boot or menu flow
- cutscenes should switch the game into a dedicated cutscene mode
- pause and resume should be mediated through `GameFlow`, not handled independently by stage scenes

Flow rules:

- a new game always starts by entering `intro_highway`
- continue uses saved progression but does not resume an in-progress room or checkpoint
- if intro has not been cleared, continue returns the player to `intro_highway` from its start
- if intro has been cleared, continue returns the player to stage select
- stage restart and return-to-stage-select requests should also route through `GameFlow`

### `Progression`

Purpose:

- own in-memory campaign state
- track what the player has unlocked or permanently collected

Tracks:

- defeated bosses
- unlocked weapons
- collected persistent pickups
- armor parts
- dash unlock
- intro clear flag
- fortress unlock state
- sub tank ownership and fill state
- campaign unlock markers used to derive stage availability

Rules:

- `Progression` owns campaign facts, not moment-to-moment gameplay state
- systems that award permanent progress should update `Progression`
- stage availability should be derived from progression facts where possible instead of duplicated as separate saved booleans

Campaign unlock rules:

- a new save starts with `intro_highway` as the only required entry point
- clearing `intro_highway` unlocks dash and the 8 Maverick stages
- defeating a Maverick boss unlocks that boss weapon immediately
- Sigma Fortress unlocks only after all 8 Maverick bosses are defeated
- fortress stages unlock sequentially from `sigma_fortress_1` through `sigma_fortress_4`
- persistent pickups stay collected on replay once recorded in `Progression`

### `SaveManager`

Purpose:

- serialize and deserialize progression data only

Rules:

- save to `user://save_01.json`
- use a versioned payload
- convert between save data and `Progression`
- do not place gameplay rules in `SaveManager`
- save triggers should be defined centrally rather than scattered across gameplay scripts

### `AudioManager`

Purpose:

- own music playback
- own SFX playback
- own bus routing
- map semantic audio events to streams

Rules:

- gameplay systems should request semantic events, not raw file paths

## Player

Keep all player-related implementation in the player area of the project, but keep responsibilities split by subsystem.

Player responsibilities are divided across:

- `Player.gd` for locomotion, facing, and movement state
- `PlayerCombat.gd` for firing, charge behavior, and weapon usage
- `HealthComponent.gd` for HP, damage intake, invulnerability, and death signaling
- `PickupReceiver.gd` for applying pickup effects
- visual and animation nodes for presentation only

### Player scene

```text
Player.tscn
- Player (CharacterBody2D) [Player.gd]
  - CollisionShape2D
  - VisualRoot
  - Hurtbox
  - HealthComponent
  - PlayerCombat
    - WeaponInventory
  - PickupReceiver
  - PlayerSensor
  - ShotOrigin
  - WallCheckLeft
  - WallCheckRight
  - CameraAnchor
```

### Input

Required actions:

- `move_left`
- `move_right`
- `jump`
- `dash`
- `shoot`
- `weapon_next`
- `pause`
- `menu_confirm`
- `menu_cancel`

Rules:

- support both keyboard and gamepad
- gameplay code reads input actions only
- gameplay code should not depend on raw keys or buttons

### Player tuning data

Use a dedicated data resource for player tuning values.

It should hold movement and combat-adjacent tuning such as:

- run speed
- acceleration and deceleration
- air control
- jump velocity
- gravity scale
- dash speed and duration
- wall slide speed
- wall jump force
- invulnerability time

Rules:

- balance values should live in data, not be hardcoded into logic

### Player controller

`Player.gd` owns:

- locomotion
- facing direction
- grounded and airborne movement handling
- wall movement handling
- movement-side state evaluation

`Player.gd` should not own:

- weapon inventory rules
- projectile spawning rules
- pickup application logic
- cutscene logic

### Player locomotion state machine

Use a single locomotion state machine in `Player.gd`.

States:

- `IDLE`
- `RUN`
- `JUMP`
- `FALL`
- `DASH`
- `WALL_SLIDE`
- `HURT`
- `DEAD`

Priority order:

- `DEAD`
- `HURT`
- `DASH`
- `WALL_SLIDE`
- `JUMP`
- `FALL`
- `RUN`
- `IDLE`

Rules:

- dash exists in code from the start
- campaign dash unlock is gated by the intro-stage capsule
- debug stages may enable dash immediately
- ladder support belongs to the full game plan, but it does not need to block the first playable slice

### Player combat

`PlayerCombat.gd` owns:

- weapon firing
- shot timing and cooldown
- charge behavior
- projectile spawning requests
- weapon energy consumption and restoration

`PlayerCombat.gd` does not own locomotion.

Use weapon data resources for:

- weapon ID
- display name
- energy cost
- projectile scene reference
- base damage
- charge support
- charge thresholds or max charge level

Combat behavior rules:

- only one weapon is equipped at a time
- weapon data should define any active projectile limit for that weapon
- for the first implementation, `buster` is the only weapon that needs charge behavior
- charge release samples the equipped weapon and facing at the moment the shot is spawned
- entering `DISABLED`, `HURT`, `DEAD`, or cutscene control cancels any in-progress charge unless a specific weapon later opts into different behavior

### Weapon switching

Use a dedicated `WeaponInventory` node under `PlayerCombat`.

Rules:

- the weapon order is explicit
- `buster` starts unlocked
- unlocked boss weapons are added through progression
- cycling should skip locked weapons
- weapon switching updates the HUD through combat or inventory signals rather than direct UI polling of input
- for the first implementation, weapon switching is ignored while a charge is being held

### Combat state machine

Use a separate combat state machine in `PlayerCombat.gd`.

States:

- `READY`
- `FIRING`
- `CHARGING`
- `CHARGED`
- `COOLDOWN`
- `DISABLED`

Rules:

- locomotion and combat run in parallel
- movement state should not block valid combat state changes by default
- combat may be disabled temporarily during hurt, death, or cutscenes when needed
- combat cooldown rules should be owned by weapon or combat data, not spread across player and projectile scripts

These combinations must be supported:

- `RUN + READY`
- `JUMP + FIRING`
- `DASH + CHARGING`
- `WALL_SLIDE + CHARGED`
- `HURT + DISABLED`

### Player presentation

Player visuals should read gameplay state, not define it.

Presentation responsibilities:

- facing-based sprite or animation flipping
- locomotion-state presentation
- combat-state presentation
- hurt, invulnerability, and charge feedback

Rules:

- visual nodes should derive their state from locomotion and combat state machines
- animation playback should not become the authoritative source of gameplay state

### Player pickups

Pickups should apply effects through `PickupReceiver.gd`, not through `Player.gd`.

`PickupReceiver` owns:

- health refill application
- weapon energy refill application
- persistent reward routing into `Progression`

`PlayerSensor` should detect pickup `Area2D`s and pass them to `PickupReceiver`.

### Player death and respawn

Death and respawn are stage-flow concerns, not self-contained player logic.

Rules:

- `HealthComponent` signals player death
- `StageController` decides whether to respawn at checkpoint or restart the stage
- player scripts should not reload scenes directly on death

## Shared Gameplay Systems

This section defines systems shared by player, enemies, bosses, hazards, and world interactions.

### Health and damage

Use one shared hit payload shape and one shared health component.

Shared concepts:

- hit payload contains the source, team, weapon identity, damage, and knockback
- hurtboxes filter incoming hits by team
- health components process damage, invulnerability, death, and health signals

Rules:

- use the same damage pipeline for player, enemies, and bosses
- hazards should integrate with the same damage model where practical
- the source of a hit defines intended damage and knockback, but the target decides how that knockback is resolved in its own movement logic

### Projectiles

Use one shared projectile contract for player and enemy attacks.

Projectile data or configuration should define:

- owner team
- weapon ID
- damage payload
- movement behavior
- lifetime
- hit behavior against world and targets

Rules:

- projectiles own travel and lifetime, not progression logic
- projectile hits should produce the same shared hit payload used elsewhere
- player and enemy projectile scenes may differ visually, but they should follow the same damage-routing model
- the default projectile behavior is single-hit and destroy-on-hit unless projectile data says otherwise
- world collision should be data-driven so weapons can choose whether they stop on solid tiles, ignore one-way surfaces, pierce, or explode
- multi-hit or lingering projectiles must define their per-target hit interval explicitly to avoid accidental rapid-hit behavior

### Damage modifiers and weaknesses

Use data-driven damage modifiers for bosses and, when useful, for enemies.

Rules:

- default damage comes from weapon data unless an enemy or boss overrides it
- weakness and resistance tables should be keyed by stable weapon IDs
- weapon weakness logic should live on the target side or shared combat data, not inside player movement scripts
- target-side damage modifiers should support immunity, resistance, normal damage, and weakness without special-casing individual player weapons

### Collision layers

Keep these layer numbers stable:

| Layer | Name |
| --- | --- |
| 1 | `WORLD_SOLID` |
| 2 | `WORLD_ONE_WAY` |
| 3 | `PLAYER_BODY` |
| 4 | `ENEMY_BODY` |
| 5 | `PLAYER_HITBOX` |
| 6 | `ENEMY_HITBOX` |
| 7 | `PLAYER_HURTBOX` |
| 8 | `ENEMY_HURTBOX` |
| 9 | `PICKUP` |
| 10 | `TRIGGER` |
| 11 | `HAZARD` |
| 12 | `CAMERA_ZONE` |
| 13 | `PLAYER_SENSOR` |

Recommended usage:

- character bodies collide with world layers
- hitboxes and hurtboxes use `Area2D`
- pickups, checkpoints, cutscene triggers, and camera zones use `Area2D`
- hazards use `Area2D` and plug into the shared hit or hazard pipeline

## Enemies And Bosses

### Campaign roster

Stages and bosses:

- `intro_highway` with scripted `vile_ride_armor`
- `chill_penguin`
- `spark_mandrill`
- `armored_armadillo`
- `launch_octopus`
- `boomer_kuwanger`
- `sting_chameleon`
- `storm_eagle`
- `flame_mammoth`
- `sigma_fortress_1` with `bospider`
- `sigma_fortress_2` with `rangda_bangda`
- `sigma_fortress_3` with `velguarder`
- `sigma_fortress_4` with `sigma_first_form` and `sigma_wolf_form`

Weapon rewards:

- `shotgun_ice`
- `electric_spark`
- `rolling_shield`
- `homing_torpedo`
- `boomerang_cutter`
- `chameleon_sting`
- `storm_tornado`
- `fire_wave`

Use stable internal IDs for regular enemy families such as:

- `walker_basic`
- `turret_basic`
- `hopper_basic`
- `flying_drone_basic`
- `shield_guard_basic`
- `mine_dropper_basic`

### Enemy scene and logic

Enemy inheritance stays shallow.

Core enemy parts:

- `EnemyBase.gd` as the main scene script
- `HealthComponent.gd` for HP
- `Hurtbox.gd` for incoming hit routing
- `EnemyBrain.gd` for AI state transitions
- `DropSpawner` or equivalent for temporary drops
- enemy data resource or equivalent authored configuration

Example structure:

```text
Enemy_WalkerBasic.tscn
- EnemyWalkerBasic (CharacterBody2D) [EnemyBase.gd]
  - CollisionShape2D
  - VisualRoot
  - Hurtbox
  - HealthComponent
  - VisionArea
  - AttackOrigin
  - EnemyBrain
  - DropSpawner
```

Rules:

- avoid deep enemy inheritance trees
- keep common combat and health behavior shared
- keep enemy-specific behavior in data, states, or small scripts
- placed enemies should be authored from explicit scene instances or spawn definitions, not discovered dynamically at runtime

Enemy authored data should cover at least:

- enemy ID
- max health
- contact damage or touch-hit behavior
- optional projectile or attack references
- optional drop behavior
- activation range or activation policy
- reset behavior on retry

### Enemy AI

Use small state scripts, not one giant enemy update loop.

Reusable enemy state types:

- `IdleState`
- `PatrolState`
- `ChaseState`
- `AttackState`
- `RecoverState`
- `DeadState`

Rules:

- `EnemyBrain` owns transitions between states
- individual states own localized behavior
- enemy behavior should be composable, not hardwired into one monolithic class
- non-boss enemies should use a clear activation policy so off-screen behavior is predictable

Activation and reset policy:

- default stage enemies wake when the player enters their activation range or camera-relevant area
- enemies outside the active gameplay area should not continue running expensive AI unnecessarily
- defeated enemies and temporary enemy drops are stage-run state only and reset on retry
- retrying from a checkpoint rebuilds enemies and temporary stage objects from authored state for the current run

### Boss scene and logic

Bosses use the shared combat and health systems plus a boss-specific phase controller.

Example structure:

```text
Boss_ChillPenguin.tscn
- BossChillPenguin (CharacterBody2D) [BossBase.gd]
  - CollisionShape2D
  - VisualRoot
  - Hurtbox
  - HealthComponent
  - BossPhaseController
  - AttackOrigin
  - IntroMarker
  - ArenaMarker
```

Boss requirements:

- intro hook
- health bar integration
- arena lock behavior
- weakness and resistance handling
- reward flow through `Progression`

Rules:

- boss phase changes should be controlled by explicit thresholds or conditions
- boss rewards should not bypass progression systems
- bosses should expose stable IDs for progression, weakness tables, and UI hookup
- bosses should remain stage-owned encounters and should not use the generic off-screen despawn policy used by normal enemies

Boss phase authoring should define:

- ordered phase list
- entry condition for each phase
- attacks or behaviors enabled in each phase
- one-time transition actions
- end-of-fight handoff back to `StageController`

## Stages, Camera, And Pickups

### Stage data

Use a stage definition resource for stage metadata.

Stage data should identify:

- stage ID
- display name
- stage scene
- boss ID
- weapon reward ID
- music event or track ID
- default spawn ID
- default unlock behavior
- intro-clear requirements
- optional intro or stage-clear cutscene IDs

Rules:

- stage IDs are the canonical keys used by `GameFlow`, progression, stage select, save data, and audio lookup
- stage metadata should be authored explicitly and reused across title flow, stage select, and stage loading

### Stage scene layout

Use a consistent stage root structure.

```text
Stage_FlameMammoth.tscn
- StageController
  - CameraController
  - TilemapRoot
  - BackgroundRoot
  - SpawnPoints
  - Checkpoints
  - Enemies
  - Pickups
  - Capsules
  - Triggers
  - CameraZones
  - HazardZones
  - BossArena
```

### Stage controller

`StageController.gd` owns stage-local flow.

Responsibilities:

- player spawn
- checkpoint activation
- trigger wiring
- stage-local boss references
- camera zone activation
- stage complete signaling
- stage-local cutscene entry points

Rules:

- stage scenes should be runnable directly for testing
- standalone stage testing should not require the full boot flow
- stage-local debug progression is allowed for development convenience
- stage completion should award progression updates before leaving the stage
- stage-local systems should report upward to `StageController` rather than changing global flow directly

Stage completion rules:

- stage clear is a stage-controller decision, not just a boss death signal
- for Maverick and fortress stages, defeating the stage boss starts the stage-clear flow
- progression rewards, cutscene outcomes, and save triggers occur before exiting the cleared stage
- once stage-clear flow begins, normal gameplay input should not resume unless the flow explicitly returns control

### Checkpoints and hazards

Checkpoints are stage-local retry anchors.

Checkpoint rules:

- checkpoints use stable stage-local IDs
- `StageController` owns the active checkpoint for the current run
- checkpoints are not permanent campaign progression facts and should not be stored in the save file
- activating a checkpoint updates the respawn anchor for the current run only
- retrying from checkpoint respawns the player at that checkpoint and rebuilds temporary stage state from authored content

Hazard rules:

- hazards may either apply standard damage or cause an instant death or fall reset depending on the hazard type
- hazards should use shared systems where possible instead of bespoke per-stage logic
- out-of-bounds or pit recovery should route through `StageController`
- retry should reset temporary pickups, temporary drops, breakable objects, and enemy state unless a stage-specific rule intentionally says otherwise

### Camera

Use one gameplay camera per stage, not multiple active gameplay cameras.

Camera modes:

- `FOLLOW`
- `ZONE_LOCK`
- `BOSS_LOCK`
- `CUTSCENE`

Rules:

- follow `Player/CameraAnchor`
- clamp to stage bounds or zone bounds
- boss fights switch to `BOSS_LOCK`
- cutscenes temporarily take camera control
- use light additive shake, not heavy cinematic motion

### Pickups and powerups

Persistent pickups live in the stage scene. Temporary drops spawn at runtime.

Pickup categories:

- health refill
- weapon-energy refill
- heart tank
- sub tank
- armor capsule

Pickup data should identify:

- pickup ID
- pickup type
- whether it is persistent
- effect payload such as health, weapon energy, or armor part

Persistent pickup rules:

- heart tanks, sub tanks, and armor capsules are persistent
- health and weapon-energy refills are not persistent
- use stable IDs like `intro_highway_dash_capsule` or `storm_eagle_heart_tank`
- stage load should skip already collected persistent pickups
- persistent pickup collection should trigger a save opportunity once the pickup is confirmed

## Progression, Stage Select, And Save

### Stage select

Use a dedicated stage select scene such as `scenes/ui/stage_select_menu.tscn`.

Rules:

- render a fixed roster from `StageDefinition` resources
- stage order is explicit, not derived from the filesystem
- after intro clear, unlock the 8 Maverick stages
- unlock fortress stages only when the required progression flags are set
- `intro_highway` does not need to appear in the normal stage select flow after it has been cleared
- fortress stage ordering is explicit and should not be inferred from filenames

### Save system

Initial save format:

- JSON
- versioned
- stored at `user://save_01.json`
- one local save profile in the initial implementation

Serialized fields:

- save format version
- boss defeat flags
- weapon unlock flags
- persistent pickup collection IDs
- armor unlock flags
- dash unlock flag
- sub tank ownership and fill values
- intro-clear flag
- fortress-unlock flag

Do not serialize:

- live enemy instances
- temporary pickups
- current checkpoint as a permanent campaign fact
- moment-to-moment HP or weapon energy unless a suspend-save system is added later

Save trigger policy:

- save after stage clear and reward payout
- save after newly collected persistent pickups or capsules
- do not save on temporary pickups or every checkpoint touch by default
- continuing from save restores campaign progression only, then re-enters the appropriate front-end flow rather than reconstructing an in-progress stage snapshot

### Retry model

For the first implementation:

- retry from checkpoint or stage start
- no full lives or continues system required yet
- lives can be layered on later without changing movement or combat architecture

## Cutscenes And Dialogue

### Cutscenes

Use a data-driven `CutsceneDirector.gd`.

Cutscene logic should not live in player scripts.

Primary use cases:

- intro stage opening
- Zero rescue
- Dr. Light capsule sequences
- boss intro stingers
- stage clear reward flow
- ending and fortress transitions

First-pass cutscene actions:

- `move_actor`
- `play_animation_state`
- `camera_pan_to_marker`
- `wait`
- `show_text`
- `emit_audio_event`
- `unlock_dash`
- `end_stage`

Rules:

- cutscenes should coordinate actors, camera, audio, and dialogue
- progression changes triggered by story moments should still route through the proper gameplay systems
- stage scripts may start cutscenes, but the cutscene system owns sequence execution once started
- only one cutscene should be active at a time
- entering a cutscene disables normal gameplay input and any combat actions that should not run during scripted control
- exiting a cutscene must restore player control, camera ownership, and gameplay state in a defined order

Cutscene skip and interruption rules:

- skippability is authored per cutscene or per sequence
- skipping a cutscene must still apply any required progression or stage-state outcomes
- if a cutscene is unskippable, dialogue skipping rules cannot bypass it
- stage-critical cutscenes should start only when the stage is in a safe state for control handoff

### Dialogue

Dialogue is a subsystem used by cutscenes. It should not own progression changes or camera movement.

Files:

- `scenes/ui/dialogue_box.tscn`
- `scripts/ui/dialogue_box.gd`
- `scripts/systems/dialogue_controller.gd`
- `data/dialogue/*.tres` or `data/dialogue/*.json`

Dialogue data should support:

- sequence IDs
- line IDs
- speaker IDs
- body text
- portrait references
- optional voice or SFX events
- skippable versus unskippable sequence behavior

Input rules:

- `menu_confirm` advances dialogue
- `menu_cancel` may skip only skippable sequences
- gameplay input stays disabled while dialogue is active
- dialogue completion should return control to the active cutscene or stage flow explicitly rather than implicitly assuming gameplay resumes

Capsule flow example:

1. Player enters a capsule trigger.
2. `StageController` starts a cutscene.
3. `CutsceneDirector` shows the related dialogue sequence.
4. `DialogueController` presents the sequence.
5. The cutscene awards the unlock through gameplay systems.
6. `Progression` marks the capsule collected.

## Audio

Audio is event-driven. Gameplay code triggers semantic events, not raw file paths.

Required semantic events:

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

Implementation rules:

- one autoload: `AudioManager`
- use buses such as `Master`, `Music`, and `SFX`
- use data-driven event-to-stream mapping
- missing placeholder clips should fail silently
- stages, bosses, UI, and cutscenes all use the same semantic event vocabulary

## UI

Required UI:

- title and menu UI
- player HUD
- weapon energy display
- boss health display
- pause menu
- stage select UI
- dialogue box

UI rules:

- UI reads gameplay state
- UI does not own gameplay logic
- stage clear and weapon unlock feedback should use the same UI system
- HUD should expose player HP, equipped weapon, weapon energy, and boss HP when relevant
- pause, dialogue, and stage-clear screens should behave as overlay UI, not separate gameplay scenes
- gameplay HUD is owned by the runtime shell and shown only during gameplay states
- boss UI is driven by the currently active boss encounter selected by `StageController`
- UI should consume state through signals, explicit references, or read-only queries, not by duplicating gameplay state internally

## Validation Strategy

Before broader content production starts, the project should be able to validate these loops cheaply:

- headless project boot
- direct stage launch from the editor
- player spawn, movement, combat, damage, death, and retry in a test stage
- boss defeat into progression update
- persistent pickup collection into save and reload

Validation rules:

- prefer the narrowest useful validation first
- direct stage testing should remain a first-class workflow throughout development

Recommended validation order:

1. Run a headless project boot check.
2. Launch the current stage scene directly in the editor.
3. Verify spawn, movement, combat, damage, death, and retry in that stage.
4. Verify one persistent pickup and one checkpoint flow.
5. Verify boss defeat, reward payout, save, and return to front-end flow.

Validation expectations for new work:

- new player or shared-system work should be validated in the narrowest possible test stage
- new progression or save work should include a save-load smoke check
- new cutscene or dialogue work should include both normal completion and skip-path checks

## Placeholder Asset Rules

- use stable placeholder names
- keep collision and hitboxes separate from visuals
- drive visuals from semantic states such as `idle`, `run`, `dash`, `hurt`, `charge_small`, and `charge_full`
- keep character, enemy, projectile, UI, and stage placeholder conventions consistent

## Milestones

The original milestone buckets were too large to reliably complete in a single turn. Use the smaller phases below instead.

Validation format for every phase:

- automated checks should be the narrowest useful headless or script-driven verification for the systems added in that phase
- manual validation should focus on feel, control flow, and visible state changes that are difficult to assert purely through automation
- each phase should add to the regression checklist rather than replacing it

### Phase 1

Scope:

- project structure
- runtime shell
- autoload registration
- one test stage
- standalone stage testing

Automated checks:

- headless project boot succeeds
- `Main.tscn` loads with the expected root layers
- required autoloads exist and initialize without errors
- test stage can be instanced directly without going through title flow

Manual validation:

- launch the project normally and confirm title flow appears
- launch the test stage directly from the editor
- confirm only one gameplay stage is active at a time

Bug watch:

- missing or duplicate autoload registration
- runtime shell loading the wrong scene layer
- test stage depending on title flow to boot correctly

### Phase 2

Scope:

- player movement
- player locomotion state machine
- camera follow hookup

Automated checks:

- locomotion states transition correctly for idle, run, jump, and fall
- player spawn creates a controllable player instance in the test stage
- camera follows the player anchor without null-reference errors

Manual validation:

- run left and right, jump, fall, and stop repeatedly
- verify facing direction changes cleanly
- verify camera follow feels stable during jumps and landings

Bug watch:

- stuck locomotion states
- frame-rate-dependent movement
- camera jitter, lag spikes, or wrong follow target

### Phase 3

Scope:

- shared health, damage, and collision
- player death and respawn flow
- retry from stage start

Automated checks:

- hit payload damages valid targets and ignores same-team hits
- player death signal triggers retry flow from stage start
- stage retry reconstructs temporary run state from authored content

Manual validation:

- take damage from an enemy or hazard
- die and confirm restart from the stage start anchor
- verify the stage looks reset after retry

Bug watch:

- invulnerability not respected
- duplicate death or retry triggers
- stale temporary objects surviving across retry

### Phase 4

Scope:

- player combat
- projectile pipeline
- audio manager
- HUD shell

Automated checks:

- firing spawns projectiles from the correct origin
- projectile limits and cooldown rules are enforced
- charge start and release follow expected combat state changes
- HUD receives weapon and health updates
- semantic audio events resolve without runtime errors

Manual validation:

- fire repeatedly while grounded and airborne
- charge and release the buster
- take damage while charging
- confirm HUD and placeholder SFX react correctly

Bug watch:

- duplicate projectiles or ignored projectile limits
- charge state getting stuck
- HUD desync from gameplay state
- leaked or overlapping audio playback nodes

### Phase 5

Scope:

- one enemy family
- enemy activation and reset behavior

Automated checks:

- enemy activation range wakes the enemy correctly
- defeated enemy state resets on retry
- temporary drops from the enemy are removed on retry

Manual validation:

- approach and leave an enemy activation area
- defeat the enemy and retry the stage
- verify the enemy and any drop behavior reset correctly

Bug watch:

- off-screen enemies running AI forever
- enemies not resetting after retry
- drops persisting incorrectly across resets

### Phase 6

Scope:

- hazards
- checkpoints
- retry from checkpoint

Automated checks:

- touching a checkpoint updates the current respawn anchor
- retry from checkpoint uses the latest active checkpoint
- hazard types trigger the expected damage or instant-death behavior

Manual validation:

- activate multiple checkpoints in order
- die to hazards before and after checkpoint activation
- verify respawn location and stage reset behavior

Bug watch:

- wrong respawn anchor used after death
- hazards applying damage too often or not at all
- checkpoint state not updating reliably

### Phase 7

Scope:

- stage clear flow
- one full non-boss stage slice

Automated checks:

- stage clear transitions through `StageController` exactly once
- gameplay input is disabled during stage-clear flow
- stage-clear overlay or handoff state appears without leaving stale gameplay state behind

Manual validation:

- complete the non-boss stage slice from start to finish
- confirm stage-clear presentation appears and control does not return unexpectedly

Bug watch:

- duplicate stage-clear triggers
- lingering gameplay input after clear
- temporary stage objects surviving into post-clear flow

### Phase 8

Scope:

- dash unlock flow
- stage-local cutscene
- dialogue flow

Automated checks:

- cutscene start and end transitions occur in the expected order
- dialogue advances and skip rules behave as authored
- dash unlock updates progression and becomes available after the event

Manual validation:

- trigger the dash capsule flow
- play the cutscene normally once and skip it once if skippable
- confirm control returns correctly and dash is available afterward

Bug watch:

- control not restored after cutscene
- duplicate unlock rewards
- camera ownership not restored after dialogue or cutscene completion

### Phase 9

Scope:

- save and load
- progression plumbing
- persistent pickup save triggers

Automated checks:

- save payload round-trips cleanly through save and load
- persistent pickup collection updates progression and survives reload
- continuing from save returns to the correct front-end flow

Manual validation:

- collect a persistent pickup, save, reload, and verify it stays collected
- test a fresh save and an existing save path

Bug watch:

- corrupted or partial save payloads
- progression flags not restored consistently
- persistent pickups reappearing after reload

### Phase 10

Scope:

- stage select
- multiple stage loading
- fortress unlock flow

Automated checks:

- stage select roster reflects progression-derived unlock state
- selecting an unlocked stage loads the correct stage scene
- fortress unlock conditions evaluate correctly

Manual validation:

- navigate the stage select UI with keyboard and gamepad
- attempt to enter locked and unlocked stages
- verify fortress progression unlock timing

Bug watch:

- locked stages shown as selectable
- wrong stage scene loading from a valid selection
- fortress stages unlocking too early or too late

### Phase 11

Scope:

- boss weapons
- weaknesses

Automated checks:

- defeated-boss reward weapon is added to the inventory
- weakness and resistance tables change damage as expected
- weapon energy costs apply correctly for newly added weapons

Manual validation:

- switch between unlocked weapons
- use a boss weapon against normal targets and weakness-enabled targets
- verify HUD weapon energy updates

Bug watch:

- wrong weapon unlock reward
- weakness tables keyed to the wrong IDs
- weapon energy draining or restoring incorrectly

### Phase 12

Scope:

- armor parts
- heart tanks
- sub tanks

Automated checks:

- each persistent upgrade type records correctly in progression
- heart tank and armor upgrades survive save and load
- sub tank ownership and fill state serialize correctly

Manual validation:

- collect one of each upgrade type
- reload the game and confirm ownership and effects remain

Bug watch:

- duplicate collection of persistent upgrades
- upgrade effects applied without persistence or persisted without effects
- sub tank fill values not restoring correctly

### Phase 13

Scope:

- boss encounter framework
- boss UI

Automated checks:

- entering a boss arena activates boss UI and arena lock behavior
- retry resets the boss encounter to its initial state
- boss UI hides cleanly when the encounter ends or resets

Manual validation:

- enter and leave the boss arena through the intended flow
- die during the encounter and retry
- verify boss UI appears only during the encounter

Bug watch:

- arena locks not releasing
- boss UI persisting outside the encounter
- encounter state not resetting cleanly on retry

### Phase 14

Scope:

- first boss fight vertical slice

Automated checks:

- first boss defeat triggers the expected reward and stage-clear flow
- boss phase transitions fire in the intended order
- boss defeat updates progression exactly once

Manual validation:

- play the full first boss fight from encounter start to reward payout
- test death during the fight and a full successful clear

Bug watch:

- boss phase softlocks
- reward payout not triggering or triggering twice
- boss death leaving the arena in an invalid state

### Phase 15

Scope:

- additional boss fights

Automated checks:

- regression suite covers shared boss framework behavior across all implemented bosses
- each added boss reports reward, UI, and reset behavior correctly

Manual validation:

- spot-check each new boss encounter for intro, phase flow, death handling, and reward flow

Bug watch:

- shared boss framework regressions affecting older bosses
- per-boss exceptions bypassing progression or UI cleanup

### Phase 16

Scope:

- full campaign content
- final Sigma flow

Automated checks:

- campaign progression can unlock all required stages in order
- final Sigma flow triggers only when prerequisite progression is complete
- ending flow can be reached from a valid completed campaign state

Manual validation:

- test representative progression paths across Maverick, fortress, and final flow content
- verify endgame transitions and front-end return paths

Bug watch:

- progression dead ends
- campaign unlock order mismatches
- final flow transitions breaking save or return flow

### Phase 17

Scope:

- movement and combat tuning
- placeholder replacement
- bug fixing and optimization

Automated checks:

- full smoke suite passes across boot, stage load, combat, save-load, and one boss encounter
- placeholder asset swaps do not break scene references
- no new runtime errors are introduced by tuning passes

Manual validation:

- run a full feel pass on movement, combat pacing, camera, UI responsiveness, and encounter readability
- verify placeholder replacements preserve collisions, anchors, and hitboxes

Bug watch:

- tuning changes causing regressions in earlier mechanics
- asset swaps breaking offsets, collisions, or references
- late optimization changing gameplay timing or state behavior

## Acceptance Criteria

- player can run, jump, wall jump, dash, shoot, charge, take damage, die, and respawn
- keyboard and gamepad both work through the same action map
- locomotion and combat state machines run in parallel without conflicts
- pickups and capsules apply effects through `PickupReceiver`
- one stage can be run directly from the editor for mid-level testing
- one stage vertical slice is playable from start to boss clear using placeholders only
- boss defeat updates progression and unlocks the proper weapon reward
- save and load restore persistent campaign state correctly
- audio responds to semantic gameplay events
- dialogue and cutscene flow work without embedding story logic into player scripts
- project structure supports one active stage plus layered runtime UI without adding extra autoloads
