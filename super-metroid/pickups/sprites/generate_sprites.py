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


def orb(ox, oy, outer, inner, highlight):
    return (
        r(ox + 4, oy + 2, 8, 2, outer) +
        r(ox + 2, oy + 4, 12, 8, outer) +
        r(ox + 4, oy + 12, 8, 2, outer) +
        r(ox + 6, oy + 1, 4, 1, outer) +
        r(ox + 6, oy + 14, 4, 1, outer) +
        r(ox + 1, oy + 6, 2, 4, outer) +
        r(ox + 13, oy + 6, 2, 4, outer) +
        r(ox + 5, oy + 4, 6, 8, inner) +
        r(ox + 4, oy + 5, 8, 6, inner) +
        r(ox + 5, oy + 5, 4, 4, highlight) +
        r(ox + 6, oy + 6, 2, 2, "#FFFFFF")
    )


# ====================
# SMALL ENERGY (16x16) — small green orb
# ====================
save("pickup_small_energy.svg", make_svg(16, 16,
     orb(0, 0, "#208820", "#40C040", "#80E880")))

# ====================
# LARGE ENERGY (16x16) — brighter, larger-looking green orb
# ====================
s = orb(0, 0, "#30A030", "#50D850", "#90F890")
s += r(3, 3, 2, 2, "#60E860")
s += r(11, 3, 2, 2, "#60E860")
s += r(3, 11, 2, 2, "#60E860")
s += r(11, 11, 2, 2, "#60E860")
save("pickup_large_energy.svg", make_svg(16, 16, s))

# ====================
# MISSILE PICKUP (16x16) — red orb
# ====================
save("pickup_missile.svg", make_svg(16, 16,
     orb(0, 0, "#A02020", "#D04040", "#F07070")))

# ====================
# SUPER MISSILE PICKUP (16x16) — green with yellow tint
# ====================
save("pickup_super_missile.svg", make_svg(16, 16,
     orb(0, 0, "#308830", "#50B050", "#80E080")))

# ====================
# POWER BOMB PICKUP (16x16) — bright yellow orb
# ====================
save("pickup_power_bomb.svg", make_svg(16, 16,
     orb(0, 0, "#A08820", "#D0B040", "#F0E080")))

print("Pickup sprites generated!")
