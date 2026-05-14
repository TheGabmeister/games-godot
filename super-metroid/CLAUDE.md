# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Super Metroid recreation in Godot 4.6 (GDScript). 2D Metroidvania platformer. Currently in pre-implementation — SPEC.md defines all gameplay systems, PHASES.md defines the build order.

## Engine & Runtime

- **Godot 4.6**, Forward Plus renderer, D3D12 driver (Windows)
- **Language:** GDScript
- **Physics:** Jolt Physics (configured but project is 2D — will use Godot's built-in 2D physics)

## External Tools

| Tool | Path |
|---|---|
| Inkscape | `C:\Program Files\Inkscape\bin\inkscape.exe` |
| ffmpeg | `D:\ffmpeg-8.1-essentials_build\bin\ffmpeg.exe` |
| fluidsynth | `D:\fluidsynth-v2.5.4-win10-x64-cpp11\bin\fluidsynth.exe` |
| Soundfont | `D:\GeneralUser-GS\GeneralUser-GS.sf2` |

Sprites are authored as SVG in Inkscape and exported to PNG via the Inkscape CLI.

## Key Documents

- **SPEC.md** — Complete gameplay systems spec: movement, combat, beams, bosses, items, enemies, HUD, world structure. All damage values, HP pools, and frame data are here. Consult before implementing any mechanic.
- **PHASES.md** — 8-phase build plan in dependency order. Phase 1 (movement) through Phase 8 (prologue, menus, content completion). Follow this order.

## Project Structure

```
autoloads/    # Singleton scripts (game state, resource managers)
player/       # Samus character scripts and scenes
data/         # Game data (item definitions, enemy stats, room data)
```

Directories exist but are empty — implementation hasn't started.
