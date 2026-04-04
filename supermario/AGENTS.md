# AGENTS.md

## Project Overview

This repository is a very small Godot starter project for `supermario`.

Current state:
- Godot version target: `4.6`
- Rendering feature set: `Forward Plus`
- Physics engine: `Jolt Physics`
- Main custom script present: `new_script.gd`
- No gameplay scenes or complex directory structure exist yet

## Repository Layout

- `project.godot`: Main Godot project configuration. Prefer editing through the Godot editor unless a direct text change is clearly required.
- `new_script.gd`: Starter GDScript attached or intended for a scene node.
- `icon.svg`: Project icon asset.
- `.godot/`: Godot generated editor/import metadata. Do not hand-edit unless there is a very specific reason.
- `.vscode/`: Editor settings.

## Agent Working Agreement

When making changes in this repo:

1. Prefer small, focused edits that match Godot 4.x and typed GDScript style.
2. Keep scripts simple and beginner-readable unless the task clearly calls for more structure.
3. Do not rename files, move assets, or rewrite project settings without a good reason.
4. Avoid editing generated files such as `.godot/*`, `*.import`, or `*.uid` unless the task specifically requires it.
5. Preserve line endings and existing formatting style in touched files.

## GDScript Conventions

- Use `extends` with the correct Godot base class.
- Prefer typed function signatures, for example `func _ready() -> void:`.
- Use `snake_case` for variables and functions.
- Keep `_process` and `_physics_process` only when they are actually needed.
- Add short comments only where logic is not obvious.
- Prefer clear scene/node interactions over overly abstract helper layers in small prototypes.

## Godot-Specific Guidance

- Prefer configuring scenes, node hierarchies, signals, and exported properties in Godot-friendly ways.
- Be careful when editing `project.godot`; malformed entries can break project loading.
- If adding assets or scenes, use `res://` paths consistently.
- When suggesting input handling, prefer Godot Input Map actions over hard-coded keys.

## Running The Project

If Godot is available on the machine, common commands are:

- `godot --path .`
- `godot --headless --path . --quit`

If `godot` is not on `PATH`, use the local Godot executable configured on the machine.

## Testing Expectations

There is no automated test suite in the repo right now.

For changes, prefer lightweight validation such as:
- opening the project successfully
- checking for script parse errors
- running the project headless when possible

## Notes For Future Agents

This repo is currently minimal. If the project grows, update this file to document:
- the main scene entry point
- important gameplay scripts
- autoload singletons
- input actions
- any custom build or export workflow
