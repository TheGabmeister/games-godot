# AGENTS.md

## Purpose

This repository is a Godot 4.6 recreation of the mechanics and game feel of *The Legend of Zelda: A Link to the Past* using original primitive visuals and placeholder-friendly audio hooks.

`SPEC.md` is the primary source of truth. Read it before making architectural decisions. If implementation pressure conflicts with the spec, favor the spec and document any deliberate deviation.

## Current Repository State

- The repo is still at an early scaffold stage.
- `SPEC.md` defines the intended architecture, conventions, milestones, and acceptance criteria.
- `project.godot` currently confirms:
  - Godot `4.6`
  - Renderer: `Forward Plus`
  - Windows rendering driver: `d3d12`
- There is not yet a full gameplay codebase in place, so new work should build toward the spec's phase plan instead of inventing a parallel structure.

## Read This First

Before changing code, skim these in order:

1. `SPEC.md`
2. `project.godot`
3. The relevant section of `SPEC.md` for the current phase or requested feature

## Non-Negotiable Project Rules

- Preserve the project's legal/creative constraint: no original Nintendo sprites, tiles, or audio assets.
- Use primitive shapes, shaders, particles, lighting, and original placeholder assets.
- Keep systems data-driven where the spec calls for resources.
- Prefer small, testable scenes.
- Global cross-scene concerns belong in autoloads.
- Local presentation and interaction belong in scenes/components.
- Do not silently change naming conventions, IDs, save keys, or folder layout defined by the spec.

## Architecture Guardrails

Follow these conventions from the spec unless the user asks to change them:

- The player is a persistent scene instance created once per run and reparented into each room's `Entities` node during transitions.
- The sword is always available.
- There is one active item slot, not two.
- Every room script must expose `@export var room_id: StringName`.
- Persistent objects must expose `@export var persist_id: StringName`.
- Persistence keys are built as `{room_id}/{persist_id}`.
- Persistent entities should warn in `_get_configuration_warnings()` when `persist_id` is empty.
- Save data must include a schema version.
- New systems should fit the spec's directory structure unless there is a strong, documented reason not to.

## Phase-Oriented Development

Build toward the milestone flow in `SPEC.md`:

1. Phase 1: movement, room loading, player, HUD, autoload foundations
2. Phase 2: combat, enemies, drops, save/load
3. Phase 3: inventory, active items, passive upgrades
4. Phase 4: overworld, transitions, dungeon structure, world switching
5. Phase 5+: bosses, polish, expanded content, advanced mechanics

If the user asks for a new feature and the repo does not yet support its prerequisite phase, either:

- implement the missing prerequisite first, or
- explicitly note that the change is being added as forward scaffolding

## Godot and GDScript Expectations

- Target Godot `4.6`.
- Use GDScript unless the user asks otherwise.
- Prefer typed GDScript where practical.
- Keep scenes and scripts paired and organized by feature domain as described in `SPEC.md`.
- Reuse shared components for health, hurtboxes, hitboxes, flashing, knockback, loot drops, and state machines instead of duplicating logic.
- Enemy behavior is per-enemy-state driven; do not collapse all enemies into a single generic AI script.
- Bosses are bespoke scenes that may share `base_boss.gd`, but they are not just regular enemies with more HP.

## Visual and UX Direction

The project is mechanics-first, but visual polish still matters. Keep this intact:

- Primitive shape language must remain readable and intentional.
- Feedback should come from animation, lighting, particles, shaders, squash/stretch, and screen shake.
- Avoid placeholder UI or visuals that contradict the spec's visual language if a simple aligned version is feasible.
- Respect the intended logical resolution of `256x224` and the `16x16` tile grid.

## Persistence and Content Safety

When creating content with save-state implications:

- Always set stable exported IDs instead of deriving them from filenames or node names at runtime.
- Avoid renaming persistent IDs casually; that can invalidate saves.
- Treat room IDs, dungeon IDs, item IDs, and resource IDs as migration-sensitive.
- If you must change save-relevant structure, update the schema version and note the migration impact.

## Implementation Style

- Make the smallest change that cleanly fits the planned architecture.
- Prefer extending shared systems over adding one-off shortcuts.
- If a shortcut is necessary to keep a milestone playable, leave a clear TODO or note in code or docs.
- Keep comments brief and only where they add real clarity.
- Avoid speculative systems the spec does not need yet.

## Verification

When possible, verify work in one of these ways:

- Open the project in the Godot editor configured in `.vscode/settings.json`
- Run Godot headless for smoke checks if the project has enough content to load safely
- Validate that scene/script/resource references are still consistent

Useful local context:

- Editor path in `.vscode/settings.json`: `d:\Godot_v4.6.2-stable_win64.exe`

## When Unsure

- Prefer the spec over guesswork.
- Preserve additive progress: each phase should leave the game runnable.
- Do not rip out prior systems just to satisfy a new request.
- If the spec and the actual repo diverge, call that out clearly in your summary.
