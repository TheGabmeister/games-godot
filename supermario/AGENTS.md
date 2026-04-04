# AGENTS.md

## Project Overview

This repository is a small Godot 4.6 Super Mario Bros inspired prototype, not a blank starter anymore.

Current state:
- Godot version target: `4.6`
- Rendering feature set: `Forward Plus`
- Physics engine setting: `Jolt Physics` for 3D project settings, while gameplay uses normal 2D physics
- Main scene entry point: `res://scenes/levels/world_1_1.tscn`
- Visual direction: primitive-shape art and procedural drawing instead of sprite sheets
- Core gameplay currently implemented: player movement/state machine, HUD, autoloaded game systems, procedural terrain, parallax background, kill zone

## Repository Layout

- `project.godot`: Main project configuration. It defines the active main scene, autoloads, input actions, collision layer names, and display settings. Prefer editor changes unless a small direct edit is clearly safer.
- `SPEC.md`: Design spec for the broader game. Parts of it are still aspirational or stale, so verify against the files on disk before implementing spec-only structure.
- `scenes/levels/world_1_1.tscn`: Current playable level and real boot scene.
- `scenes/levels/test_level.tscn`: Simple sandbox scene with a flat ground setup.
- `scenes/player/player.tscn`: Player scene with controller, camera, hurtbox, stomp detector, and state machine states as child nodes.
- `scenes/ui/hud.tscn`: In-game HUD scene.
- `scenes/main.tscn`: Present, but not the active boot scene right now.
- `scripts/autoloads/`: Global singletons for events, game state, audio, scene transitions, and camera effects.
- `scripts/player/`: Player controller, primitive-shape drawing, state machine, and per-state scripts.
- `scripts/level/`: Level bootstrap, terrain tileset generation, parallax drawing, and kill-zone behavior.
- `resources/default_bus_layout.tres`: Audio bus layout expected by `AudioManager`.
- `.godot/`: Godot generated editor/import metadata. Do not hand-edit unless there is a very specific reason.
- `.vscode/`: Editor settings.

## Main Flow

- `project.godot` boots `res://scenes/levels/world_1_1.tscn`.
- `scripts/level/level_base.gd` expects a `Player` child and a `TileMapLayer_Ground` child. On `_ready()` it creates the terrain tileset, paints the level floor/stairs, configures the player camera limits, registers the camera with `CameraEffects`, and calls `GameManager.start_new_game()`.
- `scenes/player/player.tscn` expects child nodes named `CollisionShape2D`, `Visuals`, `Visuals/PlayerDrawer`, `StateMachine`, and `Camera2D`. The player is also added to the `"player"` group at runtime.
- `scripts/level/parallax_controller.gd` finds the first node in the `"player"` group and expects that node to have a `Camera2D` child.
- `scripts/ui/hud.gd` reads initial values from `GameManager` and updates through `EventBus` signals.

## Important Gameplay Scripts

- `scripts/level/level_base.gd`: World bootstrap for terrain painting, pits, stairs, and camera bounds.
- `scripts/level/terrain_tileset.gd`: Builds the ground `TileSet` and collision polygons procedurally. Keep this in sync with any terrain tile assumptions in level scripts.
- `scripts/level/parallax_controller.gd`: Draws clouds, hills, and bushes in `_draw()`, driven by camera movement.
- `scripts/level/kill_zone.gd`: Configures collision for the level death plane and calls `die()` when available.
- `scripts/player/player_controller.gd`: Owns physics constants, crouching/collision shape changes, coyote time, jump buffering, gravity, facing, and camera no-backtracking behavior.
- `scripts/player/state_machine.gd`: Routes input, frame, and physics processing to child state nodes by name.
- `scripts/player/player_states/*.gd`: Individual player movement states. Preserve the node names in `player.tscn` if you add or rename states, because transitions use node paths.
- `scripts/player/player_drawer.gd`: Draws small/big/crouching Mario with primitive shapes. Prefer extending this style instead of introducing sprite assets unless the task calls for it.
- `scripts/ui/hud.gd`: Displays score, coins, world, and timer, including the low-time warning color change.

## Autoload Singletons

Configured in `project.godot`:

- `EventBus`: Central signal hub for player, scoring, level, enemy, item, and pause/game-over events.
- `GameManager`: Owns score, coins, lives, timer, world/level numbers, power state, and game state.
- `AudioManager`: Pools audio players and reacts to `EventBus` signals for music and SFX.
- `SceneManager`: Handles fade transitions, scene reloads, and level intro overlay text.
- `CameraEffects`: Stores the active camera reference and provides shake/freeze-frame helpers.

When changing autoload behavior, keep signal contracts and startup expectations compatible with existing HUD, player, and level scripts.

## Input Actions

These actions already exist in `project.godot` and should be preferred over hard-coded keys:

- `move_left`
- `move_right`
- `jump`
- `run`
- `crouch`
- `pause`

## Agent Working Agreement

When making changes in this repo:

1. Prefer small, focused edits that match Godot 4.x and typed GDScript style.
2. Keep scripts simple and beginner-readable unless the task clearly calls for more structure.
3. Do not rename files, move assets, or rewrite project settings without a good reason.
4. Avoid editing generated files such as `.godot/*`, `*.import`, or `*.uid` unless the task specifically requires it.
5. Preserve exact node names and child paths that scripts depend on, especially in `world_1_1.tscn`, `player.tscn`, and `hud.tscn`.
6. Prefer extending the existing primitive/procedural art approach before adding texture or sprite pipelines.
7. If you change `project.godot`, double-check the main scene path, autoload list, input map, and collision layer names afterward.

## GDScript Conventions

- Use `extends` with the correct Godot base class.
- Prefer typed function signatures, for example `func _ready() -> void:`.
- Use `snake_case` for variables and functions.
- Keep `_process` and `_physics_process` only when they are actually needed.
- Add short comments only where logic is not obvious.
- Prefer clear scene/node interactions over overly abstract helper layers in this prototype.

## Godot-Specific Guidance

- Prefer configuring scenes, node hierarchies, signals, and exported properties in Godot-friendly ways.
- Be careful when editing `project.godot`; malformed entries can break project loading.
- If adding assets or scenes, use `res://` paths consistently.
- Keep using Input Map actions instead of hard-coded keys.
- Preserve collision layer intent from `project.godot` when adding new bodies or hitboxes.
- If you change scene structure, update any scripts that use `$NodePath`, `%UniqueName`, `get_node()`, or named state transitions.

## Running The Project

If Godot is available on the machine, common commands are:

- `godot --path .`
- `godot --headless --path . --quit`

If `godot` is not on `PATH`, use the local Godot executable configured on the machine.

## Testing Expectations

There is no automated test suite in the repo right now.

For changes, prefer lightweight validation such as:
- opening the project successfully
- checking for script parse errors
- running the project headless when possible
- verifying the current boot scene is still `res://scenes/levels/world_1_1.tscn` unless the task intentionally changes it

## Notes For Future Agents

- `SPEC.md` is useful for direction, but not every section matches the current repo state yet.
- `scenes/main.tscn` is not the active entry point today even though the spec describes a future shell scene.
- The current level setup is partly code-driven. Terrain visuals, collision, pits, and stairs are created in scripts rather than authored entirely in the editor.
