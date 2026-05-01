# AGENTS.md

## Purpose

This file is the agent working agreement for the Godot Super Mario prototype.
`README.md` owns the general project overview, running commands, repository
layout, architecture, input map, collision layers, visual style, tunables, and
baseline GDScript conventions. Read it first and avoid re-adding that material
here.

Use `SPEC.md` for product direction, but verify against files on disk before
treating missing behavior as a bug. Some spec sections are aspirational or
deferred. `CLAUDE.md` is useful additional context, but this file is the
agent-facing source of truth when guidance overlaps.

## Coding Principles

- **Godot game programming best practices**
- **KISS** - simplest thing that works.
- **YAGNI** - do not build for hypothetical needs. No abstraction layers "for later."
- **DRY** - remove real duplication, not shape-similar code. Wrong abstraction costs more than repetition.
- **Locality of change** - adding a new entity, tile, or feature should require changes in as few files as possible.

When in doubt: for code one person owns and rarely changes, lean KISS. For
interfaces many contributors touch, lean locality of change.

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
   in `world_1_1.tscn`, `world_1_2.tscn`, `player.tscn`, `hud.tscn`, enemy
   scenes, and object scenes.
6. Visual gameplay art is sprite-sheet based. Prefer scene-authored
   `AnimatedSprite2D` nodes with assigned `SpriteFrames` resources over
   runtime-created sprites, `_draw()` art, or ad hoc region helpers.
7. If you change `project.godot`, double-check the main scene path, autoload
   list, input map, collision layer names, and display settings afterward.
8. Before filling in a missing feature, check whether `SPEC.md` marks it as
   later-phase work. Avoid accidental scope creep.
9. If you touch config wiring, verify both the script and the scene/resource
   assignment. Many behavior changes here come from missing `.tres` assignments
   rather than code alone.
10. If you change tile size or visual scale, update the TileSet builder, level
	`TILE_SIZE` constants, authored scene positions, gameplay config resources,
	and dependent object offsets together. The current grid is 32 px tiles.

## Implementation Notes

- The active boot scene is `res://scenes/ui/title_screen.tscn`; `scenes/main.tscn`
  is only a shell stub right now.
- `GameManager` owns persistent run state, level config lookup, level entry,
  respawns, progression, score, coins, lives, power state, and music start
  requests. It stores `time_remaining` and `timer_active`, but does not tick the
  timer and does not reference the player.
- Game-wide level order/config lives in `resources/config/game_config.tres` as
  an ordered array of `LevelConfig` resources. Each `LevelConfig` owns the
  level display name, scene, time limit, and music.
- Playable level roots should use `scripts/level/gameplay_manager.gd` as the
  scene script, expose `player_scene`, and contain a `PlayerStart` `Marker2D`.
  `GameplayManager` spawns the player, drives the countdown timer, emits
  `time_tick`, kills the player on timeout, and mediates player death signals
  before calling `GameManager.lose_life()`.
- `SfxManager` and `MusicManager` are playback plumbing only. Gameplay, UI, and
  level callers own their `AudioStream` references and request playback through
  EventBus (`sfx_requested`, `music_requested`, `music_stop_requested`, and
  `music_duck_requested`). Do not add centralized SFX/music registries back to
  the managers.
- `UIManager` autoload owns persistent pause, game-over, and level-complete UI
  overlays. Do not place those overlay scenes directly in level scenes.
- Playable levels use container nodes such as `Blocks`, `Pipes`, `Coins`,
  `Enemies`, `Effects`, and `Interactables`. Interactive gameplay objects should
  generally be scene instances under those containers, not TileMap-authored
  objects.
- `scenes/player/player.tscn` expects child nodes named `CollisionShape2D`,
  `Visuals`, `Visuals/Sprite`, `StateMachine`, `Camera2D`,
  `StompDetector`, `Hurtbox`, `DamageFlash`, and `MotionTrail`. Motion trail
  sprites are authored as children of `MotionTrail`.
- Player state transitions are scene-node-name based. Use
  `scripts/player/player_state_ids.gd` constants instead of scattering raw
  state-name literals.
- Player death is signal-driven. `player_controller.gd` emits `died` when death
  starts, and `DeathState` emits `death_animation_finished` when the bounce
  animation ends. `GameplayManager` listens to those signals; the player should
  not call `GameManager.lose_life()` directly.
- Player camera feel lives in `scripts/player/camera_controller.gd`, while
  camera bounds are auto-detected from the first `TileMapLayer` in the level.
- Level terrain is hand-painted in level `.tscn` files using `TileMapLayer` and
  `resources/tilesets/terrain_tileset.tres`. `tools/tileset_builder_reference.gd`
  is reference material for how the TileSet was built, not runtime level
  construction code.
- Question blocks and brick blocks respond to head hits through
  `player_controller.gd` slide-collision checks. New solid bumpable blocks
  should usually extend `block_base.gd` and expose `bump_from_below()`.
- Hidden blocks are intentionally different: they start with collision disabled
  and use an `Area2D` trigger on the Player layer to detect upward entry before
  enabling collision.
- `_ready()` runs synchronously inside `add_child()` in Godot 4. If a spawned
  item is positioned by its caller, do not snapshot spawn position in `_ready()`;
  use the existing lazy-initialization pattern in `emerge_helper.gd`.
- Pickup root types intentionally follow behavior. Moving pickups such as
  mushrooms, 1-ups, and starmen are `CharacterBody2D` nodes so scripted motion
  can use `move_and_slide()`, terrain collision, `is_on_floor()`, and
  `is_on_wall()`. Simple overlap pickups such as coins and fire flowers can
  stay as `Area2D` nodes. Do not force all pickups into one root node type just
  to share code.
- Shared pickup collection state and one-shot collect sound playback live in
  `scripts/pickups/pickup_helper.gd`. Concrete pickup scripts should keep their
  reward behavior local (coin count, power-up, 1-up, star power) and call the
  helper before applying the reward.
- Pickup scene resources should remain scene-swappable when useful. For
  example, `collect_sound` belongs on the pickup scene when designers may swap
  the sound, while movement tuning comes from `item_config`.
- Effects are lightweight `.tscn` scenes under `scenes/effects/`, spawned via
  `effects_manager._spawn_effect`. Their visual children should be
  scene-authored `AnimatedSprite2D` nodes with `SpriteFrames` assigned in the
  scene, not created at runtime.
- Sprite animation resources live under `resources/sprite_frames/`. Runtime
  gameplay scripts should generally call `play()` or set `animation`; do not
  rebuild `SpriteFrames`, create `AtlasTexture`s, or add a shared runtime
  sprite-frame builder back into `scripts/`.
- When changing autoload behavior, keep signal contracts and startup
  expectations compatible with existing HUD, player, block, item, and level
  scripts.
- Do not introduce `class_name` declarations. This repo relies on explicit
  `preload("res://...")` paths because headless validation can miss newly
  indexed classes.

## Validation Notes

Use the commands and baseline expectations in `README.md`. For agent changes,
prefer lightweight validation: open the project or run it headless when
possible, check for script parse/load errors, and manually verify affected
gameplay flows when behavior changes.

On this machine, headless validation may also crash after failing to open a
`user://logs/...` file. If that reproduces, note it clearly and fall back to
project-open or manual validation rather than assuming the project itself is at
fault.

## Asset Pipeline

- **Sprites**: generated from the Python + Inkscape pipeline in
  `tools/sprites/`.
  - SVG source sheets live under `tools/sprites/svg/`; `tools/.gdignore` keeps
	them out of Godot's imported project assets.
  - Runtime PNG sheets live directly under `res://sprites/`.
  - Godot `SpriteFrames` resources live under `res://resources/sprite_frames/`
    and are assigned directly to scene-authored `AnimatedSprite2D` nodes.
  - Each sprite sheet cell is 32 x 32 px.
  - Generate PNG sheets with
    `C:/Users/Admin/AppData/Local/Python/pythoncore-3.14-64/python.exe tools/sprites/generate_sprites.py`.
  - Generate `SpriteFrames` resources with
    `C:/Users/Admin/AppData/Local/Python/pythoncore-3.14-64/python.exe tools/sprites/generate_sprite_frames.py`.
  - Inkscape path: `"C:/Program Files/Inkscape/bin/inkscape.exe"`.
- **Sounds**: generate with rfxgen:
  `"D:/rfxgen_v5.0_win_x64/rfxgen.exe" -g coin -o sound.wav`.
- **Music**: Python scripts in `tools/music/` use `midiutil` to generate MIDI,
  FluidSynth to render WAV, and ffmpeg to convert to OGG.
  - Python: `C:/Users/Admin/AppData/Local/Python/pythoncore-3.14-64/python.exe`
  - FluidSynth: `D:/fluidsynth-v2.5.4-win10-x64-cpp11/bin/fluidsynth.exe`
  - ffmpeg: `D:/ffmpeg-8.1-essentials_build/bin/ffmpeg.exe`
  - Soundfont: `D:/GeneralUser-GS/GeneralUser-GS.sf2`
