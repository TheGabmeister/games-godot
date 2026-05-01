# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

A Godot 4.6 project recreating Chrono Trigger's gameplay systems. The goal is scalable architecture — not a full content recreation. SPEC.md documents the complete game systems as a reference; implementation will be selective.

## Engine & Config

- **Godot 4.6** with GL Compatibility renderer
- **GDScript** is the primary language
- Physics: Jolt Physics (3D, but the game is 2D top-down — may change)
- Rendering: D3D12 on Windows, GL Compatibility on mobile

## Spec Documentation

The game design spec is split across four files:

- **SPEC.md** — master spec: systems, characters, story, items, equipment, economy, engine/presentation systems, progression flags (~970 lines)
- **docs/techs.md** — all Single/Dual/Triple Tech tables with TP thresholds, MP costs, elements, targeting
- **docs/bestiary.md** — enemy stat tables (HP, EXP, G, TP, weakness, drop, charm) + regular enemy behavior patterns
- **docs/boss-ai.md** — per-boss AI: attack lists, phase transitions, counter triggers, kill orders, ATB speed values

When implementing a system, read the relevant SPEC.md section first, then the companion docs/ file for data tables. SPEC.md §11 lists open questions where numbers still need ROM-data verification.

## Architecture Notes (planned, not yet built)

The project is in early setup — only a placeholder script exists. The spec describes these key systems that will drive architecture:

- **ATB Battle System** — real-time gauges, no separate battle screen, AoE shapes tied to field positions (§2.1)
- **Tech System** — Single/Dual/Triple with prerequisite chains and Rock accessories (§2.2, docs/techs.md)
- **Event Scripting** — cutscenes are real-time in-engine with a command vocabulary: movement, animation, dialogue, screen effects, branching (§10.2)
- **Game State** — single-byte storyline counter + supplementary bit flags gate everything: NPC dialogue, area access, shop inventory, sealed chests (§10.9)
- **Scene Structure** — ~500 rooms across 5 overworld maps, seamless field-to-battle transitions (§10.10)
- **Inventory** — shared pool, 99-stack consumables, key items separate, equipment accessible for benched characters (§10.4)

## Conventions

- SNES-original names used throughout the spec (not DS retranslations)
- v1 scope is SNES content only; DS-port additions (Lost Sanctum, Dimensional Vortex, Magus dual/triple techs) are stretch goals

- **Godot game programming best practices**
- **KISS** — simplest thing that works.
- **YAGNI** — don't build for hypothetical needs. No abstraction layers "for later."
- **DRY** — remove real duplication, not shape-similar code. Wrong abstraction costs more than repetition.
- **Locality of change** — adding a new entity, tile, or feature should require changes in as few files as possible.

When in doubt: for code one person owns and rarely changes, lean KISS. For interfaces many contributors touch, lean locality of change.

## Asset Pipeline

- **Sprites**: each entity/item gets its own SVG and PNG file, exported via Inkscape.
  - Inkscape path: `"/c/Program Files/Inkscape/bin/inkscape.exe"`. Export: `inkscape input.svg --export-type=png --export-filename=output.png -w 64 -h 64`.
- **Sounds**: generate with rfxgen (`"D:/rfxgen_v5.0_win_x64/rfxgen.exe" -g coin -o sound.wav`).
- **Music**: Python scripts in `tools/music/` use `midiutil` to generate MIDI -> FluidSynth renders with a soundfont to WAV -> ffmpeg converts to OGG. Tool paths: `D:/fluidsynth-v2.5.4-win10-x64-cpp11/bin/fluidsynth.exe`, `D:/ffmpeg-8.1-essentials_build/bin/ffmpeg.exe`, soundfont `D:/GeneralUser-GS/GeneralUser-GS.sf2`.
