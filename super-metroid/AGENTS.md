# AGENTS.md

Guidance for coding agents working in this repository.

## Project Snapshot

This is a Godot 4.6 GDScript project recreating Super Metroid-style 2D platforming. The current main scene is `res://scenes/test_stage.tscn`, with the player implemented as a `CharacterBody2D` plus a state machine under `scripts/player/`.

Consult `SPEC.md` before implementing gameplay behavior. Consult `PHASES.md` for the intended build order and dependency sequence.

## Repository Layout

- `project.godot` - Godot project settings, input actions, renderer, and main scene.
- `scenes/` - playable scenes, currently including `test_stage.tscn`.
- `player/` - player scene, sprites, audio, and generated/imported player assets.
- `scripts/player/` - player controller, state machine, and movement states.
- `scripts/camera/` - camera controller scripts.
- `props/tiles/` - tile art source SVGs, PNG exports, and Godot import metadata.
- `autoloads/` and `data/` - reserved for later singleton and data-driven systems.
- `SPEC.md` - gameplay system specification.
- `PHASES.md` - staged implementation plan.

## Development Conventions

- Use GDScript idioms and keep code compatible with Godot 4.6.
- Prefer the existing state-machine structure for player behavior. Add or alter state scripts rather than stuffing state-specific logic into `player.gd`.
- Use existing input action names from `project.godot` such as `move_left`, `move_right`, `move_up`, `move_down`, `jump`, and `dash`.
- Keep scene/resource paths Godot-style, for example `res://scripts/player/player.gd`.
- Do not hand-edit `.import` files unless the task is specifically about Godot import metadata.
- Keep generated PNGs paired with their SVG source when changing sprite or tile art.
- Avoid broad refactors while gameplay phases are still being built out; small, phase-aligned changes are preferred.

## Validation

Use the Godot executable available on this Windows machine when a change touches scripts, scenes, resources, or project settings:

```powershell
& "d:/Godot_v4.6.2-stable_win64.exe" --path . --headless --quit
```

If Mono/C# validation is needed, use:

```powershell
& "D:/Godot_v4.6.2-stable_mono_win64/Godot_v4.6.2-stable_mono_win64_console.exe" --path . --headless --quit
```

For pure documentation changes, a Godot validation run is optional.

## Editing Notes

- Preserve user changes in the working tree. Do not reset, checkout, or overwrite unrelated files.
- Use focused patches and keep formatting consistent with nearby files.
- Favor tabs for GDScript indentation, matching Godot's default style.
- Keep comments sparse and useful, especially around non-obvious movement or collision behavior.
- When adding new gameplay constants, prefer exported variables on the owning node if designers may tune them in the editor.

## External Tools

Known local tools:

- Inkscape: `C:\Program Files\Inkscape\bin\inkscape.exe`
- ffmpeg: `D:\ffmpeg-8.1-essentials_build\bin\ffmpeg.exe`
- fluidsynth: `D:\fluidsynth-v2.5.4-win10-x64-cpp11\bin\fluidsynth.exe`
- SoundFont: `D:\GeneralUser-GS\GeneralUser-GS.sf2`

Sprites are authored as SVG and exported to PNG. Prefer the existing asset pipeline and file naming when extending art.
