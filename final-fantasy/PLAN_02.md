# Phase 2 — Menu System

## Overview

Adds the main menu shell (opened with Escape from FIELD), party status display, item usage, formation reordering, and stub entries for Magic/Equipment/Config. The menu is a CanvasLayer overlay instantiated by `level.gd`, using the same panel style as DialogueBox.

## Design Decisions

- **State management**: Escape in FIELD → GameState MENU. Cancel from top-level menu → back to FIELD. Input blocked via GameState check (same pattern as dialogue, no physics pause).
- **Instantiation**: `level.gd` creates the menu scene alongside Warrior and DialogueBox. Menu only exists during gameplay levels.
- **Layout**: left column has menu entries + Time + Gil; right panel shows content. Main menu screen doubles as party overview.
- **Item data**: custom `ItemData` Resource class, `.tres` files in `data/items/`. Inventory stored in PartyData as `Dictionary[ItemData, int]`.
- **Visual style**: reuse DialogueBox panel StyleBox. Default font for now.
- **SFX**: reuse `ui/confirm.ogg` and `ui/cancel.ogg`; generate `ui/menu_open.ogg` and `ui/cursor_move.ogg` via ffmpeg.

## Screens

### Main Menu (party overview)

Shown immediately when menu opens. Layout matches FF1 Pixel Remaster:

```
┌─────────────┬──────────────────────────────────────┐
│ > Items     │  ┌──────────────────────────────────┐ │
│   Magic     │  │ [sprite] Warrior    HP  35/  35  │ │
│   Equipment │  │          Lv. 1  MP 0/0/0/0       │ │
│   Status    │  │                  Next Level in  0 │ │
│   Formation │  ├──────────────────────────────────┤ │
│   Config    │  │ [sprite] Monk        HP  33/  33 │ │
│             │  │          Lv. 1  MP 0/0/0/0       │ │
│             │  │                  Next Level in  0 │ │
│  Time 00:00 │  ├──────────────────────────────────┤ │
│  Gil      0 │  │ [sprite] White Mage HP  33/  33  │ │
│             │  │          Lv. 1  MP 0/0/0/0       │ │
│             │  │                  Next Level in  0 │ │
│             │  ├──────────────────────────────────┤ │
│             │  │ [sprite] Black Mage HP  25/  25  │ │
│             │  │          Lv. 1  MP 0/0/0/0       │ │
│             │  │                  Next Level in  0 │ │
└─────────────┴──────────────────────────────────────┘
```

- Cursor on left column navigates menu entries
- Confirm opens the selected submenu
- Cancel (or Escape) closes the menu → FIELD

### Items Screen

Right panel replaces party overview with item list:

```
┌─────────────┬──────────────────────────────────────┐
│   Items     │  Potion           x3                  │
│ > Magic     │  Antidote         x1                  │
│   Equipment │                                       │
│   ...       │                                       │
└─────────────┴──────────────────────────────────────┘
```

- Vertical list of owned items with quantities
- Confirm on an item → party member select (pick who to use it on)
- Only Potions are usable for Phase 2 (heal HP). Other items show in inventory if present but can't be used yet.
- After use: play confirm SFX, update HP, decrement quantity, remove item if quantity hits 0
- Cancel → back to main menu list

### Status Screen

Confirm on Status → party member select on the right panel. Confirm on a character → detail view:

```
┌─────────────┬──────────────────────────────────────┐
│   Items     │  Warrior                              │
│   Magic     │  Level  1                             │
│   Equipment │  HP     35 / 35                       │
│ > Status    │                                       │
│   Formation │  STR  10    AGI   8                   │
│   Config    │  VIT  15    INT   1                   │
│             │  LCK   8                              │
└─────────────┴──────────────────────────────────────┘
```

- Cancel → back to character select → back to main menu

### Formation Screen

Right panel shows party list with position numbers:

```
┌─────────────┬──────────────────────────────────────┐
│   Items     │  1. Warrior                           │
│   Magic     │  2. Monk                              │
│   Equipment │  3. White Mage                        │
│   Status    │  4. Black Mage                        │
│ > Formation │                                       │
│   Config    │                                       │
└─────────────┴──────────────────────────────────────┘
```

- Select-and-swap: confirm on one character highlights them, confirm on another swaps their positions in `PartyData.party`
- Cancel deselects (if one is selected) or returns to main menu

### Stub Screens (Magic, Equipment, Config)

Right panel shows empty content or "Not yet available" text. Cancel returns to main menu.

## Data Structures

### ItemData Resource (`scripts/resources/item_data.gd`)

```
class_name ItemData
extends Resource

enum EffectType { HEAL_HP }

@export var item_name: String
@export var description: String
@export var effect_type: EffectType
@export var potency: int
@export var price: int
```

### PartyData additions (`scripts/autoloads/party_data.gd`)

```
var inventory: Dictionary = {}  # ItemData → int (quantity)
var gil: int = 0
var play_time: float = 0.0
```

- `_process(delta)` increments `play_time` while in FIELD state
- Helper methods: `add_item(item, qty)`, `remove_item(item, qty)`, `use_item(item, target) -> bool`
- Start with 3 Potions in inventory for testing

## Input Flow

1. **FIELD**: player presses Escape → `player_movement.gd` transitions to MENU, calls menu `open()`
2. **MENU (main)**: up/down moves cursor, confirm opens submenu, cancel/escape closes menu → FIELD
3. **Submenu**: each screen handles its own input. Cancel returns to main menu cursor.
4. All menu input handled by the menu script(s). Player movement is already blocked by `GameState.is_state(FIELD)` check.

## Files to Create

| File | Purpose |
|------|---------|
| `scripts/resources/item_data.gd` | ItemData resource class |
| `data/items/potion.tres` | Potion item definition (HEAL_HP, potency 30, price 40) |
| `scripts/ui/main_menu.gd` | Main menu controller script |
| `_scenes/main_menu.tscn` | Menu CanvasLayer scene with panels |
| `scripts/ui/items_screen.gd` | Items submenu logic |
| `scripts/ui/status_screen.gd` | Status submenu logic |
| `scripts/ui/formation_screen.gd` | Formation submenu logic |
| `ui/menu_open.ogg` | Menu open SFX (ffmpeg) |
| `ui/cursor_move.ogg` | Cursor move SFX (ffmpeg) |

## Files to Modify

| File | Change |
|------|--------|
| `scripts/autoloads/party_data.gd` | Add inventory dict, gil, play_time, item helper methods, starting Potions |
| `scripts/level.gd` | Instantiate main_menu.tscn |
| `scripts/player_movement.gd` | Handle Escape press → open menu |

## Build Order

1. **ItemData resource + Potion .tres** — data foundation
2. **PartyData inventory additions** — inventory dict, add/remove/use helpers, starting items
3. **SFX generation** — menu_open.ogg, cursor_move.ogg via ffmpeg
4. **Main menu scene + script** — CanvasLayer, left panel with cursor, right panel with party overview
5. **Level.gd + player_movement.gd integration** — instantiate menu, handle Escape key
6. **Items screen** — item list, use-on-character flow, HP restore
7. **Status screen** — character select → stat detail view
8. **Formation screen** — select-and-swap reordering
9. **Stub screens** — Magic, Equipment, Config placeholders

## Verification

After each step, run `Godot_v4.6.2-stable_win64.exe --path . --run` and test:
1. Escape opens menu with party overview, cancel/escape closes it
2. Cursor moves with SFX, wraps or clamps at list boundaries
3. Items: select Potion, use on damaged character, HP updates, quantity decrements
4. Status: select character, view stats, back out
5. Formation: swap two characters, verify PartyData.party order changed
6. Stubs: open Magic/Equipment/Config, see placeholder, back out
