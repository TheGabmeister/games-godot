# Code Review Results

## D. Code Smells

### 24. Magic numbers throughout collision/layout code

Magic collision/layout numbers appear in:
- `kill_zone.gd:5-6`
- `level_base.gd:16`, `level_1_2.gd:13`
- `question_block.gd:4`
- `pause_menu.gd:3`, `level_complete.gd:3`

### 25. Level layouts hardcoded as code, not data

Pit positions, platform positions, stair coordinates are all baked into GDScript methods like `_get_pits()` returning raw `Vector2i` arrays. A data-driven approach (dictionaries, resources, or even JSON) would be more maintainable and make it possible to add levels without writing code.

