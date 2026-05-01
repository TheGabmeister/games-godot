# Phase 1 — A character in a room

## Goal

Crono walks around a debug room, talks to an NPC, and reads dialogue in a typewriter textbox. No combat, no menus, no inventory. Placeholder art throughout.

## Scene layout

One scene file: `debug_room.tscn` — the project's main scene.

```
debug_room (Node2D)
├── TileMapLayer          — floor + wall tiles, walls have physics collision
├── Player (CharacterBody2D)
│   ├── Sprite2D          — crono.png
│   ├── CollisionShape2D  — player body collision (RectangleShape2D)
│   └── Camera2D          — child of player, auto-follows
├── NPC (StaticBody2D)
│   ├── Sprite2D          — npc.png
│   ├── CollisionShape2D  — blocks player from walking through
│   └── InteractZone (Area2D)
│       └── CollisionShape2D  — larger radius, detects player proximity
└── DialogueBox (CanvasLayer)
    └── PanelContainer
        ├── NameLabel     — speaker name, colored
        └── TextLabel     — typewriter text output
```

## Scripts

### player.gd (on Player)

- Reads directional input each physics frame (ui_left/right/up/down).
- Normalizes the input vector for diagonal consistency.
- Sets velocity and calls `move_and_slide()`.
- Tracks facing direction (last nonzero input direction) for future use.
- Checks for interact input (ui_accept). If pressed and an NPC is in range, tells the NPC to start interaction.
- Movement is disabled while dialogue is active.

### npc.gd (on NPC)

- Has an `@export var lines: PackedStringArray` — the dialogue lines this NPC speaks, set in the inspector.
- InteractZone uses `body_entered` / `body_exited` signals to track whether the player is close enough to interact.
- When triggered by the player, emits a signal or calls the DialogueBox directly with its lines.

### dialogue_box.gd (on DialogueBox)

- `start(speaker_name: String, lines: PackedStringArray)` — shows the panel, begins typewriting the first line.
- Each frame during typewrite: appends one character to visible text. Speed is a const (characters per second).
- On ui_accept press:
  - If typewriting is in progress → instantly show the full line.
  - If the full line is already displayed → advance to next line, or close if it was the last line.
- Emits a `dialogue_finished` signal when all lines are done. Player script listens to this to re-enable movement.
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

## Camera

Camera2D as a child of the Player node. Position smoothing enabled so it doesn't feel jarring. No other camera logic needed for Phase 1.

## Tilemap

A single TileMapLayer with:
- A floor tile (walkable, no collision).
- A wall tile (with physics layer collision so `move_and_slide` stops the player).

The debug room is a small rectangular space — roughly 12x10 tiles at 16px each. Walls around the border, open floor inside, NPC placed somewhere in the middle area.

Tile art: `floor.png` and `wall.png` from the sprites table above.

## Sprites

SVG source files in `assets/sprites/`, exported to PNG via Inkscape. 16x16 pixels to match the tilemap cell size.

| File | Description |
|------|-------------|
| `assets/sprites/crono.svg` → `crono.png` | Crono — simple top-down character shape. Blue/white color scheme. |
| `assets/sprites/npc.svg` → `npc.png` | Generic NPC — distinct silhouette from Crono. Green/brown color scheme. |
| `assets/sprites/floor.svg` → `floor.png` | Floor tile — warm tan/brown. |
| `assets/sprites/wall.svg` → `wall.png` | Wall tile — darker gray, visually reads as solid. |

Export command for each:
```
"/c/Program Files/Inkscape/bin/inkscape.exe" assets/sprites/<name>.svg --export-type=png --export-filename=assets/sprites/<name>.png -w 16 -h 16
```

These are simple placeholder sprites — flat colors with minimal detail. Just enough to distinguish player from NPC from wall from floor.

## What we skip

- Animation / sprite sheets — Crono is a static sprite that doesn't animate. Facing direction is tracked but not visually reflected yet.
- Party followers — just one character.
- Save/load, menus, inventory — not until Phase 5.
- Audio — no sounds or music yet.
- Any abstraction beyond what three scripts need. No autoloads, no signal bus, no manager classes.
