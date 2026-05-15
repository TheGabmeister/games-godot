# AGENTS.md

Guidance for coding agents working in this repository.

## Project Snapshot

This is a Godot 4.6 GDScript project recreating Super Metroid-style 2D platforming. The main scene is `res://scenes/rooms/room_a.tscn`. GameManager (autoload) spawns Player, Camera, and HUD at the scene tree root — rooms are swappable underneath. The player is a `CharacterBody2D` with a state machine under `scripts/player/`.

Consult `SPEC.md` before implementing gameplay behavior. Consult `PHASES.md` for the intended build order and dependency sequence.

## Repository Layout

- `project.godot` - Godot project settings, input actions, renderer, and main scene.
- `scenes/` - playable scenes, projectile scenes, enemy scenes, pickup scenes.
- `scripts/` - all GDScript files, organized by system (player/, combat/, enemies/, pickups/, hud/, camera/, autoloads/).
- `player/` - player scene, sprites, audio, and generated/imported player assets.
- `combat/` - combat asset sprites and audio (projectiles, bombs, VFX).
- `enemies/` - enemy sprites and audio.
- `pickups/` - pickup drop sprites.
- `hud/` - HUD sprites (icons, tank pips).
- `props/tiles/` - tile art source SVGs, PNG exports, and Godot import metadata.
- `SPEC.md` - gameplay system specification.
- `PHASES.md` - staged implementation plan.

## Development Conventions

- Use GDScript idioms and keep code compatible with Godot 4.6.
- Prefer the existing state-machine structure for player behavior. Add or alter state scripts rather than stuffing state-specific logic into `player.gd`.
- Use existing input action names from `project.godot`: `move_left`, `move_right`, `move_up`, `move_down`, `jump`, `dash`, `fire`, `select_weapon`, `cancel_weapon`, `aim_up`, `aim_down`.
- Keep scene/resource paths Godot-style, for example `res://scripts/player/player.gd`.
- Do not hand-edit `.import` files unless the task is specifically about Godot import metadata.
- Keep generated PNGs paired with their SVG source when changing sprite or tile art.
- Avoid broad refactors while gameplay phases are still being built out; small, phase-aligned changes are preferred.
- Capture return values from `connect()` and `erase()` to avoid `RETURN_VALUE_DISCARDED` warnings.
- Use `call_deferred()` for state transitions triggered from physics callbacks (`body_entered`, `area_entered`).

## Validation

```powershell
& "Godot_v4.6.2-stable_win64.exe" --path . --headless --quit
```

For pure documentation changes, a Godot validation run is optional.

## Editing Notes

- Preserve user changes in the working tree. Do not reset, checkout, or overwrite unrelated files.
- Use focused patches and keep formatting consistent with nearby files.
- Favor tabs for GDScript indentation, matching Godot's default style.
- Keep comments sparse and useful, especially around non-obvious movement or collision behavior.
- When adding new gameplay constants, prefer exported variables on the owning node if designers may tune them in the editor.

## External Tools (all on PATH)

| Tool | Command | Notes |
|---|---|---|
| Inkscape | `inkscape` | SVG → PNG export |
| ffmpeg | `ffmpeg` | Audio synthesis and conversion. Run as standalone commands, not chained with `&&`. |
| fluidsynth | `fluidsynth` | MIDI synthesis with `D:\GeneralUser-GS\GeneralUser-GS.sf2` |
| Godot | `Godot_v4.6.2-stable_win64.exe` | On PATH from `D:\Godot\` |

Sprites are authored as SVG and exported to PNG. Prefer the existing asset pipeline and file naming when extending art.
