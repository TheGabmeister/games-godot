# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Final Fantasy I Pixel Remaster systems recreation in Godot 4.6. The goal is to build scalable gameplay systems (combat, magic, equipment, progression, world traversal) with enough content to validate each system — not a full game recreation. See SPEC.md for the gameplay systems spec and PHASES.md for the 14-phase implementation plan.

## Engine & Tools

- **Godot 4.6.2** (Forward Plus rendering, D3D12 driver)
- Run Godot CLI: `Godot_v4.6.2-stable_win64.exe` (on PATH — do not use the full path)
- **Inkscape** for sprite pipeline: create SVG source → export to PNG via `inkscape input.svg --export-type=png --export-filename=output.png -w <width> -h <height>`
- **ffmpeg:** `D:\Tools\ffmpeg-8.1-essentials_build\bin\ffmpeg.exe`
- **fluidsynth:** `D:\Tools\fluidsynth-v2.5.4-win10-x64-cpp11\bin\fluidsynth.exe`
- **Blender:** `"C:\Program Files\Blender Foundation\Blender 5.1\blender.exe"`

If `where <tool>` fails in the Bash shell, use the full paths above — shell sessions may not inherit the latest user PATH.

## Running the Project

```bash
# Run the game
Godot_v4.6.2-stable_win64.exe --path . --run

# Run a specific scene
Godot_v4.6.2-stable_win64.exe --path . --run res://path/to/scene.tscn

# Export (headless)
Godot_v4.6.2-stable_win64.exe --path . --headless --export-release "Windows Desktop"
```

## Design Documents

- **SPEC.md** — Complete gameplay systems spec (combat formulas, classes, spells, equipment, enemies, world structure). Companion data tables in `docs/ff1/` (weapons.md, armor.md, spells.md, bestiary.md).
- **PHASES.md** — 14-phase implementation plan. Systems-focused, one system per phase, with dependency tracking and debug levels for testing.

When implementing a phase, read both SPEC.md and PHASES.md. The spec has the formulas and numbers; the phases have the build order and scope boundaries.

## Resolution

- **Base viewport:** 1280x720 (stretch mode `viewport`, aspect `keep`)
- **Tile size:** 64x64 px (20x11 visible tile grid)
- **Character sprites:** 64x96 px (1 tile wide, 1.5 tiles tall)

## Sprite Pipeline

Sprites are SVG source files exported to PNG. Always create the SVG first, then export:

```bash
# Tile export (64x64)
inkscape tile.svg --export-type=png --export-filename=tile.png -w 64 -h 64

# Character export (64x96)
inkscape character.svg --export-type=png --export-filename=character.png -w 64 -h 96
```

Keep SVG sources alongside exported PNGs so sprites can be re-exported at different resolutions.
