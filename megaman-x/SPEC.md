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

### Weapon switching

Use a dedicated `WeaponInventory` node under `PlayerCombat`.

Rules:

- the weapon order is explicit
- `buster` starts unlocked
- unlocked boss weapons are added through progression
- cycling should skip locked weapons

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

### Damage modifiers and weaknesses

Use data-driven damage modifiers for bosses and, when useful, for enemies.

Rules:

- default damage comes from weapon data unless an enemy or boss overrides it
- weakness and resistance tables should be keyed by stable weapon IDs
- weapon weakness logic should live on the target side or shared combat data, not inside player movement scripts

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

### Checkpoints and hazards

Checkpoints are stage-local retry anchors.

Checkpoint rules:

- checkpoints use stable stage-local IDs
- `StageController` owns the active checkpoint for the current run
- checkpoints are not permanent campaign progression facts and should not be stored in the save file

Hazard rules:

- hazards may either apply standard damage or cause an instant death or fall reset depending on the hazard type
- hazards should use shared systems where possible instead of bespoke per-stage logic
- out-of-bounds or pit recovery should route through `StageController`

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

## Placeholder Asset Rules

- use stable placeholder names
- keep collision and hitboxes separate from visuals
- drive visuals from semantic states such as `idle`, `run`, `dash`, `hurt`, `charge_small`, and `charge_full`
- keep character, enemy, projectile, UI, and stage placeholder conventions consistent

## Milestones

### Phase 1

- project structure
- player movement
- player combat
- shared health, damage, and collision
- one enemy family
- boss skeleton
- audio manager
- HUD shell
- one test stage
- standalone stage testing

### Phase 2

- one full vertical slice
- hazards
- checkpoints
- one boss fight
- stage clear flow
- dash unlock flow
- stage-local cutscene
- dialogue flow

### Phase 3

- stage select
- boss weapons
- weaknesses
- armor parts
- heart tanks
- sub tanks
- save and load
- multiple stages
- fortress unlock flow

### Phase 4

- full campaign content
- final Sigma flow
- movement and combat tuning
- placeholder replacement
- bug fixing and optimization

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
