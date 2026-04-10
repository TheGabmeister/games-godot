# Code Review Results

## D. Code Smells

### 24. Magic numbers throughout drawing and collision code

Every `_draw()` method is full of unexplained pixel offsets (`-8`, `0.06`, `192.0`, `768.0`, `512.0`, `-200.0`, `500.0`, etc.). The parallax controller alone has dozens. Named constants would make these self-documenting.

Magic collision/layout numbers also appear in:
- `kill_zone.gd:5-6`
- `level_base.gd:16`, `level_1_2.gd:13`
- `question_block.gd:4`
- `pause_menu.gd:3`, `level_complete.gd:3`

### 25. Level layouts hardcoded as code, not data

Pit positions, platform positions, stair coordinates are all baked into GDScript methods like `_get_pits()` returning raw `Vector2i` arrays. A data-driven approach (dictionaries, resources, or even JSON) would be more maintainable and make it possible to add levels without writing code.

