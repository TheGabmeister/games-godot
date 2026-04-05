# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Godot 4.6 recreation of Zelda: A Link to the Past mechanics using primitive shapes (no sprites). GDScript only. The game is 2D at 256×224 logical resolution on a 16×16 tile grid, rendered with Forward Plus.

## Key Files

- **SPEC.md** — primary source of truth. Read the relevant section before making changes.
- **AGENTS.md** — architecture guardrails and non-negotiable rules.
- **project.godot** — engine configuration (4.6, Forward Plus, d3d12).

## Running the Project

```bash
# Godot executable (aliased as `godot` in bash)
godot                           # Open editor
godot --path . --scene res://scenes/main/main.tscn  # Run main scene
godot --path . --headless --quit  # Headless smoke check

# GUT unit tests (after GUT is installed in Phase 2)
godot --path . --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests/unit -gexit
```

Editor path: `d:\Godot_v4.6.2-stable_win64.exe`

## Testing

Every subphase in SPEC.md has a **Verification** block with concrete checks. A subphase is not done until its Verification passes — the end-of-phase deliverable is not the only gate.

Three verification types:
1. **Unit tests** — GUT framework (`res://tests/unit/`) for pure logic: damage formula, inventory operations, loot tables, save serialization.
2. **Debug scene checks** — load `debug/debug_room.tscn` or a dedicated `tests/scenes/*.tscn` and verify behavior manually against the Verification checklist.
3. **Headless smoke checks** — `godot --path . --headless --quit` after any change.

## Architecture

The project follows a phase-based implementation plan (see SPEC.md). Each phase produces a playable build.

**Scene tree at runtime:**
```
Main (Node)
  ├── World (Node2D)           — SceneManager swaps room scenes here
  ├── HUDLayer (CanvasLayer 10)
  ├── DialogLayer (CanvasLayer 15)
  ├── PostProcessLayer (CanvasLayer 19)
  ├── TransitionOverlay (CanvasLayer 20)
  └── PauseLayer (CanvasLayer 25, process_mode=ALWAYS)
```

**Autoload order matters:** EventBus → GameManager → InventoryManager → AudioManager → SceneManager → SaveManager → Cutscene (Phase 5+)

**Player is persistent** — created once per run, reparented into each room's `Entities` node during transitions. Never duplicated or recreated.

**State machines** are generic (`components/state_machine.gd`). Player, enemies, and bosses all use the same StateMachine node with type-specific State subclasses. States are per-entity-type (not shared across enemy types, except StunnedState).

**Enemies use composition, not scene inheritance.** There is no `base_enemy.tscn`. Each enemy is a standalone scene using `base_enemy.gd` as its script base class, including only the components it needs.

**Bosses are NOT enemies.** `base_boss.gd` extends `Node2D` (not `CharacterBody2D`). Each boss is a bespoke scene with its own state machine and sub-entities.

**Item effects** use `BaseItemEffect` (RefCounted) scripts cached by InventoryManager. `ItemUseState` calls `effect.activate(player)` which spawns scenes (arrows, bombs, etc.) and returns a lock duration.

**Persistence** uses `@export var persist_id: StringName` on entities and `@export var room_id: StringName` on rooms. Flag keys: `{room_id}/{persist_id}`. Never derive IDs from node names or scene paths.

## Conventions

- Health unit = half heart. Starting health = 6 (3 hearts).
- All visuals drawn via `_draw()`, `Polygon2D`, shaders, particles, `PointLight2D`. No sprite textures.
- Audio system logs events when assets are missing. Adding audio = drop files at `res://audio/bgm/{name}.ogg` or `res://audio/sfx/{name}.ogg`.
- Physics layers: 1=World, 2=Player, 3=Enemies, 4=PlayerAttacks, 5=EnemyAttacks, 6=Interactables, 7=Hazards, 8=Triggers.
- Rooms use `y_sort_enabled = true` on the `Entities` node.
- JSON saves use basic types only. Convert `Vector2` to `[x, y]` arrays. Include `schema_version` in every save file.
- Enemies respawn on room re-entry. Chests/blocks/switches persist via GameManager flags.
