# Code Review Results

## D. Code Smells

### 22. Hardcoded state name strings everywhere

`&"IdleState"`, `&"JumpState"`, `&"FallState"`, etc. are scattered across all state files and the controller. A rename in the scene tree silently breaks everything with no compile-time error.

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
