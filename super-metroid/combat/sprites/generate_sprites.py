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
# POWER BEAM (16x8) — small yellow energy bolt
# ====================
s = ""
s += r(2, 1, 12, 6, "#E8C030")
s += r(4, 0, 8, 8, "#F0D848")
s += r(6, 2, 6, 4, "#FFFFF0")
s += r(0, 3, 4, 2, "#D8A020")
s += r(12, 2, 4, 4, "#F8E860")
save("power_beam.svg", make_svg(16, 8, s))

# ====================
# CHARGE BEAM (24x16) — larger brighter bolt with glow
# ====================
s = ""
s += r(2, 2, 20, 12, "#E8C030")
s += r(4, 1, 16, 14, "#F0D848")
s += r(6, 0, 12, 16, "#F8E860")
s += r(8, 4, 10, 8, "#FFFFF0")
s += r(10, 6, 6, 4, "#FFFFFF")
s += r(0, 6, 4, 4, "#D8A020")
s += r(20, 4, 4, 8, "#F8E860")
save("charge_beam.svg", make_svg(24, 16, s))

# ====================
# MISSILE (16x8) — red missile with exhaust
# ====================
s = ""
# Body
s += r(4, 1, 10, 6, "#D04040")
s += r(6, 0, 6, 8, "#E05050")
s += r(8, 2, 4, 4, "#F06060")
# Nose
s += r(12, 2, 4, 4, "#C03030")
s += r(14, 3, 2, 2, "#A02020")
# Exhaust
s += r(0, 2, 4, 4, "#F0A020")
s += r(1, 3, 2, 2, "#F8D060")
save("missile.svg", make_svg(16, 8, s))

# ====================
# BOMB (16x16) — dark sphere with indicator
# ====================
s = ""
s += r(4, 2, 8, 2, "#606060")
s += r(2, 4, 12, 8, "#505050")
s += r(4, 12, 8, 2, "#606060")
s += r(6, 1, 4, 1, "#707070")
s += r(6, 14, 4, 1, "#404040")
s += r(1, 6, 2, 4, "#606060")
s += r(13, 6, 2, 4, "#606060")
s += r(6, 6, 4, 4, "#C83838")
s += r(7, 7, 2, 2, "#E86060")
save("bomb.svg", make_svg(16, 16, s))

# ====================
# BOMB EXPLOSION (4 frames, 32x32 each = 128x32)
# ====================
s = ""
for i in range(4):
    ox = i * 32
    expand = i * 3
    center = 16
    size = 4 + expand * 2
    half = size // 2
    # Outer ring
    s += r(ox + center - half - 2, center - half - 2, size + 4, size + 4, "#F0A020")
    # Inner bright
    s += r(ox + center - half, center - half, size, size, "#F8D060")
    # Core white
    core = max(2, size // 2)
    s += r(ox + center - core // 2, center - core // 2, core, core, "#FFFFF0")
    # Fade outer edges on later frames
    if i >= 2:
        s += r(ox + center - half - 3, center - half - 3, size + 6, 2, "#D08020")
        s += r(ox + center - half - 3, center + half + 1, size + 6, 2, "#D08020")
save("bomb_explosion.svg", make_svg(128, 32, s))

# ====================
# BEAM IMPACT (4 frames, 16x16 each = 64x16)
# ====================
s = ""
for i in range(4):
    ox = i * 16
    # Small cross/star burst that expands
    sz = 2 + i
    s += r(ox + 8 - 1, 8 - sz, 2, sz * 2, "#F8E860")
    s += r(ox + 8 - sz, 8 - 1, sz * 2, 2, "#F8E860")
    if i >= 1:
        s += r(ox + 8 - 1 - i, 8 - 1 - i, 2, 2, "#F0D040")
        s += r(ox + 8 + i - 1, 8 + i - 1, 2, 2, "#F0D040")
        s += r(ox + 8 + i - 1, 8 - 1 - i, 2, 2, "#F0D040")
        s += r(ox + 8 - 1 - i, 8 + i - 1, 2, 2, "#F0D040")
    s += r(ox + 7, 7, 2, 2, "#FFFFFF")
save("beam_impact.svg", make_svg(64, 16, s))

# ====================
# MISSILE EXPLOSION (4 frames, 32x32 each = 128x32)
# ====================
s = ""
for i in range(4):
    ox = i * 32
    expand = i * 4
    center = 16
    size = 6 + expand * 2
    half = size // 2
    # Outer orange
    s += r(ox + center - half - 2, center - half - 2, size + 4, size + 4, "#D04040")
    # Mid ring
    s += r(ox + center - half, center - half, size, size, "#F0A020")
    # Inner bright
    inner = max(4, size // 2)
    s += r(ox + center - inner // 2, center - inner // 2, inner, inner, "#F8D060")
    # Core
    core = max(2, inner // 2)
    s += r(ox + center - core // 2, center - core // 2, core, core, "#FFFFF0")
save("missile_explosion.svg", make_svg(128, 32, s))

# ====================
# CHARGE GLOW (32x32) — overlay that pulses on Samus during charging
# ====================
s = ""
s += r(4, 4, 24, 24, "#F0D040")
s += r(6, 2, 20, 28, "#F0D040")
s += r(2, 6, 28, 20, "#F0D040")
s += r(8, 8, 16, 16, "#F8E860")
s += r(10, 6, 12, 20, "#F8E860")
s += r(6, 10, 20, 12, "#F8E860")
s += r(12, 12, 8, 8, "#FFFFF0")
save("charge_glow.svg", make_svg(32, 32, s))

# ====================
# SCREW ATTACK AURA (64x96) — electric energy overlay around Samus
# ====================
s = ""
# Outer electric arcs — scattered bright pixels
arcs = [
    (8, 10, 4, 2), (48, 8, 4, 2), (4, 30, 2, 4), (58, 28, 2, 4),
    (10, 50, 4, 2), (50, 52, 4, 2), (6, 70, 2, 4), (56, 68, 2, 4),
    (16, 4, 2, 4), (44, 6, 2, 4), (14, 80, 4, 2), (46, 82, 4, 2),
    (2, 44, 4, 2), (58, 46, 4, 2), (20, 90, 2, 4), (42, 88, 2, 4),
]
for ax, ay, aw, ah in arcs:
    s += r(ax, ay, aw, ah, "#60D0F0")
# Inner glow ring
s += r(18, 14, 28, 2, "#40B0E0")
s += r(18, 78, 28, 2, "#40B0E0")
s += r(14, 18, 2, 58, "#40B0E0")
s += r(48, 18, 2, 58, "#40B0E0")
# Bright highlights
s += r(20, 16, 4, 2, "#80F0FF")
s += r(40, 16, 4, 2, "#80F0FF")
s += r(20, 76, 4, 2, "#80F0FF")
s += r(40, 76, 4, 2, "#80F0FF")
save("screw_attack_aura.svg", make_svg(64, 96, s))

# ====================
# ENEMY DEATH BURST (4 frames, 32x32 each = 128x32)
# ====================
s = ""
for i in range(4):
    ox = i * 32
    # Frame 0: small flash, Frame 3: scattered particles
    if i == 0:
        s += r(ox + 12, 12, 8, 8, "#FFFFFF")
        s += r(ox + 10, 14, 12, 4, "#F8E860")
    elif i == 1:
        s += r(ox + 10, 10, 12, 12, "#F8E860")
        s += r(ox + 8, 12, 16, 8, "#F0D040")
        s += r(ox + 12, 8, 8, 16, "#F0D040")
        s += r(ox + 13, 13, 6, 6, "#FFFFFF")
    elif i == 2:
        s += r(ox + 6, 6, 4, 4, "#F0D040")
        s += r(ox + 22, 6, 4, 4, "#F0D040")
        s += r(ox + 6, 22, 4, 4, "#F0D040")
        s += r(ox + 22, 22, 4, 4, "#F0D040")
        s += r(ox + 14, 2, 4, 4, "#F8E860")
        s += r(ox + 14, 26, 4, 4, "#F8E860")
        s += r(ox + 2, 14, 4, 4, "#F8E860")
        s += r(ox + 26, 14, 4, 4, "#F8E860")
    elif i == 3:
        s += r(ox + 4, 4, 2, 2, "#D8A020")
        s += r(ox + 26, 4, 2, 2, "#D8A020")
        s += r(ox + 4, 26, 2, 2, "#D8A020")
        s += r(ox + 26, 26, 2, 2, "#D8A020")
        s += r(ox + 14, 0, 4, 2, "#D8A020")
        s += r(ox + 14, 30, 4, 2, "#D8A020")
        s += r(ox + 0, 14, 2, 4, "#D8A020")
        s += r(ox + 30, 14, 2, 4, "#D8A020")
save("enemy_death.svg", make_svg(128, 32, s))

print("Combat sprites generated!")
