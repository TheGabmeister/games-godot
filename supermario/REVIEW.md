# Code Review Results

## A. Duplicated Code (DRY violations)

## B. Performance Issues

## C. Architecture Issues

### 17. Level boot and run-state ownership is split across UI, level scripts, and GameManager — **RESOLVED**

Centralized into `GameManager._enter_level(scene_path)` with three public entry
points: `start_new_game()`, `advance_to_next_level()`, and
`respawn_current_level()`. Level scripts (`level_base.gd`, `level_1_2.gd`) are
now pure scene construction — no `_start_level`, no `_on_player_respawned`, no
timer calls, no state mutations. `title_screen.gd`, `level_complete.gd`, and
`game_over_screen.gd` all delegate to the new GameManager API.

Three real bugs were fixed along the way:
- Timer was being started twice on new-game boot (once in `start_new_game`,
  once in `level_base._start_level`).
- The `is_new_game` branch in `level_base._start_level` was dead code that
  duplicated `_reset_run_state()`.
- `level_1_2._start_level` unconditionally stripped Fire Mario on level
  transition. Power state now persists across level completions (classic SMB
  behavior). Requires `player_controller._ready()` to call
  `update_collision_shape()` so the collision size and drawer form match the
  preserved `GameManager.current_power_state` on a fresh scene instance.

### 18. GameManager has misleading API boundaries — **PARTIALLY RESOLVED**

- `get_next_level_scene()` was removed (absorbed into `advance_to_next_level()`
  where the world/level mutation is explicit, not hidden in a "getter").
- Still outstanding: `player_controller.gd` and `koopa_shell.gd` write
  `GameManager.lives += 1` directly instead of going through a helper.

### 19. Unused `_camera` field in CameraEffects

`camera_effects.gd:7` — `_camera` is stored via `register_camera()` on line 40 but never read anywhere. Dead code.

## D. Code Smells

### 20. `Vector2.ZERO` used as null sentinel in AudioManager

`audio_manager.gd:61` — `if position == Vector2.ZERO: return`. What if a legitimate SFX source is at world origin? Ambiguous API.

### 21. Redundant else branch in CameraEffects

`camera_effects.gd:24-25` — sets `_shake_offset = Vector2.ZERO` every frame even when no shake is active. Once the shake ends (line 22-23 handles that), this is just wasted assignment every subsequent frame.

### 22. Hardcoded state name strings everywhere

`&"IdleState"`, `&"JumpState"`, `&"FallState"`, etc. are scattered across all state files and the controller. A rename in the scene tree silently breaks everything with no compile-time error.

### 23. Inconsistent `queue_free()` vs `call_deferred("queue_free")`

- `goomba.gd` uses `queue_free()` directly
- `koopa.gd` and `enemy_base.gd` use `call_deferred("queue_free")`

Should be consistent. During physics callbacks, deferred is safer.

### 24. Magic numbers throughout drawing and collision code

Every `_draw()` method is full of unexplained pixel offsets (`-8`, `0.06`, `192.0`, `768.0`, `512.0`, `-200.0`, `500.0`, etc.). The parallax controller alone has dozens. Named constants would make these self-documenting.

Magic collision/layout numbers also appear in:
- `kill_zone.gd:5-6`
- `level_base.gd:16`, `level_1_2.gd:13`
- `question_block.gd:4`
- `pause_menu.gd:3`, `level_complete.gd:3`

### 25. Level layouts hardcoded as code, not data

Pit positions, platform positions, stair coordinates are all baked into GDScript methods like `_get_pits()` returning raw `Vector2i` arrays. A data-driven approach (dictionaries, resources, or even JSON) would be more maintainable and make it possible to add levels without writing code.

## E. Minor but Noticeable

26. `_player_spawn` set but never read in `level_base.gd` — dead variable.

27. Unused `@onready` vars in `pause_menu.gd` — `_panel` and `_label` are cached but never referenced.

28. `const P := preload("res://scripts/color_palette.gd")` appears in 21 files — not a bug, but if this were an autoload instead, every drawer file would be one line shorter.

29. Format string `"%06d"` in HUD and time warning threshold `100` are magic values.

## Suggested Priority

| Priority | Issue | Impact |
|----------|-------|--------|
| 1 | Extract block bump base class (#1) | Eliminates 3-way duplication |
| 2 | Parameterize tileset creation (#2) | Eliminates near-identical file |
| 3 | Cache `load()` in AudioManager (#7) | Prevents frame stutters |
| 4 | Convert effects to `.tscn` scenes (#8) | Cleaner, faster, debuggable |
| 5 | Extract `_reset_state()` in GameManager (#5) | Quick win |
| 6 | Make private methods public where states need them (#14) | Fixes encapsulation |
| 7 | Remove dead code (#19, #26, #27) | Quick cleanup |
| 8 | Conditional `queue_redraw()` (#9) | Performance with many entities |
