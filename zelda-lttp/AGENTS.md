# AGENTS.md

## Purpose

This repository is a Godot 4.6 recreation of the mechanics and game feel of *The Legend of Zelda: A Link to the Past* using original primitive visuals and placeholder-friendly audio hooks.

`SPEC.md` is the primary source of truth. Read it before making architectural decisions. If implementation pressure conflicts with the spec, favor the spec and document any deliberate deviation.

## Current Repository State

- Phases 1-8 are present in the repository, but some Phase 7 and Phase 8 integrations should still be treated as verification-sensitive until they are confirmed end-to-end against `SPEC.md`.
- `SPEC.md` defines the intended architecture, conventions, milestones, and acceptance criteria.
- `project.godot` currently confirms:
  - Godot `4.6`
  - Renderer: `Forward Plus`
  - Windows rendering driver: `d3d12`
- Current implemented baseline includes:
  - `scenes/main/main.tscn` as the root scene with `World`, `HUDLayer`, `DialogLayer`, `PostProcessLayer`, `TransitionOverlay`, `GameOverLayer`, and `PauseLayer`
  - Autoloads registered in `project.godot`: `EventBus`, `GameManager`, `ItemRegistry`, `PlayerState`, `AudioManager`, `SceneManager`, `SaveManager`, `Cutscene`
  - A persistent player scene with states currently present in the scene tree including `Idle`, `Walk`, `Attack`, `Knockback`, `Fall`, `Dash`, `ItemUse`, `ItemGet`, `Cutscene`, `Swim`, `Lift`, `Carry`, `Throw`, `Death`, and `Trapped`
  - Phase 2 combat components and enemy architecture: shared `HurtboxComponent`, `HitboxComponent`, `HealthComponent`, `KnockbackComponent`, `FlashComponent`, `LootDropComponent`, `EnemyData`, and `base_enemy.gd`
  - Five Phase 2 enemy archetypes implemented as standalone scenes: Soldier, Octorok, Keese, Stalfos, and Buzz Blob
  - A reusable projectile baseline in `scenes/projectiles/projectile_base.tscn`
  - Phase 2 drops/pickups content in `resources/loot_tables/`, `resources/items/pickups/`, and `scenes/pickups/pickup.tscn`
  - Phase 3 skills (10 SKILL items with effect scripts including Magic Mirror), upgrades (16 UPGRADE items), item use system (`ItemUseState`, `BaseItemEffect`), acquisition presentation (`ItemGetState`), chest interaction, shield tiers (`ShieldComponent`), swim state, pause subscreen, and HUD magic meter
  - Phase 4 world structure: 4x4 light world overworld grid (`scenes/rooms/overworld/`), 2 interiors (`cave_01`, `house_01`), 4-room dungeon (`dungeon_01`), 2x2 dark world subset (`scenes/rooms/dark_overworld/`)
  - Phase 4 transition system: `TransitionOverlay` with fade/iris effects, screen-edge scroll transitions, `Door` scene with walk-in/interact triggers
  - Phase 4 dungeon elements: `LockedDoor`, `BossDoor`, `PushBlock`, `DungeonSwitch`, `PressurePlate`, `SwitchDoor`, `ConveyorBelt`
  - Phase 4 world switching: `WorldPortal`, `SceneManager.switch_world()`, bunny transform without Moon Pearl
  - Phase 6 systems present in the branch: title screen flow, save/load, dialog typewriter flow, cutscene autoload, post-process color grading hooks, squash/stretch helper, torch flicker helper, and impact particle helper
  - Phase 7 systems present: expanded 8x8 overworld room-data coverage, dungeon 02 and dungeon 03 room sets, NPC scene/reward flows, heart piece placements, destructible/liftable objects, and baseline lift/carry/throw support
  - Phase 8-era additions currently present: glove-tier liftables (`SkullRock`, `DarkBoulder`), `GameOverScreen`, `DeathState`, `TrappedState`, and advanced enemy scenes/resources for `LikeLike` and `Wizzrobe`
  - Debug coverage including `debug/debug_room.tscn`, `debug/damage_formula_test.gd`, `debug/test_loot_table.tscn`, and `debug/test_player_state.tscn`
  - A debug room with `Entities`, `EntryPoints`, walls, a pit hazard, combat test fixtures, y-sort verification dummies, and 6 Phase 3 test chests
  - A HUD with hearts display, rupee counter, equipped item slot, and magic meter
- Later-phase gameplay content is still incomplete, so new work should extend the current Phase 8 baseline toward the Phase 9 boss work in the spec instead of inventing a parallel structure.
- Some systems intentionally remain scaffolds:
  - Later-phase registries/resources may exist before their full gameplay loops do
- Some systems are present but should be treated as integration-sensitive rather than assumed finished:
  - Phase 6 save/load and title-screen flow exist in code, but do not assume end-to-end slot creation, continue flow, delete flow, or game-over save-and-quit behavior are complete in the current branch unless you verify them
  - Dialog, `ItemGetState`, reward flows, and cutscene waits should be checked carefully before extension; `EventBus.dialog_closed` ownership is especially migration-sensitive
  - Save schema shape and `schema_version` handling should be treated as migration-sensitive if you touch `SaveManager`, `PlayerState.serialize()`, or `GameManager.serialize()`
- Some spec-defined combat and interaction details may still need alignment work even though the Phase 2-8 baseline is present:
  - Shield-block behavior should be treated as migration-sensitive combat logic, not assumed complete unless verified in the current branch
  - Loot/pickup behavior should stay aligned with the spec's weighted-table and pickup-payload expectations when extending drops to bushes, pots, or other destructibles
  - Lift/carry/throw edge cases, game-over respawn/save behavior, and advanced enemy integration should be treated as verification-sensitive before building further features on top of them

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
- Room `Entities` nodes should stay `y_sort_enabled = true`; moving actors, NPCs, pickups, and the persistent player should sort there instead of faking depth with manual `z_index` tweaks.
- The sword is always available.
- There is one equipped skill slot on the action button, not two active item slots.
- Every room script must expose `@export var room_data: RoomData`; `RoomData` is the single source of truth for room metadata.
- Persistent objects must expose `@export var persist_id: StringName`.
- Persistence keys are built as `{room_id}/{persist_id}`.
- Persistent entities should warn in `_get_configuration_warnings()` when `persist_id` is empty.
- Save data must include a schema version.
- Character-sheet state belongs on the `PlayerState` autoload.
- World/story/per-dungeon boolean progression belongs in `GameManager` flags.
- Transient navigation state belongs in `SceneManager`, not `GameManager`.
- Room transitions should go through stable `room_id` values resolved by `SceneManager.room_registry`; do not hardcode room scene paths in gameplay code.
- Item lookup by stable id belongs through `ItemRegistry`; do not hardcode `.tres` paths in gameplay code.
- The player does not use a `HealthComponent`; enemy actors do.
- New systems should fit the spec's directory structure unless there is a strong, documented reason not to.

## Phase-Oriented Development

Build toward the milestone flow in `SPEC.md`:

1. Phase 1: movement, room loading, player, HUD, autoload foundations
2. Phase 2: combat, enemies, drops
3. Phase 3: skills, upgrades, resources, subscreen
4. Phase 4: overworld, transitions, dungeon structure, world switching
5. Phase 5: first dungeon playthrough via reward pedestal placeholder
6. Phase 6: HUD polish, dialog, cutscenes, title screen, save/load, effects pass
7. Phase 7: expanded content, additional dungeons, NPCs, baseline lifting/destructibles
8. Phase 8: glove upgrades, game over, advanced enemies, audio coverage
9. Phase 9: bosses and boss retrofit into earlier dungeons

If the user asks for a new feature and the repo does not yet support its prerequisite phase, either:

- implement the missing prerequisite first, or
- explicitly note that the change is being added as forward scaffolding

## Godot and GDScript Expectations

- Target Godot `4.6`.
- Use GDScript unless the user asks otherwise.
- Prefer typed GDScript where practical.
- Keep scenes and scripts paired and organized by feature domain as described in `SPEC.md`.
- Reuse shared components for health, hurtboxes, hitboxes, flashing, knockback, loot drops, and state machines instead of duplicating logic.
- Do not remove or bypass an existing state from the player's scene tree when a transition already targets it; keep the state machine scene wiring and scripts in sync.
- Use the current spec terminology consistently: `skills`, `upgrades`, and `resources`, not an RPG-style inventory model.
- Keep `PlayerState` as a character-sheet facade, not a god object. If its logic grows, split internals into small helper/domain scripts while preserving `PlayerState` as the stable public entry point.
- Enemy behavior is per-enemy-state driven; do not collapse all enemies into a single generic AI script.
- Bosses are bespoke scenes that may share `base_boss.gd`, but they are not just regular enemies with more HP.

## Visual and UX Direction

The project is mechanics-first, but visual polish still matters. Keep this intact:

- Primitive shape language must remain readable and intentional.
- Feedback should come from animation, lighting, particles, shaders, squash/stretch, and screen shake.
- Avoid placeholder UI or visuals that contradict the spec's visual language if a simple aligned version is feasible.
- Respect the intended logical resolution of `256x224` and the `16x16` tile grid.
- Godot's default fallback font is anti-aliased and will look soft at this resolution when scaled. If crisp retro text matters, use an imported pixel font instead of assuming the engine default will read cleanly.

## Persistence and Content Safety

When creating content with save-state implications:

- Always set stable exported IDs instead of deriving them from filenames or node names at runtime.
- Avoid renaming persistent IDs casually; that can invalidate saves.
- Treat room IDs, `RoomData.scene_path`, dungeon IDs, item IDs, and resource IDs as migration-sensitive.
- Treat `PlayerState` serialization shape and `GameManager` flag keys as migration-sensitive as well.
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
- Use the debug room to verify room loading, hazards, player insertion under `Entities`, y-sort behavior, enemy combat behavior, projectile interactions, and pickup drops before treating a Phase 1 or Phase 2 change as done
- Run the available debug tests when touching combat math or loot behavior, especially `debug/damage_formula_test.gd` and `debug/test_loot_table.tscn`
- For Phase 6 work, do not stop at headless boot: verify title-screen flow, dialog dismissal, cutscene resume points, and any save/load path you changed
- For Phase 7 work, verify NPC gating/reward flow, heart piece persistence, dungeon reward pedestal flow, and lift/carry/throw behavior including pit and transition edge cases
- For Phase 8 work, verify glove-tier lifting, death-to-game-over flow, continue/save-and-quit behavior, and advanced enemy behavior in an authored room or debug setup rather than relying on headless boot alone

Useful local context:

- Editor path in `.vscode/settings.json`: `d:\Godot_v4.6.2-stable_win64.exe`

## When Unsure

- Prefer the spec over guesswork.
- Preserve additive progress: each phase should leave the game runnable.
- Do not rip out prior systems just to satisfy a new request.
- If the spec and the actual repo diverge, call that out clearly in your summary.
