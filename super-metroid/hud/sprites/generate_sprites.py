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
# MISSILE ICON (16x16) — for HUD weapon slot
# ====================
s = ""
# Missile body
s += r(2, 5, 10, 6, "#D04040")
s += r(4, 4, 6, 8, "#E05050")
s += r(6, 6, 4, 4, "#F07070")
# Nose cone
s += r(10, 6, 4, 4, "#C03030")
s += r(13, 7, 2, 2, "#A02020")
# Tail fins
s += r(1, 4, 3, 2, "#B03030")
s += r(1, 10, 3, 2, "#B03030")
# Exhaust
s += r(0, 7, 2, 2, "#F0A020")
save("icon_missile.svg", make_svg(16, 16, s))

# ====================
# BEAM ICON (16x16) — for HUD weapon slot (default weapon)
# ====================
s = ""
s += r(2, 6, 12, 4, "#E8C030")
s += r(4, 5, 8, 6, "#F0D848")
s += r(6, 7, 6, 2, "#FFFFF0")
s += r(0, 7, 3, 2, "#D8A020")
s += r(13, 6, 3, 4, "#F8E860")
save("icon_beam.svg", make_svg(16, 16, s))

# ====================
# ENERGY TANK PIP FULL (8x8) — pink filled square
# ====================
s = ""
s += r(0, 0, 8, 8, "#404040")
s += r(1, 1, 6, 6, "#E04888")
s += r(2, 2, 4, 4, "#F068A8")
s += r(2, 2, 2, 2, "#F8A0C8")
save("tank_pip_full.svg", make_svg(8, 8, s))

# ====================
# ENERGY TANK PIP EMPTY (8x8) — gray empty square
# ====================
s = ""
s += r(0, 0, 8, 8, "#404040")
s += r(1, 1, 6, 6, "#282828")
s += r(2, 2, 2, 2, "#383838")
save("tank_pip_empty.svg", make_svg(8, 8, s))

print("HUD sprites generated!")
