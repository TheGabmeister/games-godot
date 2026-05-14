import os

OUTPUT_DIR = os.path.dirname(os.path.abspath(__file__))


def r(x, y, w, h, fill):
    return f'  <rect x="{x}" y="{y}" width="{w}" height="{h}" fill="{fill}"/>\n'


def make_svg(w, h, content):
    return (
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" '
        f'viewBox="0 0 {w} {h}" shape-rendering="crispEdges">\n{content}</svg>\n'
    )


def save(name, content):
    path = os.path.join(OUTPUT_DIR, name)
    with open(path, "w") as f:
        f.write(content)
    print(f"  {name}")


# ====================
# WAVER (4 frames, 32x32 each = 128x32)
# Swooping insect — oval body, small wings that flap
# ====================
s = ""
wing_offsets = [(0, -2), (0, -4), (0, -2), (0, 0)]
for i in range(4):
    ox = i * 32
    wy = wing_offsets[i][1]
    # Body — purple-blue oval
    s += r(ox + 10, 14, 12, 10, "#6040A0")
    s += r(ox + 8, 16, 16, 6, "#7050B0")
    s += r(ox + 12, 12, 8, 2, "#7050B0")
    s += r(ox + 12, 24, 8, 2, "#5030A0")
    # Inner body highlight
    s += r(ox + 12, 16, 8, 4, "#8868C0")
    # Eyes
    s += r(ox + 10, 15, 3, 3, "#FF6060")
    s += r(ox + 19, 15, 3, 3, "#FF6060")
    s += r(ox + 11, 16, 1, 1, "#FFFFFF")
    s += r(ox + 20, 16, 1, 1, "#FFFFFF")
    # Wings — translucent blue, flapping
    s += r(ox + 4, 10 + wy, 8, 6, "#80B0E0")
    s += r(ox + 20, 10 + wy, 8, 6, "#80B0E0")
    s += r(ox + 6, 8 + wy, 4, 4, "#A0D0F0")
    s += r(ox + 22, 8 + wy, 4, 4, "#A0D0F0")
    # Antennae
    s += r(ox + 12, 10, 2, 4, "#5030A0")
    s += r(ox + 18, 10, 2, 4, "#5030A0")
    s += r(ox + 11, 8, 2, 2, "#6040A0")
    s += r(ox + 19, 8, 2, 2, "#6040A0")
save("waver.svg", make_svg(128, 32, s))

# ====================
# ZEELA (4 frames, 32x32 each = 128x32)
# Surface crawler — flat green body with legs that animate
# ====================
s = ""
leg_phases = [
    [(-2, 0), (2, 0), (-2, 0), (2, 0)],
    [(0, 0), (0, 0), (0, 0), (0, 0)],
    [(2, 0), (-2, 0), (2, 0), (-2, 0)],
    [(0, 0), (0, 0), (0, 0), (0, 0)],
]
for i in range(4):
    ox = i * 32
    # Body — green rounded shape
    s += r(ox + 8, 12, 16, 10, "#308030")
    s += r(ox + 6, 14, 20, 6, "#409040")
    s += r(ox + 10, 10, 12, 4, "#409040")
    # Shell highlights
    s += r(ox + 10, 13, 4, 4, "#50A850")
    s += r(ox + 18, 13, 4, 4, "#50A850")
    s += r(ox + 14, 12, 4, 2, "#60B860")
    # Eyes
    s += r(ox + 10, 18, 3, 3, "#E06060")
    s += r(ox + 19, 18, 3, 3, "#E06060")
    s += r(ox + 11, 19, 1, 1, "#FFFFFF")
    s += r(ox + 20, 19, 1, 1, "#FFFFFF")
    # Underbelly
    s += r(ox + 10, 22, 12, 2, "#287028")
    # Legs (4 pairs, alternating extension)
    lp = leg_phases[i]
    for j, (ldx, _ldy) in enumerate(lp):
        lx = ox + 6 + j * 6 + ldx
        s += r(lx, 24, 2, 4, "#287028")
        s += r(lx, 28, 2, 2, "#205820")
save("zeela.svg", make_svg(128, 32, s))

# ====================
# SIDEHOPPER (4 frames, 32x48 each = 128x48)
# Aggressive leaping creature — larger, more threatening
# Frame 0-1: idle (legs bent), Frame 2-3: jumping (legs extended)
# ====================
s = ""
for i in range(4):
    ox = i * 32
    is_jumping = i >= 2
    body_y = 6 if is_jumping else 12
    # Main body — red-orange
    s += r(ox + 8, body_y, 16, 16, "#C05030")
    s += r(ox + 6, body_y + 2, 20, 12, "#D06040")
    s += r(ox + 10, body_y - 2, 12, 4, "#D06040")
    # Body highlights
    s += r(ox + 10, body_y + 2, 8, 6, "#E07850")
    s += r(ox + 12, body_y + 4, 4, 4, "#F09068")
    # Head/mouth
    s += r(ox + 10, body_y + 14, 12, 6, "#B04028")
    s += r(ox + 12, body_y + 16, 8, 4, "#C85838")
    # Teeth
    s += r(ox + 12, body_y + 14, 2, 2, "#FFFFFF")
    s += r(ox + 18, body_y + 14, 2, 2, "#FFFFFF")
    s += r(ox + 15, body_y + 14, 2, 2, "#FFFFFF")
    # Eyes
    s += r(ox + 10, body_y + 4, 4, 4, "#FFFF40")
    s += r(ox + 18, body_y + 4, 4, 4, "#FFFF40")
    s += r(ox + 11, body_y + 5, 2, 2, "#000000")
    s += r(ox + 19, body_y + 5, 2, 2, "#000000")
    if is_jumping:
        # Legs extended downward
        dy = 4 if i == 3 else 0
        s += r(ox + 6, body_y + 18, 4, 14 + dy, "#A04028")
        s += r(ox + 22, body_y + 18, 4, 14 + dy, "#A04028")
        s += r(ox + 7, body_y + 20, 2, 10 + dy, "#B85040")
        s += r(ox + 23, body_y + 20, 2, 10 + dy, "#B85040")
        # Feet
        s += r(ox + 4, body_y + 32 + dy, 6, 4, "#903828")
        s += r(ox + 22, body_y + 32 + dy, 6, 4, "#903828")
    else:
        # Legs bent (crouching)
        crouch = 2 if i == 1 else 0
        s += r(ox + 4, body_y + 18 + crouch, 6, 8, "#A04028")
        s += r(ox + 22, body_y + 18 + crouch, 6, 8, "#A04028")
        s += r(ox + 5, body_y + 20 + crouch, 4, 4, "#B85040")
        s += r(ox + 23, body_y + 20 + crouch, 4, 4, "#B85040")
        # Feet bent under
        s += r(ox + 2, body_y + 26 + crouch, 8, 4, "#903828")
        s += r(ox + 22, body_y + 26 + crouch, 8, 4, "#903828")
        s += r(ox + 6, body_y + 30 + crouch, 6, 3, "#803020")
        s += r(ox + 20, body_y + 30 + crouch, 6, 3, "#803020")
save("sidehopper.svg", make_svg(128, 48, s))

print("Enemy sprites generated!")
