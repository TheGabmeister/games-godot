# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Godot 4.6 Super Mario game project. Currently a minimal starter — no gameplay scenes or systems implemented yet. Uses Forward Plus rendering and Jolt Physics.

## Running

```bash
godot --path .                     # Open in editor
godot --headless --path . --quit   # Headless validation (parse errors, project loading)
```

If `godot` is not on PATH, use: `d:\Godot_v4.6.2-stable_win64.exe`

## Validation

No automated test suite. Validate changes by:
- Running headless to check for script parse errors
- Opening the project in the editor to verify scene loading

## GDScript Conventions

- Typed signatures: `func name(param: Type) -> ReturnType:`
- `snake_case` for variables/functions
- Only include `_process`/`_physics_process` when actually used
- Use `extends` with the correct Godot base class
- Prefer Input Map actions over hard-coded keys
- Use `res://` paths for all asset references

## Working Agreement

- Small, focused edits — keep scripts beginner-readable
- Do not edit generated files: `.godot/*`, `*.import`, `*.uid`
- Do not rename files or rewrite project settings without reason
- Be careful editing `project.godot` — malformed entries break project loading
- Prefer configuring scenes/signals/exports through Godot-friendly patterns
- Preserve existing line endings and formatting
