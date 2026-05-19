"""Generate Cornelia town tileset atlas as a single PNG."""
from PIL import Image, ImageDraw

TILE = 64
# Atlas layout: 8 columns x 4 rows = 32 tile slots
COLS, ROWS = 8, 4
atlas = Image.new('RGBA', (TILE * COLS, TILE * ROWS), (0, 0, 0, 0))

def draw_tile(col, row, func):
    tile = Image.new('RGBA', (TILE, TILE), (0, 0, 0, 0))
    d = ImageDraw.Draw(tile)
    func(d, tile)
    atlas.paste(tile, (col * TILE, row * TILE))

# ── ROW 0: Ground tiles (walkable) ───────────────────────────────────────────

def grass(d, t):
    d.rectangle([0, 0, 63, 63], fill=(60, 140, 50))
    # Grass blades
    for x in range(4, 60, 8):
        for y in range(4, 60, 12):
            d.rectangle([x, y, x+2, y+4], fill=(50, 120, 40))
    for x in range(8, 60, 12):
        for y in range(10, 60, 14):
            d.rectangle([x, y, x+2, y+3], fill=(70, 160, 55))

def stone_path(d, t):
    d.rectangle([0, 0, 63, 63], fill=(160, 150, 130))
    # Stone pattern
    d.rectangle([2, 2, 28, 28], fill=(170, 160, 140))
    d.rectangle([32, 2, 62, 28], fill=(150, 140, 120))
    d.rectangle([2, 32, 28, 62], fill=(150, 140, 120))
    d.rectangle([32, 32, 62, 62], fill=(170, 160, 140))
    # Grout lines
    d.rectangle([0, 29, 63, 31], fill=(130, 120, 100))
    d.rectangle([29, 0, 31, 63], fill=(130, 120, 100))

def wood_floor(d, t):
    d.rectangle([0, 0, 63, 63], fill=(140, 100, 60))
    # Planks
    for y in range(0, 64, 16):
        d.rectangle([0, y, 63, y+1], fill=(120, 85, 50))
    # Wood grain
    for y in range(0, 64, 16):
        offset = 20 if (y // 16) % 2 == 0 else 0
        d.rectangle([offset + 30, y+4, offset + 32, y+12], fill=(130, 92, 55))

def sand(d, t):
    d.rectangle([0, 0, 63, 63], fill=(210, 190, 140))
    for x in range(6, 60, 10):
        for y in range(6, 60, 14):
            d.rectangle([x, y, x+2, y+1], fill=(200, 180, 130))
    for x in range(10, 60, 12):
        for y in range(12, 60, 10):
            d.rectangle([x, y, x+1, y+1], fill=(195, 175, 125))

def door(d, t):
    d.rectangle([0, 0, 63, 63], fill=(100, 60, 30))
    # Door frame
    d.rectangle([4, 0, 60, 63], fill=(120, 75, 35))
    d.rectangle([8, 4, 56, 63], fill=(90, 55, 25))
    # Door handle
    d.rectangle([40, 30, 46, 36], fill=(200, 180, 60))
    # Door panels
    d.rectangle([12, 8, 28, 28], fill=(100, 65, 30))
    d.rectangle([34, 8, 50, 28], fill=(100, 65, 30))
    d.rectangle([12, 34, 28, 58], fill=(100, 65, 30))
    d.rectangle([34, 34, 50, 58], fill=(100, 65, 30))

def dark_floor(d, t):
    """Castle/interior dark stone floor."""
    d.rectangle([0, 0, 63, 63], fill=(80, 75, 90))
    d.rectangle([2, 2, 28, 28], fill=(90, 85, 100))
    d.rectangle([32, 2, 62, 28], fill=(75, 70, 85))
    d.rectangle([2, 32, 28, 62], fill=(75, 70, 85))
    d.rectangle([32, 32, 62, 62], fill=(90, 85, 100))
    d.rectangle([0, 29, 63, 31], fill=(60, 55, 70))
    d.rectangle([29, 0, 31, 63], fill=(60, 55, 70))

# ── ROW 1: Wall tiles (impassable) ───────────────────────────────────────────

def stone_wall(d, t):
    d.rectangle([0, 0, 63, 63], fill=(120, 115, 105))
    # Brick pattern
    for y in range(0, 64, 16):
        offset = 16 if (y // 16) % 2 else 0
        for x in range(-16, 80, 32):
            bx = x + offset
            d.rectangle([bx+1, y+1, bx+29, y+13], fill=(130, 125, 115))
            d.rectangle([bx+2, y+2, bx+28, y+12], fill=(140, 135, 125))
    # Mortar lines
    for y in range(0, 64, 16):
        d.rectangle([0, y, 63, y+1], fill=(100, 95, 85))

def dark_wall(d, t):
    """Building exterior wall."""
    d.rectangle([0, 0, 63, 63], fill=(70, 60, 55))
    d.rectangle([2, 2, 62, 62], fill=(80, 70, 65))
    # Window
    d.rectangle([16, 16, 48, 40], fill=(40, 40, 60))
    d.rectangle([18, 18, 46, 38], fill=(60, 80, 120))
    # Window cross
    d.rectangle([31, 16, 33, 40], fill=(70, 60, 55))
    d.rectangle([16, 27, 48, 29], fill=(70, 60, 55))

def roof(d, t):
    d.rectangle([0, 0, 63, 63], fill=(160, 60, 40))
    # Shingle rows
    for y in range(0, 64, 8):
        offset = 8 if (y // 8) % 2 else 0
        for x in range(-8, 72, 16):
            bx = x + offset
            d.rectangle([bx, y, bx+14, y+6], fill=(170, 70, 50))
            d.rectangle([bx+1, y+1, bx+13, y+5], fill=(150, 55, 35))

def roof_top(d, t):
    """Roof peak / ridge."""
    d.rectangle([0, 0, 63, 63], fill=(0, 0, 0, 0))
    # Triangular roof top
    for i in range(32):
        y = 63 - i * 2
        if y < 0:
            break
        d.rectangle([i, y, 63 - i, 63], fill=(160, 60, 40))
    d.rectangle([0, 60, 63, 63], fill=(170, 70, 50))

def water(d, t):
    d.rectangle([0, 0, 63, 63], fill=(40, 80, 180))
    # Wave highlights
    for y in range(4, 60, 12):
        for x in range(0, 64, 16):
            offset = 6 if (y // 12) % 2 else 0
            d.rectangle([x + offset, y, x + offset + 8, y + 2], fill=(60, 100, 200))
    for y in range(10, 60, 12):
        for x in range(4, 64, 20):
            d.rectangle([x, y, x + 6, y + 1], fill=(80, 120, 220))

def counter(d, t):
    d.rectangle([0, 0, 63, 63], fill=(140, 100, 60))
    # Counter top surface
    d.rectangle([0, 0, 63, 8], fill=(160, 120, 70))
    d.rectangle([0, 8, 63, 12], fill=(120, 85, 50))
    # Front panel
    d.rectangle([4, 14, 60, 60], fill=(130, 92, 55))
    d.rectangle([8, 18, 56, 56], fill=(120, 85, 50))
    # Shelf line
    d.rectangle([4, 36, 60, 38], fill=(140, 100, 60))

def fence(d, t):
    d.rectangle([0, 0, 63, 63], fill=(0, 0, 0, 0))
    # Posts
    d.rectangle([4, 8, 12, 56], fill=(140, 100, 50))
    d.rectangle([52, 8, 60, 56], fill=(140, 100, 50))
    # Rails
    d.rectangle([0, 16, 63, 22], fill=(160, 120, 60))
    d.rectangle([0, 40, 63, 46], fill=(160, 120, 60))
    # Post caps
    d.rectangle([2, 4, 14, 10], fill=(160, 120, 60))
    d.rectangle([50, 4, 62, 10], fill=(160, 120, 60))

# ── ROW 2: Decorative / special ──────────────────────────────────────────────

def flowers(d, t):
    """Grass with flowers (walkable)."""
    d.rectangle([0, 0, 63, 63], fill=(60, 140, 50))
    for x in range(4, 60, 8):
        for y in range(4, 60, 12):
            d.rectangle([x, y, x+2, y+4], fill=(50, 120, 40))
    # Flowers
    colors = [(220, 60, 60), (220, 200, 40), (200, 60, 200), (60, 60, 220)]
    positions = [(10, 10), (40, 8), (20, 40), (50, 44), (8, 52), (44, 28)]
    for i, (x, y) in enumerate(positions):
        c = colors[i % len(colors)]
        d.rectangle([x, y, x+4, y+4], fill=c)
        d.rectangle([x+1, y-1, x+3, y+5], fill=c)
        d.rectangle([x-1, y+1, x+5, y+3], fill=c)

def well(d, t):
    """Town well (impassable)."""
    d.rectangle([0, 0, 63, 63], fill=(60, 140, 50))
    # Well base
    d.rectangle([12, 20, 52, 56], fill=(130, 125, 115))
    d.rectangle([16, 24, 48, 52], fill=(40, 60, 140))
    # Well rim
    d.rectangle([10, 18, 54, 22], fill=(150, 145, 135))
    # Posts
    d.rectangle([14, 4, 20, 20], fill=(120, 80, 40))
    d.rectangle([44, 4, 50, 20], fill=(120, 80, 40))
    # Roof
    d.rectangle([10, 2, 54, 8], fill=(160, 60, 40))

def sign_post(d, t):
    """Sign post (impassable)."""
    d.rectangle([0, 0, 63, 63], fill=(60, 140, 50))
    # Post
    d.rectangle([28, 24, 36, 60], fill=(120, 80, 40))
    # Sign board
    d.rectangle([10, 8, 54, 28], fill=(160, 120, 60))
    d.rectangle([12, 10, 52, 26], fill=(140, 100, 50))

def stairs_up(d, t):
    """Stairs going up (walkable)."""
    d.rectangle([0, 0, 63, 63], fill=(80, 75, 90))
    for i in range(4):
        y = 48 - i * 16
        shade = 90 + i * 10
        d.rectangle([0, y, 63, y + 14], fill=(shade, shade - 5, shade + 10))
        d.rectangle([0, y, 63, y + 2], fill=(shade + 20, shade + 15, shade + 25))

def black(d, t):
    """Pure black (void/unused)."""
    d.rectangle([0, 0, 63, 63], fill=(0, 0, 0))

def water_edge_top(d, t):
    """Water edge - grass on top, water below."""
    d.rectangle([0, 0, 63, 63], fill=(40, 80, 180))
    d.rectangle([0, 0, 63, 20], fill=(60, 140, 50))
    d.rectangle([0, 20, 63, 26], fill=(50, 110, 45))
    # Wave highlights in water
    for x in range(4, 60, 16):
        d.rectangle([x, 36, x + 8, 38], fill=(60, 100, 200))

# ── ROW 3: More tiles ────────────────────────────────────────────────────────

def carpet_red(d, t):
    """Red carpet (walkable, castle interior)."""
    d.rectangle([0, 0, 63, 63], fill=(160, 30, 30))
    d.rectangle([4, 4, 60, 60], fill=(180, 40, 40))
    # Border pattern
    d.rectangle([0, 0, 63, 3], fill=(200, 160, 40))
    d.rectangle([0, 60, 63, 63], fill=(200, 160, 40))
    d.rectangle([0, 0, 3, 63], fill=(200, 160, 40))
    d.rectangle([60, 0, 63, 63], fill=(200, 160, 40))

def throne(d, t):
    """Throne (impassable)."""
    d.rectangle([0, 0, 63, 63], fill=(80, 75, 90))
    # Throne back
    d.rectangle([12, 4, 52, 36], fill=(200, 160, 40))
    d.rectangle([16, 8, 48, 32], fill=(160, 30, 30))
    # Throne seat
    d.rectangle([8, 36, 56, 52], fill=(200, 160, 40))
    d.rectangle([12, 40, 52, 48], fill=(180, 40, 40))
    # Armrests
    d.rectangle([8, 24, 16, 52], fill=(200, 160, 40))
    d.rectangle([48, 24, 56, 52], fill=(200, 160, 40))
    # Legs
    d.rectangle([12, 52, 20, 60], fill=(200, 160, 40))
    d.rectangle([44, 52, 52, 60], fill=(200, 160, 40))

def pillar(d, t):
    """Stone pillar (impassable)."""
    d.rectangle([0, 0, 63, 63], fill=(0, 0, 0, 0))
    # Pillar shaft
    d.rectangle([18, 8, 46, 56], fill=(170, 165, 155))
    d.rectangle([22, 8, 42, 56], fill=(180, 175, 165))
    # Capital
    d.rectangle([14, 4, 50, 12], fill=(180, 175, 165))
    d.rectangle([12, 2, 52, 6], fill=(190, 185, 175))
    # Base
    d.rectangle([14, 52, 50, 60], fill=(180, 175, 165))
    d.rectangle([12, 58, 52, 62], fill=(190, 185, 175))

def chest(d, t):
    """Treasure chest (impassable)."""
    d.rectangle([0, 0, 63, 63], fill=(60, 140, 50))
    # Chest body
    d.rectangle([12, 24, 52, 52], fill=(140, 90, 30))
    d.rectangle([14, 26, 50, 50], fill=(160, 110, 40))
    # Chest lid
    d.rectangle([10, 16, 54, 28], fill=(160, 110, 40))
    d.rectangle([12, 18, 52, 26], fill=(140, 90, 30))
    # Lock
    d.rectangle([28, 32, 36, 42], fill=(200, 180, 60))
    d.rectangle([30, 34, 34, 40], fill=(180, 160, 40))
    # Chest top curve
    d.rectangle([10, 14, 54, 18], fill=(120, 75, 25))

def grass_dark(d, t):
    """Darker grass for variation."""
    d.rectangle([0, 0, 63, 63], fill=(45, 110, 40))
    for x in range(4, 60, 8):
        for y in range(4, 60, 12):
            d.rectangle([x, y, x+2, y+4], fill=(40, 95, 35))
    for x in range(8, 60, 12):
        for y in range(10, 60, 14):
            d.rectangle([x, y, x+2, y+3], fill=(55, 125, 45))

def tree(d, t):
    """Tree (impassable)."""
    d.rectangle([0, 0, 63, 63], fill=(60, 140, 50))
    # Trunk
    d.rectangle([26, 40, 38, 60], fill=(100, 65, 30))
    d.rectangle([28, 42, 36, 58], fill=(110, 75, 35))
    # Foliage
    d.rectangle([8, 8, 56, 44], fill=(30, 110, 30))
    d.rectangle([12, 4, 52, 40], fill=(40, 130, 40))
    d.rectangle([16, 2, 48, 12], fill=(35, 120, 35))
    d.rectangle([20, 12, 44, 36], fill=(50, 140, 45))

def bush(d, t):
    """Bush (impassable)."""
    d.rectangle([0, 0, 63, 63], fill=(60, 140, 50))
    d.rectangle([6, 20, 58, 56], fill=(30, 110, 30))
    d.rectangle([10, 16, 54, 52], fill=(40, 130, 40))
    d.rectangle([14, 14, 50, 24], fill=(45, 135, 42))
    d.rectangle([18, 24, 46, 44], fill=(50, 140, 48))

def wall_top(d, t):
    """Wall top edge - shows top of a wall."""
    d.rectangle([0, 0, 63, 63], fill=(70, 60, 55))
    # Crenellation
    d.rectangle([0, 0, 63, 8], fill=(140, 135, 125))
    d.rectangle([0, 8, 63, 16], fill=(130, 125, 115))
    for x in range(0, 64, 16):
        d.rectangle([x+2, 0, x+6, 8], fill=(0, 0, 0, 0))

# ── BUILD ATLAS ──────────────────────────────────────────────────────────────

# Row 0: Walkable ground
draw_tile(0, 0, grass)          # 0,0
draw_tile(1, 0, stone_path)     # 1,0
draw_tile(2, 0, wood_floor)     # 2,0
draw_tile(3, 0, sand)           # 3,0
draw_tile(4, 0, door)           # 4,0
draw_tile(5, 0, dark_floor)     # 5,0
draw_tile(6, 0, flowers)        # 6,0
draw_tile(7, 0, grass_dark)     # 7,0

# Row 1: Walls / impassable
draw_tile(0, 1, stone_wall)     # 0,1
draw_tile(1, 1, dark_wall)      # 1,1
draw_tile(2, 1, roof)           # 2,1
draw_tile(3, 1, water)          # 3,1
draw_tile(4, 1, counter)        # 4,1
draw_tile(5, 1, fence)          # 5,1
draw_tile(6, 1, roof_top)       # 6,1
draw_tile(7, 1, wall_top)       # 7,1

# Row 2: Decorative / special
draw_tile(0, 2, well)           # 0,2
draw_tile(1, 2, sign_post)      # 1,2
draw_tile(2, 2, stairs_up)      # 2,2
draw_tile(3, 2, water_edge_top) # 3,2
draw_tile(4, 2, black)          # 4,2
draw_tile(5, 2, tree)           # 5,2
draw_tile(6, 2, bush)           # 6,2

# Row 3: Castle / interior
draw_tile(0, 3, carpet_red)     # 0,3
draw_tile(1, 3, throne)         # 1,3
draw_tile(2, 3, pillar)         # 2,3
draw_tile(3, 3, chest)          # 3,3

atlas.save("c:/dev/games-godot/final-fantasy/tilesets/cornelia_tiles.png")
print("Tileset atlas saved: 512x256 (8x4 tiles)")
