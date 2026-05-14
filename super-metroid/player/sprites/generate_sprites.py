import os

OUTPUT_DIR = os.path.dirname(os.path.abspath(__file__))
FW = 64
FH = 96
MB = 32


def r(x, y, w, h, fill):
    return f'  <rect x="{x}" y="{y}" width="{w}" height="{h}" fill="{fill}"/>\n'


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


def arm_cannon(ox, oy, dy=0):
    return (
        r(ox+52, oy+28+dy, 4, 10, "#28A070") +
        r(ox+56, oy+26+dy, 6, 14, "#209060") +
        r(ox+54, oy+30+dy, 2, 6, "#38B880") +
        r(ox+58, oy+25+dy, 4, 4, "#186848") +
        r(ox+58, oy+39+dy, 4, 2, "#186848") +
        r(ox+60, oy+26+dy, 3, 12, "#187050") +
        r(ox+57, oy+28+dy, 1, 8, "#40C888")
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


def standing_samus(ox, oy, ll=21, rl=33, arm_dy=0, cannon_dy=0, ll_dy=0, rl_dy=0):
    return (
        helmet(ox, oy) +
        torso_and_shoulders(ox, oy) +
        arm_cannon(ox, oy, cannon_dy) +
        left_arm(ox, oy, arm_dy) +
        waist_belt(ox, oy) +
        draw_leg(ox, oy, ll, ll_dy) +
        draw_leg(ox, oy, rl, rl_dy) +
        left_boot(ox, oy, ll - 3, ll_dy) +
        right_boot(ox, oy, rl - 1, rl_dy)
    )


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
# WALK CYCLE (6 frames)
# ====================
# (left_leg_x, right_leg_x, arm_dy, cannon_dy, left_leg_dy, right_leg_dy)
walk_frames = [
    (17, 37, 2, 1, 0, 0),
    (19, 35, 1, 0, -1, 1),
    (21, 33, 0, 0, 0, 0),
    (25, 29, -2, -1, 0, 0),
    (23, 31, -1, 0, 1, -1),
    (21, 33, 0, 0, 0, 0),
]
s = ""
for i, (ll, rl, ad, cd, lld, rld) in enumerate(walk_frames):
    s += standing_samus(i * FW, 0, ll, rl, ad, cd, lld, rld)
save("samus_walk.svg", make_svg(FW * 6, FH, s))

# ====================
# RUN CYCLE (6 frames)
# ====================
run_frames = [
    (15, 39, 3, 1, 0, -2),
    (18, 36, 1, 0, -1, -1),
    (21, 33, 0, 0, 0, 0),
    (25, 29, -3, -1, -2, 0),
    (23, 31, -1, 0, -1, 1),
    (21, 33, 0, 0, 0, 0),
]
s = ""
for i, (ll, rl, ad, cd, lld, rld) in enumerate(run_frames):
    s += standing_samus(i * FW, 0, ll, rl, ad, cd, lld, rld)
save("samus_run.svg", make_svg(FW * 6, FH, s))

# ====================
# CROUCH (1 frame)
# ====================
def draw_crouch(ox, oy):
    dy = 16
    s = ""
    s += r(ox+22, oy+dy+3, 20, 4, "#D04040")
    s += r(ox+20, oy+dy+7, 24, 12, "#C83838")
    s += r(ox+22, oy+dy+5, 20, 2, "#C83838")
    s += r(ox+23, oy+dy+4, 18, 1, "#C83838")
    s += r(ox+24, oy+dy+5, 14, 2, "#E05858")
    s += r(ox+34, oy+dy+10, 8, 4, "#20D820")
    s += r(ox+35, oy+dy+9, 6, 1, "#30E830")
    s += r(ox+35, oy+dy+14, 6, 1, "#18B018")
    s += r(ox+35, oy+dy+10, 2, 2, "#60FF60")
    s += r(ox+22, oy+dy+19, 20, 3, "#B03030")
    s += r(ox+26, oy+dy+22, 12, 2, "#D8A820")
    s += r(ox+8, oy+dy+24, 14, 5, "#D8A820")
    s += r(ox+6, oy+dy+25, 4, 3, "#C89818")
    s += r(ox+10, oy+dy+23, 10, 2, "#E8B828")
    s += r(ox+42, oy+dy+24, 14, 5, "#D8A820")
    s += r(ox+54, oy+dy+25, 4, 3, "#C89818")
    s += r(ox+44, oy+dy+23, 10, 2, "#E8B828")
    s += r(ox+20, oy+dy+24, 24, 12, "#D8A820")
    s += r(ox+24, oy+dy+26, 16, 6, "#E8C030")
    s += r(ox+26, oy+dy+28, 12, 3, "#F0D040")
    s += r(ox+52, oy+dy+26, 4, 8, "#28A070")
    s += r(ox+56, oy+dy+24, 6, 12, "#209060")
    s += r(ox+58, oy+dy+23, 4, 4, "#186848")
    s += r(ox+60, oy+dy+24, 3, 10, "#187050")
    s += r(ox+57, oy+dy+26, 1, 6, "#40C888")
    s += r(ox+8, oy+dy+29, 8, 6, "#D8A820")
    s += r(ox+6, oy+dy+33, 6, 4, "#C89818")
    s += r(ox+22, oy+dy+36, 20, 3, "#D0A020")
    s += r(ox+21, oy+dy+39, 22, 3, "#C83838")
    s += r(ox+28, oy+dy+39, 8, 3, "#D84848")
    s += r(ox+14, oy+dy+42, 14, 8, "#D8A820")
    s += r(ox+36, oy+dy+42, 14, 8, "#D8A820")
    s += r(ox+15, oy+dy+43, 10, 6, "#D0A020")
    s += r(ox+37, oy+dy+43, 10, 6, "#D0A020")
    s += r(ox+12, oy+dy+48, 14, 4, "#C83838")
    s += r(ox+36, oy+dy+48, 14, 4, "#C83838")
    s += r(ox+16, oy+dy+52, 10, 6, "#D8A820")
    s += r(ox+38, oy+dy+52, 10, 6, "#D8A820")
    s += r(ox+12, oy+dy+56, 16, 6, "#C83838")
    s += r(ox+36, oy+dy+56, 16, 6, "#C83838")
    s += r(ox+14, oy+dy+57, 12, 3, "#D84848")
    s += r(ox+38, oy+dy+57, 12, 3, "#D84848")
    s += r(ox+12, oy+dy+62, 16, 3, "#903030")
    s += r(ox+36, oy+dy+62, 16, 3, "#903030")
    return s

save("samus_crouch.svg", make_svg(FW, FH, draw_crouch(0, 0)))

# ====================
# FALL (1 frame)
# ====================
save("samus_fall.svg", make_svg(FW, FH,
     standing_samus(0, 0, ll=19, rl=35, arm_dy=-2, cannon_dy=-1)))

# ====================
# SPIN JUMP (4 frames)
# ====================
def draw_spin(ox, oy, rot):
    s = ""
    if rot == 0:
        s += r(ox+20, oy+26, 24, 8, "#C83838")
        s += r(ox+22, oy+24, 20, 4, "#D04040")
        s += r(ox+30, oy+28, 6, 4, "#20D820")
        s += r(ox+31, oy+29, 2, 2, "#60FF60")
        s += r(ox+14, oy+34, 36, 6, "#D8A820")
        s += r(ox+12, oy+38, 40, 10, "#D8A820")
        s += r(ox+16, oy+36, 28, 10, "#E8C030")
        s += r(ox+14, oy+48, 36, 8, "#D8A820")
        s += r(ox+16, oy+50, 28, 4, "#D0A020")
        s += r(ox+12, oy+56, 40, 6, "#C83838")
        s += r(ox+16, oy+57, 32, 3, "#D84848")
        s += r(ox+14, oy+62, 36, 4, "#903030")
    elif rot == 1:
        s += r(ox+42, oy+32, 12, 24, "#C83838")
        s += r(ox+46, oy+38, 6, 8, "#20D820")
        s += r(ox+47, oy+39, 2, 4, "#60FF60")
        s += r(ox+18, oy+30, 26, 8, "#D8A820")
        s += r(ox+16, oy+36, 28, 16, "#D8A820")
        s += r(ox+20, oy+34, 20, 16, "#E8C030")
        s += r(ox+18, oy+52, 26, 8, "#D8A820")
        s += r(ox+8, oy+34, 10, 20, "#C83838")
        s += r(ox+10, oy+38, 6, 12, "#D84848")
        s += r(ox+4, oy+36, 6, 16, "#903030")
    elif rot == 2:
        s += r(ox+14, oy+22, 36, 4, "#903030")
        s += r(ox+12, oy+26, 40, 6, "#C83838")
        s += r(ox+16, oy+27, 32, 3, "#D84848")
        s += r(ox+14, oy+32, 36, 8, "#D8A820")
        s += r(ox+16, oy+34, 28, 4, "#D0A020")
        s += r(ox+12, oy+40, 40, 10, "#D8A820")
        s += r(ox+16, oy+42, 28, 10, "#E8C030")
        s += r(ox+14, oy+48, 36, 6, "#D8A820")
        s += r(ox+20, oy+54, 24, 8, "#C83838")
        s += r(ox+22, oy+60, 20, 4, "#D04040")
        s += r(ox+28, oy+56, 6, 4, "#20D820")
        s += r(ox+29, oy+57, 2, 2, "#60FF60")
    elif rot == 3:
        s += r(ox+46, oy+34, 10, 20, "#C83838")
        s += r(ox+48, oy+38, 6, 12, "#D84848")
        s += r(ox+54, oy+36, 6, 16, "#903030")
        s += r(ox+20, oy+30, 26, 8, "#D8A820")
        s += r(ox+20, oy+36, 28, 16, "#D8A820")
        s += r(ox+24, oy+34, 20, 16, "#E8C030")
        s += r(ox+20, oy+52, 26, 8, "#D8A820")
        s += r(ox+10, oy+32, 12, 24, "#C83838")
        s += r(ox+12, oy+38, 6, 8, "#20D820")
        s += r(ox+13, oy+39, 2, 4, "#60FF60")
    return s

s = ""
for i in range(4):
    s += draw_spin(i * FW, 0, i)
save("samus_spin_jump.svg", make_svg(FW * 4, FH, s))

# ====================
# MORPH BALL (4 frames, 32x32 each)
# ====================
def draw_morph(ox, oy, rot):
    s = ""
    s += r(ox+10, oy+2, 12, 2, "#C89818")
    s += r(ox+8, oy+4, 16, 2, "#D8A820")
    s += r(ox+6, oy+6, 20, 4, "#D8A820")
    s += r(ox+4, oy+10, 24, 12, "#D8A820")
    s += r(ox+6, oy+22, 20, 4, "#D8A820")
    s += r(ox+8, oy+26, 16, 2, "#D8A820")
    s += r(ox+10, oy+28, 12, 2, "#C89818")
    s += r(ox+12, oy+8, 8, 2, "#E8C030")
    s += r(ox+10, oy+10, 12, 8, "#E8C030")
    s += r(ox+12, oy+18, 8, 4, "#E8C030")
    s += r(ox+14, oy+14, 4, 4, "#F0D040")
    s += r(ox+14, oy+2, 4, 2, "#B03030")
    s += r(ox+14, oy+28, 4, 2, "#B03030")
    s += r(ox+2, oy+14, 2, 4, "#B03030")
    s += r(ox+28, oy+14, 2, 4, "#B03030")
    marks = [
        (ox+13, oy+4, 6, 4),
        (ox+22, oy+13, 4, 6),
        (ox+13, oy+24, 6, 4),
        (ox+6, oy+13, 4, 6),
    ]
    mx, my, mw, mh = marks[rot]
    s += r(mx, my, mw, mh, "#C83838")
    return s

s = ""
for i in range(4):
    s += draw_morph(i * MB, 0, i)
save("samus_morph_ball.svg", make_svg(MB * 4, MB, s))

print("All SVGs generated!")
