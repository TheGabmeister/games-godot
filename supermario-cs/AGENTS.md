# AGENTS.md

Guidance for coding agents working in this repository. Architecture and rules live in [CLAUDE.md](CLAUDE.md) — read it first, then come back here for collaboration policy.

## Build & Validation

```bash
dotnet build supermario-cs.csproj      # compile C#
godot --headless --path . --quit       # validate project structure
godot --path .                         # open editor
```

If `godot` is not on PATH on Windows: `D:\Godot\Godot_v4.6.2-stable_mono_win64.exe`. Run `dotnet build` before `godot --headless` — headless does not validate C# syntax. No automated tests; validation is build + manual playtest.

## Working rules

- **Respect user-stated constraints exactly.** If the user rejects an approach, do not keep re-suggesting variants of it.
- **Inspector-wired references over hard-coded lookups.** When the user asks for inspector-wired references, use exported typed references or `NodePath`s. Do not fall back to `GetNode<T>("ChildName")`.
- **`.tscn` edits with care.** Before changing exported properties or scene wiring by hand, inspect the current `.tscn`, explain the tradeoff, and prefer the smallest change that preserves the user's chosen wiring style. The `node_paths=` directive gotcha (see CLAUDE.md) is the most common silent failure.
- **Suspect cache issues before redesigning.** If a Godot editor/runtime cache problem is plausible, say so plainly and try rebuild/reload validation before changing code or scene wiring.
- **Do not hand-edit generated files** under `.godot/`, `*.uid`, or `*.import`.
- **Static accessors are mid-migration.** New gameplay-event code should use `GameEvents` injection (see CLAUDE.md). `GameMode.Instance` access is tolerated where injection has not yet reached but is not the target shape.
