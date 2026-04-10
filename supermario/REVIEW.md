# Code Review Results

## A. Duplicated Code (DRY violations)

## B. Performance Issues

### 7. `load()` at runtime in AudioManager

- `audio_manager.gd:55`, `audio_manager.gd:58`
- `audio_manager.gd:80`, `audio_manager.gd:83`

`load(path)` performs synchronous disk I/O every time an SFX or music track plays. This will cause frame stutters. Should `preload()` or cache in a dictionary on first load.

### 8. `Node2D.new()` + `set_script()` pattern in effects_manager

`effects_manager.gd:21-26`, repeated 4 times.

Creating bare `Node2D` and injecting scripts dynamically is slower than `PackedScene.instantiate()` and defeats editor tooling. These effects should be `.tscn` scenes.

### 9. `queue_redraw()` called every frame unconditionally

- `question_block.gd:24`, `question_block.gd:35-36` — redraws every frame even when not bumping (only `_pulse_time` changes)
- All enemy drawers (`goomba_drawer`, `koopa_drawer`, `koopa_shell_drawer`) call `queue_redraw()` every frame even when stationary/offscreen
- `flagpole.gd:76-77` — redraws every frame even when totally idle (worst offender)
- `parallax_controller.gd:19`
- `player_drawer.gd:25`

Should be conditional: only redraw when visual state actually changed.

### 10. `get_tree().get_nodes_in_group("player")` in hot paths

- `koopa_shell.gd:78` — on every stomp
- `piranha_plant.gd._player_is_nearby()` — every physics frame

Tree traversal on every call. Cache the player reference.

### 11. `move_and_slide()` is called twice per frame in the run path

The helper API is inconsistent — movement helpers both mutate velocity *and* call `move_and_slide()`, so the run path ends up sliding twice.

- `player_controller.gd:122`, `player_controller.gd:139`
- `run_state.gd:18`, `run_state.gd:23`, `run_state.gd:26`

Movement helpers should either only mutate velocity or own the whole move step, not both.

### 12. Timer/HUD emits every frame even when the displayed second has not changed

- `game_manager.gd:30`, `game_manager.gd:38`
- `hud.gd:31`

Only emit when the integer second actually changes.

## C. Architecture Issues

### 13. Player controller is a God Object

`player_controller.gd` handles: movement, gravity, camera management, collision shape updates, 3 timer systems, star power, invincibility, fireball management, stomp combos, death handling, power-ups, damage, pipe entry, and flagpole entry. That's too many responsibilities for one file.

### 14. States and other scripts reach into private members of controllers and autoloads

- `grow_state.gd` and `shrink_state.gd` call `player._update_collision_shape()`
- `shrink_state.gd` calls `player._start_invincibility()`
- `flagpole_state.gd:31` reads `GameManager._timer_active` (private var on an autoload)
- `level_base.gd:60`, `level_1_2.gd:38`
- `pipe_enter_state.gd:53`, `pipe_enter_state.gd:55`, `pipe_enter_state.gd:75`

Underscore-prefixed members are meant to be private. These should be exposed as public APIs.

### 15. PiranhaPlant doesn't extend EnemyBase but reimplements its interface

`piranha_plant.gd` duck-types the full enemy API (`is_active()`, `is_dead()`, `is_dangerous()`, `stomp_kill()`, `non_stomp_kill()`, `shell_kill()`, `die()`) without inheriting from `enemy_base.gd`. If the interface changes, this silently breaks.

### 16. Combat/item interaction is heavily duck-typed and parent-dependent

- `player_controller.gd:117`, `player_controller.gd:240`, `player_controller.gd:277`
- `fireball.gd:48`
- `koopa_shell.gd:147`

The repeated `has_method(...)` plus `area.get_parent()` pattern works, but it's brittle and makes contracts implicit.

### 17. Level boot and run-state ownership is split across UI, level scripts, and GameManager

- `title_screen.gd:30`
- `game_manager.gd:41`
- `level_base.gd:33`, `level_base.gd:60`
- `level_1_2.gd:27`, `level_1_2.gd:38`

Too many places can start/reset a run, making the flow hard to reason about.

### 18. GameManager has misleading API boundaries

- `game_manager.gd:140`, `game_manager.gd:147` — `get_next_level_scene()` mutates world/level state inside a getter
- `player_controller.gd:250`, `koopa_shell.gd:175` — random scripts do `GameManager.lives += 1` instead of going through life-management helpers

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
