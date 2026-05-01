#!/bin/bash
# Re-exports all SVG sprites to PNG via Inkscape.
# Run from the project root: bash tools/export_sprites.sh

INKSCAPE="/c/Program Files/Inkscape/bin/inkscape.exe"

# Sprite sheets (8 frames × 64px = 512 wide)
"$INKSCAPE" player/crono_sheet.svg --export-type=png --export-filename=player/crono_sheet.png -w 512 -h 64
"$INKSCAPE" npc/npc_sheet.svg --export-type=png --export-filename=npc/npc_sheet.png -w 512 -h 64

# Single tiles (64x64)
"$INKSCAPE" props/floor.svg --export-type=png --export-filename=props/floor.png -w 64 -h 64
"$INKSCAPE" props/wall.svg --export-type=png --export-filename=props/wall.png -w 64 -h 64

echo "All sprites exported."
