import os

OUTPUT_DIR = os.path.dirname(os.path.abspath(__file__))
FW = 64
FH = 96


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


# Shared body parts (duplicated from generate_sprites.py for standalone use)
def helmet(ox, oy):
    return (
        r(ox+22, oy+3, 20, 4, "#D04040") +
        r(ox+20, oy+7, 24, 12, "#C83838") +
        r(ox+22, oy+5, 20, 2, "#C83838") +
        r(ox+23, oy+4, 18, 1, "#C83838") +
        r(ox+24, oy+5, 14, 2, "#E05858") +
        r(ox+34, oy+10, 8, 4, "#20D820") +
        r(ox+35, oy+9, 6, 1, "#30E830") +
        r(ox+35, oy+14, 6, 1, "#18B018") +
        r(ox+35, oy+10, 2, 2, "#60FF60") +
        r(ox+22, oy+19, 20, 3, "#B03030")
    )


def torso_and_shoulders(ox, oy):
    return (
        r(ox+26, oy+22, 12, 3, "#D8A820") +
        r(ox+6, oy+24, 16, 6, "#D8A820") +
        r(ox+4, oy+25, 4, 4, "#C89818") +
        r(ox+8, oy+23, 12, 2, "#E8B828") +
        r(ox+6, oy+30, 14, 2, "#C89818") +
        r(ox+8, oy+26, 12, 1, "#E8C030") +
        r(ox+42, oy+24, 16, 6, "#D8A820") +
        r(ox+56, oy+25, 4, 4, "#C89818") +
        r(ox+44, oy+23, 12, 2, "#E8B828") +
        r(ox+44, oy+30, 14, 2, "#C89818") +
        r(ox+44, oy+26, 12, 1, "#E8C030") +
        r(ox+20, oy+25, 24, 14, "#D8A820") +
        r(ox+24, oy+27, 16, 8, "#E8C030") +
        r(ox+26, oy+29, 12, 4, "#F0D040") +
        r(ox+27, oy+30, 10, 1, "#D8A820") +
        r(ox+27, oy+32, 10, 1, "#D8A820")
    )


def left_arm(ox, oy, dy=0):
    return (
        r(ox+8, oy+30+dy, 10, 8, "#D8A820") +
        r(ox+6, oy+34+dy, 8, 6, "#D8A820") +
        r(ox+6, oy+38+dy, 6, 4, "#C89818") +
        r(ox+10, oy+31+dy, 4, 4, "#E8C030")
    )


def waist_belt(ox, oy):
    return (
        r(ox+22, oy+39, 20, 4, "#D0A020") +
        r(ox+21, oy+43, 22, 4, "#C83838") +
        r(ox+28, oy+43, 8, 4, "#D84848") +
        r(ox+30, oy+44, 4, 2, "#E86060")
    )


def draw_leg(ox, oy, lx, ly=0):
    return (
        r(ox+lx, oy+47+ly, 10, 10, "#D8A820") +
        r(ox+lx+1, oy+48+ly, 8, 8, "#D0A020") +
        r(ox+lx+2, oy+49+ly, 4, 4, "#E0B828") +
        r(ox+lx, oy+57+ly, 10, 4, "#C83838") +
        r(ox+lx+1, oy+58+ly, 8, 2, "#D84848") +
        r(ox+lx, oy+61+ly, 10, 12, "#D8A820") +
        r(ox+lx+1, oy+62+ly, 8, 10, "#D0A020") +
        r(ox+lx+2, oy+63+ly, 3, 6, "#E0B828")
    )


def left_boot(ox, oy, bx, ly=0):
    return (
        r(ox+bx, oy+73+ly, 14, 8, "#C83838") +
        r(ox+bx-1, oy+75+ly, 15, 6, "#B03030") +
        r(ox+bx+1, oy+74+ly, 10, 4, "#D84848") +
        r(ox+bx-2, oy+81+ly, 16, 4, "#903030") +
        r(ox+bx-1, oy+85+ly, 14, 3, "#782828") +
        r(ox+bx-2, oy+79+ly, 3, 2, "#B03030")
    )


def right_boot(ox, oy, bx, ly=0):
    return (
        r(ox+bx, oy+73+ly, 14, 8, "#C83838") +
        r(ox+bx, oy+75+ly, 15, 6, "#B03030") +
        r(ox+bx+3, oy+74+ly, 10, 4, "#D84848") +
        r(ox+bx, oy+81+ly, 16, 4, "#903030") +
        r(ox+bx+1, oy+85+ly, 14, 3, "#782828") +
        r(ox+bx+13, oy+79+ly, 3, 2, "#B03030")
    )


def lower_body(ox, oy, ll=21, rl=33, ll_dy=0, rl_dy=0):
    return (
        waist_belt(ox, oy) +
        draw_leg(ox, oy, ll, ll_dy) +
        draw_leg(ox, oy, rl, rl_dy) +
        left_boot(ox, oy, ll - 3, ll_dy) +
        right_boot(ox, oy, rl - 1, rl_dy)
    )


# ====================
# AIM UP (1 frame) — cannon points straight up from right shoulder
# ====================
def draw_aim_up(ox, oy):
    s = ""
    s += helmet(ox, oy)
    # Cannon pointing up — positioned above right shoulder
    s += r(ox+46, oy+14, 10, 6, "#28A070")
    s += r(ox+44, oy+6, 14, 10, "#209060")
    s += r(ox+48, oy+0, 6, 8, "#186848")
    s += r(ox+46, oy+2, 10, 4, "#187050")
    s += r(ox+50, oy+8, 2, 6, "#40C888")
    # Right shoulder (no horizontal cannon)
    s += r(ox+42, oy+24, 16, 6, "#D8A820")
    s += r(ox+56, oy+25, 4, 4, "#C89818")
    s += r(ox+44, oy+23, 12, 2, "#E8B828")
    s += r(ox+44, oy+30, 14, 2, "#C89818")
    # Torso (without right shoulder cannon overlap)
    s += r(ox+26, oy+22, 12, 3, "#D8A820")
    s += r(ox+6, oy+24, 16, 6, "#D8A820")
    s += r(ox+4, oy+25, 4, 4, "#C89818")
    s += r(ox+8, oy+23, 12, 2, "#E8B828")
    s += r(ox+6, oy+30, 14, 2, "#C89818")
    s += r(ox+8, oy+26, 12, 1, "#E8C030")
    s += r(ox+20, oy+25, 24, 14, "#D8A820")
    s += r(ox+24, oy+27, 16, 8, "#E8C030")
    s += r(ox+26, oy+29, 12, 4, "#F0D040")
    s += left_arm(ox, oy)
    s += lower_body(ox, oy)
    return s

save("samus_aim_up.svg", make_svg(FW, FH, draw_aim_up(0, 0)))

# ====================
# AIM DIAGONAL UP (1 frame) — cannon at ~45 degrees up-right
# ====================
def draw_aim_diag_up(ox, oy):
    s = ""
    s += helmet(ox, oy)
    # Cannon pointing diagonal up-right
    s += r(ox+50, oy+18, 8, 6, "#28A070")
    s += r(ox+52, oy+12, 10, 8, "#209060")
    s += r(ox+56, oy+6, 6, 8, "#186848")
    s += r(ox+54, oy+8, 8, 4, "#187050")
    s += r(ox+56, oy+14, 2, 4, "#40C888")
    # Right shoulder
    s += r(ox+42, oy+24, 16, 6, "#D8A820")
    s += r(ox+56, oy+25, 4, 4, "#C89818")
    s += r(ox+44, oy+23, 12, 2, "#E8B828")
    s += r(ox+44, oy+30, 14, 2, "#C89818")
    # Torso
    s += r(ox+26, oy+22, 12, 3, "#D8A820")
    s += r(ox+6, oy+24, 16, 6, "#D8A820")
    s += r(ox+4, oy+25, 4, 4, "#C89818")
    s += r(ox+8, oy+23, 12, 2, "#E8B828")
    s += r(ox+6, oy+30, 14, 2, "#C89818")
    s += r(ox+8, oy+26, 12, 1, "#E8C030")
    s += r(ox+20, oy+25, 24, 14, "#D8A820")
    s += r(ox+24, oy+27, 16, 8, "#E8C030")
    s += r(ox+26, oy+29, 12, 4, "#F0D040")
    s += left_arm(ox, oy)
    s += lower_body(ox, oy)
    return s

save("samus_aim_diag_up.svg", make_svg(FW, FH, draw_aim_diag_up(0, 0)))

# ====================
# HURT (1 frame) — knockback pose, arms spread, slight backward lean
# ====================
def draw_hurt(ox, oy):
    s = ""
    # Helmet tilted slightly
    s += r(ox+20, oy+5, 20, 4, "#D04040")
    s += r(ox+18, oy+9, 24, 12, "#C83838")
    s += r(ox+20, oy+7, 20, 2, "#C83838")
    s += r(ox+21, oy+6, 18, 1, "#C83838")
    s += r(ox+22, oy+7, 14, 2, "#E05858")
    s += r(ox+32, oy+12, 8, 4, "#20D820")
    s += r(ox+33, oy+11, 6, 1, "#30E830")
    s += r(ox+33, oy+16, 6, 1, "#18B018")
    s += r(ox+33, oy+12, 2, 2, "#60FF60")
    s += r(ox+20, oy+21, 20, 3, "#B03030")
    # Torso leaning back
    s += r(ox+24, oy+24, 12, 3, "#D8A820")
    s += r(ox+4, oy+26, 16, 5, "#D8A820")
    s += r(ox+2, oy+27, 4, 3, "#C89818")
    s += r(ox+40, oy+26, 16, 5, "#D8A820")
    s += r(ox+54, oy+27, 4, 3, "#C89818")
    s += r(ox+18, oy+27, 24, 12, "#D8A820")
    s += r(ox+22, oy+29, 16, 6, "#E8C030")
    # Arms spread out
    s += r(ox+54, oy+28, 8, 6, "#209060")
    s += r(ox+58, oy+26, 4, 4, "#186848")
    s += r(ox+2, oy+30, 8, 6, "#D8A820")
    s += r(ox+4, oy+32, 4, 4, "#C89818")
    # Belt
    s += r(ox+20, oy+39, 20, 4, "#D0A020")
    s += r(ox+19, oy+43, 22, 4, "#C83838")
    s += r(ox+26, oy+43, 8, 4, "#D84848")
    # Legs spread for knockback stance
    s += draw_leg(ox, oy, 16, 0)
    s += draw_leg(ox, oy, 36, 0)
    s += left_boot(ox, oy, 13, 0)
    s += right_boot(ox, oy, 35, 0)
    return s

save("samus_hurt.svg", make_svg(FW, FH, draw_hurt(0, 0)))

print("Combat sprites generated!")
