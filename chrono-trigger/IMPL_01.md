# Phase 1 — A character in a room

## Goal

Crono walks around a debug room, talks to an NPC, and reads dialogue in a typewriter textbox. No combat, no menus, no inventory. Placeholder art throughout.

## Project folder structure

```
res://
├── dialogue/          — DialogueData .tres files
├── npc/               — NPC sprites and audio
├── player/            — player sprites and audio
├── props/             — tilemap/environment sprites and audio
├── scenes/            — all .tscn files (debug_room, player, npc, dialogue_box)
├── scripts/           — all .gd files (game_state, player, npc, dialogue_box, dialogue_data)
└── docs/              — spec companion files (techs, bestiary, boss-ai)
```

## Scene layout

One scene file: `scenes/debug_room.tscn` — the project's main scene.

```
debug_room (Node2D)
├── TileMapLayer          — floor + wall tiles, walls have physics collision
├── Player (CharacterBody2D)
│   ├── AnimatedSprite2D  — crono_sheet.png via SpriteFrames
│   ├── CollisionShape2D  — player body collision (RectangleShape2D)
│   ├── InteractRay (RayCast2D) — short ray in facing direction, detects interactables
│   └── Camera2D          — child of player, auto-follows
├── NPC (StaticBody2D)
│   ├── AnimatedSprite2D  — npc_sheet.png via SpriteFrames
│   └── CollisionShape2D  — blocks player from walking through
└── DialogueBox (CanvasLayer)
    └── PanelContainer
        ├── NameLabel     — speaker name, colored
        └── TextLabel     — typewriter text output
```

## Scripts

All scripts live in `scripts/`. All scenes live in `scenes/`.

### game_state.gd (autoload)

Registered as an autoload named `GameState` in Project Settings.

- `enum State { FIELD, DIALOGUE }` — expanded in later phases (MENU, BATTLE, CUTSCENE).
- `var current: State = State.FIELD`
- `func change(new_state: State)` — sets `current` and emits a `state_changed(new_state)` signal so nodes can react if needed.

### player.gd (on Player)

- All input is gated on `GameState.current == GameState.State.FIELD`.
- Reads directional input each physics frame (ui_left/right/up/down).
- Normalizes the input vector for diagonal consistency.
- Sets velocity and calls `move_and_slide()`.
- Tracks facing direction (last nonzero input direction). Updates the InteractRay's `target_position` to point in that direction.
- On interact input: checks if InteractRay is colliding. If the collider is in the "interactable" group, calls `interact()` on it.

### dialogue_data.gd (resource)

```gdscript
class_name DialogueData
extends Resource

@export var speaker_name: String
@export var lines: PackedStringArray
```

Authored as `.tres` files in `dialogue/` (e.g., `dialogue/npc_greeting.tres`). Each file is one conversation.

### npc.gd (on NPC)

- Has an `@export var dialogue: DialogueData` — assigned in the inspector to a `.tres` file.
- Node is added to the "interactable" group.
- `interact()` method: calls the DialogueBox with `dialogue`.

### dialogue_box.gd (on DialogueBox)

- `start(data: DialogueData)` — shows the panel, sets `GameState.change(State.DIALOGUE)`, begins typewriting the first line using `data.speaker_name` and `data.lines`.
- All input is gated on `GameState.current == GameState.State.DIALOGUE`.
- Each frame during typewrite: appends one character to visible text. Speed is a const (characters per second).
- On interact press:
  - If typewriting is in progress → instantly show the full line.
  - If the full line is already displayed → advance to next line, or close if it was the last line.
- On close: sets `GameState.change(State.FIELD)`.
- The panel is hidden by default.

## Input map

Add these to `project.godot` input map (or configure in editor):

| Action       | Keyboard          | Gamepad                   | Purpose              |
|--------------|-------------------|---------------------------|----------------------|
| move_up      | W / Up arrow      | Left stick up / D-pad up  | movement             |
| move_down    | S / Down arrow    | Left stick down / D-pad down | movement          |
| move_left    | A / Left arrow    | Left stick left / D-pad left | movement          |
| move_right   | D / Right arrow   | Left stick right / D-pad right | movement        |
| interact     | Z / Enter         | A (bottom face button)    | talk to NPC, advance dialogue |

## Display

- **Resolution:** 1200×900 (4:3).
- Set in `project.godot` under `display/window/size` — `viewport_width=1200`, `viewport_height=900`.
- Stretch mode: `canvas_items`, aspect: `keep` — scales cleanly to larger displays.

## Camera

Camera2D as a child of the Player node. Position smoothing enabled so it doesn't feel jarring. No other camera logic needed for Phase 1.

## Tilemap

A single TileMapLayer with:
- A floor tile (walkable, no collision).
- A wall tile (with physics layer collision so `move_and_slide` stops the player).

The debug room is a small rectangular space — roughly 20x15 tiles at 32px each (fits neatly in 1200×900 with room to spare). Walls around the border, open floor inside, NPC placed somewhere in the middle area.

Tile art: `props/floor.png` and `props/wall.png` from the sprites table above.

## Sprites

SVG source files exported to PNG via Inkscape. 32×32 pixels per tile/character.

| File | Description |
|------|-------------|
| `player/crono_sheet.svg` → `crono_sheet.png` | Crono sprite sheet — 4 directions × 2 walk frames = 8 frames in a horizontal strip. Blue/white color scheme. See sprite sheet layout below. |
| `npc/npc_sheet.svg` → `npc_sheet.png` | NPC sprite sheet — 4 directions × 2 idle frames = 8 frames in a horizontal strip. Green/brown color scheme. See NPC sprite sheet layout below. |
| `props/floor.svg` → `floor.png` | Floor tile — warm tan/brown. |
| `props/wall.svg` → `wall.png` | Wall tile — darker gray, visually reads as solid. |

Export commands:
```
"/c/Program Files/Inkscape/bin/inkscape.exe" player/crono_sheet.svg --export-type=png --export-filename=player/crono_sheet.png -w 256 -h 32
"/c/Program Files/Inkscape/bin/inkscape.exe" npc/npc_sheet.svg --export-type=png --export-filename=npc/npc_sheet.png -w 256 -h 32
"/c/Program Files/Inkscape/bin/inkscape.exe" <folder>/<name>.svg --export-type=png --export-filename=<folder>/<name>.png -w 32 -h 32
```

### Crono sprite sheet layout

Horizontal strip: 256×32 px (8 frames × 32px each). Each 32×32 cell is one frame.

```
| down_0 | down_1 | up_0 | up_1 | left_0 | left_1 | right_0 | right_1 |
```

- **down_0 / down_1** — facing camera, idle and walk step.
- **up_0 / up_1** — facing away, idle and walk step.
- **left_0 / left_1** — facing left, idle and walk step.
- **right_0 / right_1** — facing right, idle and walk step.

Simple top-down character. Walk frames differ by leg position (one leg forward vs. the other). Keep it minimal — the goal is to read direction and movement, not detailed animation.

### NPC sprite sheet layout

Same format as Crono: 256×32 px horizontal strip, 8 frames of 32×32.

```
| down_0 | down_1 | up_0 | up_1 | left_0 | left_1 | right_0 | right_1 |
```

The NPC doesn't walk, so the two frames per direction are a subtle idle animation (e.g., slight body shift or blink). Plays on loop while standing. The NPC faces down by default.

### Animation setup

Both Player and NPC use `AnimatedSprite2D` with a `SpriteFrames` resource built from their respective sprite sheets.

**Player animations:**
- 4 walk animations: `walk_down`, `walk_up`, `walk_left`, `walk_right` — 2 frames each, looping at ~6 FPS.
- 4 idle animations: `idle_down`, `idle_up`, `idle_left`, `idle_right` — 2 frames each, looping at ~3 FPS.
- `player.gd` plays the walk animation matching the facing direction when moving, switches to idle when stopped.

**NPC animations:**
- 4 idle animations: `idle_down`, `idle_up`, `idle_left`, `idle_right` — 2 frames each, looping at ~3 FPS.
- Defaults to `idle_down`. No walk animations needed for Phase 1.

## Test checklist

### Movement
- [x] WASD moves Crono in 8 directions
- [x] Arrow keys also work
- [x] Gamepad left stick and D-pad also work
- [x] Diagonal movement is normalized (not faster than cardinal)
- [x] Walk animation plays while moving, matches facing direction
- [x] Idle animation plays when stopped, matches last facing direction
- [x] Crono stops at all 4 walls and cannot pass through them
- [x] Crono cannot walk through the NPC

### Interaction
- [x] Facing the NPC and pressing Z/Enter/gamepad A triggers dialogue
- [x] Facing away from the NPC and pressing interact does nothing
- [x] Being too far from the NPC and pressing interact does nothing

### Dialogue
- [x] Dialogue box appears at the bottom of the screen
- [x] Speaker name ("Old Man") is displayed in blue
- [x] Text typewriters character by character
- [x] Pressing interact mid-typewrite instantly completes the line
- [x] Pressing interact after a line is complete advances to the next line
- [x] After the last line, pressing interact closes the dialogue box
- [x] Player cannot move while dialogue is open
- [x] Player can move again after dialogue closes

### Camera
- [x] Camera follows the player smoothly
- [x] Camera starts centered on the room

### NPC
- [x] NPC plays idle animation (subtle bob) while standing

## What we skip

- Party followers — just one character.
- Save/load, menus, inventory — not until Phase 5.
- Audio — no sounds or music yet.
- No signal bus or manager classes beyond GameState.
