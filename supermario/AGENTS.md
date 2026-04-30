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
6. Prefer extending the existing primitive/procedural art approach before
   adding texture or sprite pipelines.
7. If you change `project.godot`, double-check the main scene path, autoload
   list, input map, collision layer names, and display settings afterward.
8. Before filling in a missing feature, check whether `SPEC.md` marks it as
   later-phase work. Avoid accidental scope creep.
9. If you touch config wiring, verify both the script and the scene/resource
   assignment. Many behavior changes here come from missing `.tres` assignments
   rather than code alone.

## Implementation Notes

- The active boot scene is `res://scenes/ui/title_screen.tscn`; `scenes/main.tscn`
  is only a shell stub right now.
- `GameManager` owns run state, timers, level entry, respawns, and progression.
  Level scripts should stay focused on scene construction, terrain, and camera
  setup.
- Playable levels use container nodes such as `Blocks`, `Pipes`, `Coins`,
  `Enemies`, `Effects`, and `Interactables`. Interactive gameplay objects should
  generally be scene instances under those containers, not TileMap-authored
  objects.
- `scenes/player/player.tscn` expects child nodes named `CollisionShape2D`,
  `Visuals`, `Visuals/PlayerDrawer`, `StateMachine`, `Camera2D`,
  `StompDetector`, `Hurtbox`, `DamageFlash`, and `MotionTrail`.
- Player state transitions are scene-node-name based. Use
  `scripts/player/player_state_ids.gd` constants instead of scattering raw
  state-name literals.
- Player camera feel lives in `scripts/player/camera_controller.gd`, while
  level scripts still set camera limits.
- `scripts/level/parallax_controller.gd` lazily finds the first node in the
  `"player"` group and expects that node to have a `Camera2D` child.
- Question blocks and brick blocks respond to head hits through
  `player_controller.gd` slide-collision checks. New solid bumpable blocks
  should usually extend `block_base.gd` and expose `bump_from_below()`.
- Hidden blocks are intentionally different: they start with collision disabled
  and use an `Area2D` trigger on the Player layer to detect upward entry before
  enabling collision.
- `_ready()` runs synchronously inside `add_child()` in Godot 4. If a spawned
  item is positioned by its caller, do not snapshot spawn position in `_ready()`;
  use the existing lazy-initialization pattern in `emerge_helper.gd`.
- Effects are procedural and lightweight. Prefer `_draw()`, short-lived helper
  nodes, and EventBus-driven spawning over heavyweight particle scene
  hierarchies.
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

- **Sprites**: each entity/item gets its own SVG and PNG file, exported via
  Inkscape.
  - Inkscape path: `"/c/Program Files/Inkscape/bin/inkscape.exe"`.
  - Export example: `inkscape input.svg --export-type=png --export-filename=output.png -w 64 -h 64`.
- **Sounds**: generate with rfxgen:
  `"D:/rfxgen_v5.0_win_x64/rfxgen.exe" -g coin -o sound.wav`.
- **Music**: Python scripts in `tools/music/` use `midiutil` to generate MIDI,
  FluidSynth to render WAV, and ffmpeg to convert to OGG.
  - FluidSynth: `D:/fluidsynth-v2.5.4-win10-x64-cpp11/bin/fluidsynth.exe`
  - ffmpeg: `D:/ffmpeg-8.1-essentials_build/bin/ffmpeg.exe`
  - Soundfont: `D:/GeneralUser-GS/GeneralUser-GS.sf2`
