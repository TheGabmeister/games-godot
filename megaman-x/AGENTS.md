# AGENTS.md

This repository is a very early-stage Godot project for `megaman-x`.

## Scope and boundaries

- Keep all reads and writes inside this repository.
- Do not modify files outside the repo to make this project work.
- Do not revert user changes unless the user explicitly asks for that.

## Current project state

- Engine: Godot 4.6 (`config/features` includes `"4.6"`).
- Physics engine: Jolt Physics.
- Renderer on Windows: `d3d12`.
- Current tracked project files are minimal: `project.godot`, `icon.svg`, and editor metadata.
- There are currently no gameplay scenes, scripts, tests, or asset pipelines checked in.

## Working conventions

- Prefer adding gameplay code under conventional Godot folders such as `scenes/`, `scripts/`, `assets/`, and `addons/` as the project grows.
- Preserve Godot `.import` and `.godot` generated data unless a task specifically requires touching them.
- Prefer editing gameplay content through normal project files; avoid hand-editing `project.godot` unless the change is simple and clearly understood.
- When introducing new scripts or scenes, use consistent `res://` paths and keep names descriptive.
- Keep changes small and easy to validate. This repo is still forming its structure.

## Validation

- If Godot is available, prefer a headless smoke check after meaningful changes:
  - `godot --path . --headless --quit`
- If `godot` is not on `PATH`, use the local Godot executable configured on the machine.
- If new GDScript files are added, run the narrowest available script check or project startup check instead of relying only on static inspection.

## Notes for future agents

- Start by reading `project.godot` to confirm engine settings before making engine-level changes.
- If you need to establish structure, create only the folders required by the task instead of scaffolding a full game layout speculatively.
- Document any new repo-specific workflow here once real scenes, scripts, build steps, or test commands exist.
