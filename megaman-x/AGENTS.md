# AGENTS.md

This repository is an early-stage Godot project for `megaman-x`.

## Scope and boundaries

- Keep all reads and writes inside this repository.
- Do not modify files outside the repo to make this project work.
- Do not revert user changes unless the user explicitly asks for that.

## Current project state

- Engine: Godot 4.6 (`config/features` includes `"4.6"`).
- Physics engine: Jolt Physics.
- Renderer on Windows: `d3d12`.
- Main design reference: `SPEC.md`.
- Current tracked repo content is still light: project config, docs, icon, and editor metadata.
- There are not yet gameplay scenes, scripts, or tests checked in.

## Source of truth

- Read `SPEC.md` before making architecture or gameplay decisions.
- Treat `SPEC.md` as the implementation blueprint for system ownership, scene structure, autoload names, collision layers, state machines, save flow, cutscenes, dialogue, and stage testing workflow.
- If implementation reveals a better approach, update `SPEC.md` in the same change or clearly call out the mismatch.

## Working conventions

- Prefer adding gameplay code under the structure described in `SPEC.md`, especially `scenes/`, `scripts/`, `data/`, `ui/`, `audio/`, `autoloads/`, and `assets/placeholders/`.
- Preserve Godot `.import` and `.godot` generated data unless a task specifically requires touching them.
- Prefer editing gameplay content through normal project files; avoid hand-editing `project.godot` unless the change is simple and clearly understood.
- When introducing new scripts or scenes, use consistent `res://` paths and keep names descriptive.
- Keep changes small and easy to validate.

## Architectural defaults

- Keep autoloads limited to the services already named in `SPEC.md`: `game_flow.gd`, `progression.gd`, `save_manager.gd`, and `audio_manager.gd`, unless the user explicitly wants the architecture changed.
- Follow the component-oriented player structure in `SPEC.md`: `Player.gd` for locomotion, `PlayerCombat.gd` for combat, `HealthComponent.gd` for HP/death, and `PickupReceiver.gd` for pickup effects.
- Keep locomotion and combat state machines separate.
- Use the collision layer plan from `SPEC.md`; do not invent ad hoc layer numbering.
- Keep cutscene and dialogue logic out of player scripts.

## Testing workflow

- Prefer stage scenes to be runnable directly for iteration; do not assume the full boot/title flow is required for every test.
- If you add gameplay scenes or scripts, prefer the narrowest useful validation first: script check, stage smoke test, then broader project launch if needed.

## Validation

- If Godot is available, prefer a headless smoke check after meaningful changes:
  - `godot --path . --headless --quit`
- If `godot` is not on `PATH`, use the local Godot executable configured on the machine.
- If new GDScript files are added, run the narrowest available script check or project startup check instead of relying only on static inspection.

## Notes for future agents

- Start by reading `project.godot` to confirm engine settings before making engine-level changes.
- Start by reading `SPEC.md` to understand the intended subsystem layout before adding code.
- If you need to establish structure, create only the folders required by the task instead of scaffolding the full game at once.
- Update this file when repo-specific workflow, test commands, or implementation conventions become real and stable.
