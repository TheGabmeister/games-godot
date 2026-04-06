# AGENTS.md

## Project Overview

This repository is a Godot 4.6 Super Mario Bros inspired prototype. It is no
longer a blank starter and is currently mid-implementation against `SPEC.md`.

Current state:
- Godot version target: `4.6`
- Rendering feature set: `Forward Plus`
- Physics engine setting: `Jolt Physics` for 3D project settings, while gameplay
  uses normal 2D physics
- Main scene entry point: `res://scenes/levels/world_1_1.tscn`
- Visual direction: primitive-shape art and procedural drawing instead of sprite
  sheets or textures
- Core gameplay currently implemented: player movement/state machine, HUD,
  autoloaded game systems, procedural terrain, parallax background, kill zone,
  question blocks, brick blocks, hidden blocks, coins, mushrooms, fire
  flowers, Goombas, Koopas, Koopa shells, stomp/contact damage, and enemy
  activation cleanup
- Phase 6 infrastructure is now present on disk: tunables migrated into
  `Resource` files under `resources/config/`, plus procedural effects for
  damage flash, score popups, motion trails, brick particles, stomp puffs,
  coin pop, and the power-up ring

## Repository Layout

- `project.godot`: Main project configuration. It defines the active main
  scene, autoloads, input actions, collision layer names, and display settings.
  Prefer editor changes unless a small direct edit is clearly safer.
- `SPEC.md`: Design spec for the broader game. It is the design authority, but
  some sections are still aspirational or deferred. Verify against files on
  disk and the phase notes before treating a missing feature as a bug.
- `CLAUDE.md`: Another agent guide with repo-specific implementation notes.
- `scenes/levels/world_1_1.tscn`: Current playable level and real boot scene.
  This scene now includes background, procedural terrain, placed blocks, placed
  coins, enemies, an `Effects` node, a kill zone, and the player/HUD.
- `scenes/levels/test_level.tscn`: Sandbox level scene.
- `scenes/player/player.tscn`: Player scene with controller, camera, stomp
  detector, hurtbox, damage flash, motion trail, and state machine states as
  child nodes.
- `scenes/ui/hud.tscn`: In-game HUD scene.
- `scenes/objects/`: Interactive object scenes such as question blocks, brick
  blocks, hidden blocks, coins, mushrooms, and fire flowers.
- `scenes/enemies/`: Enemy scenes for Goomba, Koopa, and Koopa shell.
- `scenes/effects/`: Reserved for effect scenes if any are added later, though
  the current repo mostly instantiates effect scripts directly under the level
  `Effects` node.
- `scenes/main.tscn`: Present, but not the active boot scene right now.
- `scripts/autoloads/`: Global singletons for events, game state, audio, scene
  transitions, and camera effects.
- `scripts/config/`: `Resource` subclasses for inspector-editable gameplay and
  polish tunables.
- `resources/config/`: Canonical `.tres` instances consumed by scenes and
  scripts.
- `scripts/effects/`: Procedural effect scripts such as score popups, damage
  flash, motion trails, brick particles, stomp puffs, coin pop, and the
  power-up ring.
- `scripts/player/`: Player controller, primitive-shape drawing, state machine,
  and per-state scripts.
- `scripts/level/`: Level bootstrap, terrain tileset generation, parallax
  drawing, and kill-zone behavior.
- `scripts/enemies/`: Enemy base logic, per-enemy behavior, shell logic, and
  enemy procedural drawing.
- `scripts/objects/`: Interactive blocks and collectible/power-up behavior.
- `scripts/color_palette.gd`: Shared named color constants used throughout the
  procedural visuals.
- `shaders/`: Shader assets, currently including the sky/background gradient.
- `resources/default_bus_layout.tres`: Audio bus layout expected by
  `AudioManager`.
- `.godot/`: Godot generated editor/import metadata. Do not hand-edit unless
  there is a very specific reason.
- `.vscode/`: Editor settings.

## Main Flow

- `project.godot` boots `res://scenes/levels/world_1_1.tscn`.
- `scripts/level/level_base.gd` expects a `Player` child and a
  `TileMapLayer_Ground` child. On `_ready()` it creates the terrain tileset,
  paints the level floor/stairs, configures the player camera limits, registers
  the camera with `CameraEffects`, and calls `GameManager.start_new_game()`.
- `world_1_1.tscn` uses container nodes like `Blocks`, `Pipes`, `Coins`,
  `Enemies`, `Effects`, and `Interactables`. Interactive objects are scene
  instances under these containers rather than TileMap-authored gameplay
  objects.
- The `Enemies` node in `world_1_1.tscn` is scripted by
  `scripts/level/enemy_spawner.gd`, which activates enemies near the camera and
  cleans up enemies far behind it.
- The `Effects` node in `world_1_1.tscn` is scripted by
  `scripts/effects/effects_manager.gd`, which listens to `EventBus` and spawns
  procedural visual effects for score, block breaks, stomps, and coin pops.
- `scenes/player/player.tscn` expects child nodes named `CollisionShape2D`,
  `Visuals`, `Visuals/PlayerDrawer`, `StateMachine`, `Camera2D`,
  `StompDetector`, `Hurtbox`, `DamageFlash`, and `MotionTrail`. The player is
  also added to the `"player"` group at runtime.
- `StateMachine` transitions by child node name. Current state nodes include
  `IdleState`, `RunState`, `JumpState`, `FallState`, `CrouchState`,
  `DeathState`, `GrowState`, and `ShrinkState`.
- `scripts/level/parallax_controller.gd` finds the first node in the `"player"`
  group and expects that node to have a `Camera2D` child. It resolves that
  lazily in `_process()`, not `_ready()`.
- `scripts/ui/hud.gd` reads initial values from `GameManager` and updates
  through `EventBus` signals.

## Important Gameplay Scripts

- `scripts/level/level_base.gd`: World bootstrap for terrain painting, pits,
  stairs, and camera bounds.
- `scripts/level/terrain_tileset.gd`: Builds the ground `TileSet` and collision
  polygons procedurally. Keep this in sync with any terrain tile assumptions in
  level scripts.
- `scripts/level/parallax_controller.gd`: Draws clouds, hills, and bushes in
  `_draw()`, driven by camera movement.
- `scripts/level/enemy_spawner.gd`: Enemy activation and cleanup gate tied to
  the current camera bounds.
- `scripts/level/kill_zone.gd`: Configures collision for the level death plane
  and calls `die()` when available.
- `scripts/player/player_controller.gd`: Owns movement config references,
  crouching and collision shape changes, coyote time, jump buffering, damage,
  stomp logic, camera no-backtracking behavior, `check_ceiling_bumps()`, and
  `power_up()`.
- `scripts/player/state_machine.gd`: Routes input, frame, and physics
  processing to child state nodes by name.
- `scripts/player/player_states/*.gd`: Individual player movement states.
  Preserve the node names in `player.tscn` if you add or rename states, because
  transitions use node paths.
- `scripts/player/player_states/grow_state.gd` and
  `scripts/player/player_states/shrink_state.gd`: Power transition animation
  states. Be careful about momentum restoration, collision-shape timing, and
  gameplay pause expectations if you touch them.
- `scripts/player/player_drawer.gd`: Draws small, big, and crouching Mario with
  primitive shapes. Prefer extending this style instead of introducing sprite
  assets unless the task calls for it.
- `scripts/enemies/enemy_base.gd`: Shared enemy movement, death handling, and
  per-enemy config usage.
- `scripts/enemies/goomba.gd`: Goomba stomp/squish logic.
- `scripts/enemies/koopa.gd`: Koopa behavior and shell spawning.
- `scripts/enemies/koopa_shell.gd`: Idle vs moving shell behavior, kick logic,
  shell combo kills, and shell danger checks.
- `scripts/objects/question_block.gd`: Bumpable `?` block that can spawn coins,
  mushrooms, or fire flowers.
- `scripts/objects/brick_block.gd`: Breakable or bumpable brick block, with
  multi-coin support.
- `scripts/objects/hidden_block.gd`: Hidden block that reveals itself with a
  trigger-area pattern instead of standard slide-collision bump detection.
- `scripts/objects/mushroom.gd`: Moving mushroom pickup with emerge animation.
- `scripts/objects/fire_flower.gd`: Stationary fire flower pickup with emerge
  animation.
- `scripts/objects/coin.gd`: Collectible area-based coin with procedural spin.
- `scripts/effects/effects_manager.gd`: Event-driven effect spawning hub for
  score popups, brick particles, stomp puffs, and coin pops.
- `scripts/effects/damage_flash.gd`: Player hit-flash helper attached under the
  player scene.
- `scripts/effects/motion_trail.gd`: Top-speed run trail attached under the
  player scene.
- `scripts/ui/hud.gd`: Displays score, coins, world, and timer, including the
  low-time warning color change.

## Autoload Singletons

Configured in `project.godot`:

- `EventBus`: Central signal hub for player, scoring, level, enemy, item, and
  pause/game-over events.
- `GameManager`: Owns score, coins, lives, timer, world/level numbers, power
  state, and game state.
- `AudioManager`: Audio skeleton with pooled SFX players, pooled 2D SFX
  players, and dual music players for crossfades. Registries are present but
  most paths are still empty.
- `SceneManager`: Handles fade transitions, scene reloads, and level intro
  overlay text.
- `CameraEffects`: Stores the active camera reference and provides shake and
  freeze-frame helpers.

When changing autoload behavior, keep signal contracts and startup expectations
compatible with existing HUD, player, block, item, and level scripts.

## Config Resources

Phase 6 introduced `Resource`-driven tunables. Current config scripts live in
`scripts/config/` and canonical `.tres` instances live in `resources/config/`.

Current categories on disk:
- `player_movement_config.gd` / `player_movement_default.tres`
- `camera_config.gd` / `camera_default.tres`
- `enemy_config.gd` / `goomba_config.tres` and `koopa_config.tres`
- `block_bump_config.gd` / `block_bump_default.tres`
- `item_config.gd` / `item_default.tres`
- `level_timing_config.gd` / `level_timing_default.tres`
- `effects_config.gd` / `effects_default.tres`

When adding new tunables:
- Prefer extending an existing config category before inventing a new pattern.
- Keep one canonical shared `.tres` under `resources/config/` unless there is a
  real need for variants.
- Preserve the project rule of avoiding `class_name`; use `extends Resource`
  plus `preload("res://...")` paths instead.

## Current Gameplay Contracts

- `GameManager.PowerState` currently includes `SMALL`, `BIG`, and `FIRE`.
- `GameManager.GameState` currently includes `TITLE`, `PLAYING`, `PAUSED`,
  `GAME_OVER`, `LEVEL_COMPLETE`, and `TRANSITIONING`.
- `EventBus` already exposes signals for block bumps/breaks, item spawning,
  power-state changes, enemy stomps/kills, combo stomps, one-ups, level state,
  and game-over flow. Prefer using those signals instead of direct cross-system
  calls.
- Character movement physics collide only with terrain by default. Most
  gameplay overlaps use `Area2D` on the named layers in `project.godot`.
- Score popups and several polish effects are event-driven. If you add a new
  scoring or break/impact event, check whether it should also emit an
  `EventBus` signal so the effects layer can react without direct scene wiring.

## Input Actions

These actions already exist in `project.godot` and should be preferred over
hard-coded keys:

- `move_left`
- `move_right`
- `jump`
- `run`
- `crouch`
- `pause`

## Collision Layers

These 2D physics layers are named in `project.godot`:

- `Terrain`
- `Player`
- `Enemies`
- `PlayerHitbox`
- `EnemyHitbox`
- `Items`
- `Fireballs`
- `KoopaShell`
- `KillZone`
- `Interactable`

Preserve the intent of these layers when adding new bodies, hitboxes, or item
areas.

## Agent Working Agreement

When making changes in this repo:

1. Prefer small, focused edits that match Godot 4.x and typed GDScript style.
2. Keep scripts simple and beginner-readable unless the task clearly calls for
   more structure.
3. Do not rename files, move assets, or rewrite project settings without a good
   reason.
4. Avoid editing generated files such as `.godot/*`, `*.import`, or `*.uid`
   unless the task specifically requires it.
5. Preserve exact node names and child paths that scripts depend on, especially
   in `world_1_1.tscn`, `player.tscn`, `hud.tscn`, the enemy scenes under
   `scenes/enemies/`, and the object scenes under `scenes/objects/`.
6. Prefer extending the existing primitive/procedural art approach before
   adding texture or sprite pipelines.
7. If you change `project.godot`, double-check the main scene path, autoload
   list, input map, and collision layer names afterward.
8. Before "filling in" something missing, check whether `SPEC.md` marks it as a
   later-phase feature. Avoid accidental scope creep.
9. If you touch Phase 6 config wiring, verify both the script and the scene or
   resource assignment. In this repo, many behavior changes come from missing
   `.tres` assignments rather than from code alone.

## GDScript Conventions

- Use `extends` with the correct Godot base class.
- Prefer typed function signatures, for example `func _ready() -> void:`.
- Use `snake_case` for variables and functions.
- Keep `_process` and `_physics_process` only when they are actually needed.
- Add short comments only where logic is not obvious.
- Prefer clear scene/node interactions over overly abstract helper layers in
  this prototype.
- Do not introduce `class_name` declarations. This project avoids them because
  headless validation can miss newly indexed classes.
- Prefer `preload("res://...")` for script or scene references.

## Godot-Specific Guidance

- Prefer configuring scenes, node hierarchies, signals, and exported
  properties in Godot-friendly ways.
- Be careful when editing `project.godot`; malformed entries can break project
  loading.
- If adding assets or scenes, use `res://` paths consistently.
- Keep using Input Map actions instead of hard-coded keys.
- Preserve collision layer intent from `project.godot` when adding new bodies
  or hitboxes.
- If you change scene structure, update any scripts that use `$NodePath`,
  `%UniqueName`, `get_node()`, or named state transitions.
- `_ready()` runs synchronously inside `add_child()` in Godot 4. If an item is
  spawned and then positioned by the caller, do not snapshot spawn position in
  `_ready()`. Use the existing lazy-initialization pattern from
  `mushroom.gd` and `fire_flower.gd`.
- Question blocks and brick blocks respond to head hits through
  `player_controller.gd`'s `check_ceiling_bumps()` slide-collision iteration.
  New bumpable solid blocks should expose a `bump_from_below()` method.
- Hidden blocks are different: because they start with collision disabled, they
  use an `Area2D` trigger on the Player layer to detect upward entry, then
  enable their `StaticBody2D` collision. Reuse that pattern for toggleable
  collision blocks instead of forcing them through slide-collision bump logic.
- Effects are intentionally procedural and lightweight. Prefer `_draw()`,
  short-lived helper nodes, and `EventBus`-driven spawning over heavyweight
  particle scene hierarchies unless the task clearly needs them.

## Running The Project

If Godot is available on the machine, common commands are:

- `godot --path .`
- `godot --headless --path . --quit`

If `godot` is not on `PATH`, use the local executable configured on this
machine, currently `d:\Godot_v4.6.2-stable_win64.exe`.

## Testing Expectations

There is no automated test suite in the repo right now.

For changes, prefer lightweight validation such as:
- opening the project successfully
- checking for script parse errors
- running the project headless when possible
- verifying the current boot scene is still `res://scenes/levels/world_1_1.tscn`
  unless the task intentionally changes it
- manually checking the affected gameplay flow in the running game for changes
  to player movement, block bumps, item spawning, or HUD updates

Known quirk:
- `godot --headless --path . --quit` can exit before indexing new `class_name`
  scripts. This repo avoids `class_name` and uses explicit `preload()` paths
  instead.
- On this machine, headless validation may also crash after failing to open a
  `user://logs/...` file. If that reproduces, note it clearly and fall back to
  project-open/manual validation rather than assuming the project itself is the
  cause.

## Notes For Future Agents

- `SPEC.md` is useful for direction, but not every section matches the current
  repo state yet.
- `scenes/main.tscn` is not the active entry point today even though the spec
  describes a future shell scene.
- The level setup is partly code-driven. Terrain visuals, collision, pits, and
  stairs are created in scripts rather than authored entirely in the editor.
- Most visuals are intentionally drawn with `_draw()`, primitive shapes, color
  constants, and a small amount of shader work. Preserve that style.
- Phase 6 moved many tunables into config resources, but some behavior may still
  be split across scene assignments, preloaded resources, and scripts. When
  adjusting feel or polish, search both `scripts/config/` and scene/resource
  assignments before concluding a value is unused.
