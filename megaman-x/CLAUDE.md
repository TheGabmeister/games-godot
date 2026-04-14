# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Source of truth

`SPEC.md` is the design blueprint — system ownership, scene structure, state machines, collision layers, save flow, phase-by-phase scope. Read it before making architectural decisions. If implementation diverges from the spec, update the spec in the same change or flag the mismatch explicitly.

## Engine and environment

- Godot 4.6, Forward+ renderer, `d3d12` on Windows. Physics engine is Jolt.
- Main scene is `res://scenes/Main.tscn` — this is the runtime shell, not a gameplay stage.
- Shell is bash on Windows — use Unix paths (`/dev/null`, not `NUL`) and forward slashes.

## Common commands

Headless boot smoke check:

```
godot --path . --headless --quit
```

Run a single harness check. Note the `--` separating engine args from user args, and that the mode name is passed as a standalone argument (the harness reads it via `OS.get_cmdline_user_args()`):

```
godot --path . --headless --script tests/smoke/phase_1_harness.gd -- <mode>
```

Modes currently dispatched in [tests/smoke/phase_1_harness.gd](tests/smoke/phase_1_harness.gd): `main_layers`, `title_flow`, `autoloads`, `test_stage`, `locomotion`, `player_spawn`, `camera_follow`, `damage_pipeline`, `player_retry`, `stage_reset`, `enemy_activation`, `enemy_reset`, `enemy_drop_reset`, `enemy_projectile_hit`, `stage_clear_once`, `stage_clear_input_lock`, `stage_clear_overlay`, `checkpoint_activation`, `checkpoint_retry`, `hazard_modes`, `projectile_spawn`, `projectile_rules`, `charge_flow`, `hud_updates`, `audio_events`. Each exits 0 on pass, nonzero on fail. New checks belong in the same `match` block until a later-phase harness is introduced.

## Architecture

The runtime is a **non-autoload shell** plus **four autoloads**. Don't add more autoloads without an explicit design reason.

**Autoloads** (registered in `project.godot`, under `autoloads/`):

- `GameFlow` — owns the `RuntimeState` enum (`BOOT`/`TITLE`/`STAGE_SELECT`/`IN_STAGE`/`PAUSED`/`CUTSCENE`/`STAGE_CLEAR`/`ENDING`), the stage registry, and transition requests. The registry is built at `_ready()` from a `STAGE_REGISTRY_PATHS` array — **stage lookup is never filesystem discovery; stages must be added to that array (or its successor) explicitly.**
- `Progression` — in-memory campaign facts (defeated bosses, unlocked weapons, persistent pickups, dash/armor flags, sub tank state). Not moment-to-moment gameplay state.
- `SaveManager` — versioned JSON round-trip at `user://save_01.json`. No gameplay rules belong here.
- `AudioManager` — semantic event → stream mapping. Gameplay emits event names, never file paths.

**Runtime shell** ([scripts/systems/runtime_shell.gd](scripts/systems/runtime_shell.gd), scene [scenes/Main.tscn](scenes/Main.tscn)) owns actual scene instancing into three layers:

- `WorldRoot` (Node) — exactly one active stage scene at a time.
- `UIRoot` (CanvasLayer, layer 1) — persistent HUD.
- `OverlayRoot` (CanvasLayer, layer 2) — pause, dialogue, stage-clear overlays.

`GameFlow` decides *what* state to enter; the runtime shell resolves *how* to instance and tear down scenes. Stage scenes must not drive global flow.

**Player** ([scripts/player/](scripts/player/)) is component-split — do not collapse these:

- `player.gd` — locomotion, facing, movement state machine only.
- `player_combat.gd` — firing, charge, weapon switching, projectile spawn requests. Separate state machine from locomotion; they run in parallel.
- `health_component.gd` + `hurtbox.gd` + `hit_payload.gd` ([scripts/components/](scripts/components/)) — shared damage pipeline used by player, enemies, bosses, hazards.
- `pickup_receiver.gd` — applies pickup effects; routes persistent rewards into `Progression`.

**Stages** — `StageController` ([scripts/stages/stage_controller.gd](scripts/stages/stage_controller.gd)) owns stage-local flow (spawn, checkpoints, triggers, boss references, stage-clear signaling). Stage scenes should be runnable directly in the editor for iteration — don't introduce dependencies on full boot/title flow for basic stage testing.

## Data-driven conventions

- Weapon, enemy, player tuning, and stage metadata live as `Resource` `.tres` files under `data/` — balance values are authored, not hardcoded.
- Collision layer numbers are fixed by `SPEC.md` (1..13, named). Don't invent new numbers.
- Projectiles share one contract regardless of owner team; default is single-hit destroy-on-hit unless weapon data overrides.
- Charge behavior: `buster` is the only weapon with charge in the current implementation — gate any new charge logic on weapon data, not on player scripts.
