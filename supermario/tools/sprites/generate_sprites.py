from __future__ import annotations

import argparse
import subprocess
from dataclasses import dataclass
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
SVG_DIR = ROOT / "tools" / "sprites" / "svg"
PNG_DIR = ROOT / "sprites"
DEFAULT_INKSCAPE = Path(r"C:\Program Files\Inkscape\bin\inkscape.exe")

CELL = 32


@dataclass(frozen=True)
class Sheet:
    name: str
    cols: int
    rows: int
    content: str

    @property
    def width(self) -> int:
        return self.cols * CELL

    @property
    def height(self) -> int:
        return self.rows * CELL


def color(hex_value: str) -> str:
    return hex_value


SKY = color("#59a6f2")
GROUND_GREEN = color("#40a640")
GROUND_BROWN = color("#8c5926")
UNDERGROUND_DARK = color("#2e2e47")
UNDERGROUND_BASE = color("#4c4c6b")
BRICK_RED = color("#b84c2e")
BRICK_DARK = color("#8c381f")
MARIO_RED = color("#e62626")
MARIO_SKIN = color("#f2bf8c")
MARIO_BLUE = color("#334dbf")
FIRE_WHITE = color("#f2f2f2")
GOOMBA_BROWN = color("#8c4c26")
GOOMBA_DARK = color("#592e14")
KOOPA_GREEN = color("#33b340")
KOOPA_SHELL = color("#268c33")
PIRANHA_GREEN = color("#269926")
PIRANHA_RED = color("#cc261f")
PIPE_GREEN = color("#2e9938")
PIPE_LIGHT = color("#47b852")
QUESTION_YELLOW = color("#f2cc33")
QUESTION_DARK = color("#b38c1a")
COIN_GOLD = color("#ffd933")
COIN_SHINE = color("#fff299")
BLOCK_BROWN = color("#805933")
STAR_YELLOW = color("#ffe626")
FIRE_ORANGE = color("#ff8c1a")
FIRE_RED = color("#ff401a")
MUSHROOM_RED = color("#e62626")
MUSHROOM_GREEN = color("#39b54a")
MUSHROOM_CREAM = color("#f2e6cc")
WHITE = color("#ffffff")
BLACK = color("#000000")


def tag(name: str, attrs: dict[str, object], children: str = "") -> str:
    attr_text = " ".join(f'{key}="{value}"' for key, value in attrs.items())
    if children:
        return f"<{name} {attr_text}>{children}</{name}>"
    return f"<{name} {attr_text}/>"


def group(x: int, y: int, children: str) -> str:
    return tag("g", {"transform": f"translate({x * CELL},{y * CELL})"}, children)


def rect(x: float, y: float, w: float, h: float, fill: str, stroke: str | None = None) -> str:
    attrs: dict[str, object] = {"x": x, "y": y, "width": w, "height": h, "fill": fill}
    if stroke:
        attrs["stroke"] = stroke
        attrs["stroke-width"] = 1
    return tag("rect", attrs)


def circle(cx: float, cy: float, r: float, fill: str, stroke: str | None = None) -> str:
    attrs: dict[str, object] = {"cx": cx, "cy": cy, "r": r, "fill": fill}
    if stroke:
        attrs["stroke"] = stroke
        attrs["stroke-width"] = 1
    return tag("circle", attrs)


def poly(points: list[tuple[float, float]], fill: str, stroke: str | None = None) -> str:
    attrs: dict[str, object] = {
        "points": " ".join(f"{x},{y}" for x, y in points),
        "fill": fill,
    }
    if stroke:
        attrs["stroke"] = stroke
        attrs["stroke-width"] = 1
    return tag("polygon", attrs)


def line(x1: float, y1: float, x2: float, y2: float, stroke: str, width: float = 1.0) -> str:
    return tag("line", {"x1": x1, "y1": y1, "x2": x2, "y2": y2, "stroke": stroke, "stroke-width": width})


def svg(width: int, height: int, body: str) -> str:
    return (
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" '
        f'viewBox="0 0 {width} {height}" shape-rendering="crispEdges">\n'
        f'{body}\n</svg>\n'
    )


def cell_frame(label: str = "") -> str:
    if not label:
        return ""
    return tag(
        "text",
        {"x": 2, "y": 30, "font-size": 3, "font-family": "monospace", "fill": "#000000", "opacity": 0.35},
        label,
    )


def mario_frame(form: str, pose: str, step: int = 0) -> str:
    red = FIRE_WHITE if form == "fire" else MARIO_RED
    body_h = 16 if form == "small" else 28
    y = 30 - body_h
    foot_shift = [-2, 2, 0][step % 3]
    crouch = pose == "crouch"
    death = pose == "death"
    if crouch:
        y = 13
        body_h = 17
    if death:
        y = 16
        body_h = 14
    parts = ""
    parts += rect(10, 27, 5, 3, red)
    parts += rect(17 + foot_shift, 27, 5, 3, red)
    if form == "small" or crouch or death:
        parts += rect(10, y + 7, 12, 8, MARIO_BLUE)
        parts += rect(11, y + 5, 10, 3, red)
        parts += rect(12, y + 2, 8, 4, MARIO_SKIN)
        parts += rect(10, y, 12, 3, red)
        if death:
            parts += rect(12, y + 3, 8, 1, BLACK)
        else:
            parts += rect(17, y + 3, 2, 2, WHITE)
            parts += rect(18, y + 3, 1, 1, BLACK)
    else:
        if pose == "jump":
            parts += rect(8, y + 9, 3, 5, MARIO_SKIN)
            parts += rect(22, y + 4, 3, 6, MARIO_SKIN)
        else:
            parts += rect(8, y + 10, 3, 6, MARIO_SKIN)
            parts += rect(21, y + 10, 3, 6, MARIO_SKIN)
        parts += rect(10, y + 16, 12, 10, MARIO_BLUE)
        parts += rect(10, y + 9, 12, 7, red)
        parts += rect(11, y + 3, 10, 6, MARIO_SKIN)
        parts += rect(10, y, 12, 4, red)
        parts += rect(17, y + 4, 2, 2, WHITE)
        parts += rect(18, y + 4, 1, 1, BLACK)
        parts += rect(19, y + 6, 2, 2, "#d9a87a")
    return parts


def goomba_frame(step: int, squished: bool = False) -> str:
    if squished:
        return rect(8, 25, 16, 5, GOOMBA_BROWN, GOOMBA_DARK) + rect(12, 27, 3, 1, GOOMBA_DARK) + rect(18, 27, 3, 1, GOOMBA_DARK)
    foot = -2 if step == 0 else 2
    body = poly([(7, 29), (25, 29), (22, 16), (10, 16)], GOOMBA_BROWN, GOOMBA_DARK)
    feet = rect(7, 27, 7, 3, GOOMBA_DARK) + rect(18 + foot, 27, 7, 3, GOOMBA_DARK)
    eyes = circle(13, 20, 2, WHITE) + circle(20, 20, 2, WHITE) + circle(13, 20, 1, BLACK) + circle(20, 20, 1, BLACK)
    brows = rect(10, 17, 5, 1, GOOMBA_DARK) + rect(18, 17, 5, 1, GOOMBA_DARK)
    return feet + body + eyes + brows


def koopa_frame(step: int) -> str:
    foot = -2 if step == 0 else 2
    parts = rect(9, 27, 5, 3, "#1f7a27") + rect(18 + foot, 27, 5, 3, "#1f7a27")
    parts += rect(10, 18, 12, 9, "#f2d98c", GOOMBA_DARK)
    parts += poly([(8, 19), (24, 19), (22, 11), (18, 8), (14, 8), (10, 11)], KOOPA_GREEN, KOOPA_SHELL)
    parts += rect(10, 14, 12, 2, KOOPA_SHELL)
    parts += circle(22, 11, 4, "#47c452", KOOPA_SHELL)
    parts += circle(23, 10, 1.5, WHITE) + circle(23.5, 10, 0.7, BLACK)
    return parts


def shell_frame(step: int) -> str:
    stripe_x = [9, 11, 13, 11][step % 4]
    parts = poly([(7, 29), (25, 29), (25, 24), (22, 18), (16, 16), (10, 18), (7, 24)], KOOPA_GREEN, KOOPA_SHELL)
    parts += rect(8, 27, 16, 3, "#f2d98c")
    parts += rect(stripe_x, 21, 10, 2, KOOPA_SHELL)
    parts += rect(12, 18, 8, 1, "#66d96f")
    return parts


def piranha_frame(open_amount: int) -> str:
    head_y = 22 - open_amount
    stem_h = 30 - head_y
    parts = rect(14, head_y, 4, stem_h, PIRANHA_GREEN)
    parts += rect(8, head_y - 11, 16, 12, PIRANHA_GREEN, "#176617")
    parts += rect(7, head_y - 11, 18, 3, PIRANHA_RED)
    parts += rect(7, head_y - 1, 18, 2, PIRANHA_RED)
    parts += rect(12, head_y - 8, 2, 4, WHITE) + rect(19, head_y - 8, 2, 4, WHITE)
    return parts


def coin_frame(width: int) -> str:
    cx = 16
    parts = rect(cx - width, 9, width * 2, 16, COIN_GOLD, "#cc9d13")
    if width > 2:
        parts += rect(cx - max(1, width // 3), 11, max(1, width // 2), 12, COIN_SHINE)
    return parts


def star_frame(fill: str) -> str:
    pts = [(16, 4), (19, 12), (28, 12), (21, 18), (24, 27), (16, 22), (8, 27), (11, 18), (4, 12), (13, 12)]
    return poly(pts, fill, "#a87900") + circle(13, 15, 1, BLACK) + circle(19, 15, 1, BLACK)


def flower_frame(step: int) -> str:
    colors = [FIRE_ORANGE, FIRE_RED, STAR_YELLOW]
    parts = rect(15, 19, 2, 10, PIRANHA_GREEN)
    for i, (x, y) in enumerate([(16, 10), (10, 14), (22, 14), (12, 21), (20, 21)]):
        parts += circle(x, y, 4, colors[(i + step) % len(colors)])
    parts += circle(16, 16, 3, STAR_YELLOW, FIRE_RED)
    return parts


def mushroom_frame(fill: str) -> str:
    return (
        rect(12, 21, 8, 8, MUSHROOM_CREAM)
        + poly([(7, 22), (25, 22), (23, 14), (20, 9), (16, 7), (12, 9), (9, 14)], fill, "#8c1f1f")
        + circle(11, 16, 2, MUSHROOM_CREAM)
        + circle(21, 16, 2, MUSHROOM_CREAM)
        + circle(16, 12, 2, MUSHROOM_CREAM)
    )


def block_question(frame: int) -> str:
    fills = [QUESTION_YELLOW, "#ffd94d", "#e6b829"]
    return (
        rect(6, 6, 20, 20, fills[frame % 3], QUESTION_DARK)
        + rect(11, 10, 10, 2, QUESTION_DARK)
        + rect(19, 12, 2, 5, QUESTION_DARK)
        + rect(15, 17, 4, 2, QUESTION_DARK)
        + rect(15, 23, 3, 3, QUESTION_DARK)
    )


def brick_block() -> str:
    parts = rect(6, 6, 20, 20, BRICK_RED, BRICK_DARK)
    parts += line(6, 14, 26, 14, BRICK_DARK) + line(6, 22, 26, 22, BRICK_DARK)
    parts += line(11, 6, 11, 14, BRICK_DARK) + line(21, 6, 21, 14, BRICK_DARK)
    parts += line(16, 14, 16, 22, BRICK_DARK) + line(11, 22, 11, 26, BRICK_DARK) + line(21, 22, 21, 26, BRICK_DARK)
    return parts


def used_block() -> str:
    return rect(6, 6, 20, 20, BLOCK_BROWN, "#594026") + rect(8, 8, 16, 3, "#9a7040")


def pipe_cap() -> str:
    return rect(2, 8, 28, 16, PIPE_LIGHT, PIPE_GREEN) + rect(2, 8, 4, 16, PIPE_GREEN) + rect(26, 8, 4, 16, PIPE_GREEN)


def pipe_body() -> str:
    return rect(6, 0, 20, 32, PIPE_LIGHT, PIPE_GREEN) + rect(6, 0, 4, 32, PIPE_GREEN) + rect(22, 0, 4, 32, PIPE_GREEN)


def flagpole_parts(kind: str) -> str:
    if kind == "pole":
        return rect(14, 0, 4, 32, "#999999")
    if kind == "ball":
        return circle(16, 16, 7, STAR_YELLOW, "#aa8a00")
    if kind == "flag":
        return poly([(22, 8), (5, 16), (22, 24)], "#1ab326", "#0c6615")
    return rect(4, 16, 24, 12, GROUND_GREEN, "#267026")


def terrain(kind: str) -> str:
    if kind == "over_top":
        return rect(0, 0, 32, 6, GROUND_GREEN) + rect(0, 6, 32, 26, GROUND_BROWN)
    if kind == "over_fill":
        return rect(0, 0, 32, 32, GROUND_BROWN)
    if kind == "under_top":
        return rect(0, 0, 32, 6, UNDERGROUND_DARK) + rect(0, 6, 32, 26, UNDERGROUND_BASE)
    return rect(0, 0, 32, 32, UNDERGROUND_BASE)


def decor(kind: str) -> str:
    if kind == "cloud":
        return circle(16, 14, 8, WHITE) + circle(9, 17, 6, WHITE) + circle(23, 17, 6, WHITE)
    if kind == "hill":
        return poly([(2, 28), (30, 28), (26, 17), (20, 10), (12, 10), (6, 17)], "#73bf73")
    return circle(16, 20, 9, "#399939") + circle(8, 24, 6, "#399939") + circle(24, 24, 6, "#399939")


def castle() -> str:
    parts = rect(3, 14, 26, 18, "#8c5926", "#66401a")
    for x in [3, 10, 19]:
        parts += rect(x, 8, 6, 6, "#8c5926", "#66401a")
    parts += rect(12, 23, 8, 9, BLACK)
    parts += rect(14, 16, 4, 4, BLACK)
    parts += line(3, 20, 29, 20, "#66401a") + line(3, 26, 29, 26, "#66401a")
    return parts


def fireball_frame(step: int) -> str:
    colors = [FIRE_ORANGE, FIRE_RED, STAR_YELLOW, FIRE_RED]
    return circle(16, 16, 7, colors[step % 4]) + circle(16, 16, 3, colors[(step + 1) % 4])


def digit(ch: str) -> str:
    segs = {
        "0": [(0, 0, 5, 1), (0, 6, 5, 1), (0, 0, 1, 7), (4, 0, 1, 7)],
        "1": [(2, 0, 1, 7)],
        "2": [(0, 0, 5, 1), (4, 0, 1, 4), (0, 3, 5, 1), (0, 3, 1, 4), (0, 6, 5, 1)],
        "3": [(0, 0, 5, 1), (0, 3, 5, 1), (0, 6, 5, 1), (4, 0, 1, 7)],
        "4": [(0, 0, 1, 4), (0, 3, 5, 1), (4, 0, 1, 7)],
        "5": [(0, 0, 5, 1), (0, 0, 1, 4), (0, 3, 5, 1), (4, 3, 1, 4), (0, 6, 5, 1)],
        "6": [(0, 0, 5, 1), (0, 0, 1, 7), (0, 3, 5, 1), (4, 3, 1, 4), (0, 6, 5, 1)],
        "7": [(0, 0, 5, 1), (4, 0, 1, 7)],
        "8": [(0, 0, 5, 1), (0, 3, 5, 1), (0, 6, 5, 1), (0, 0, 1, 7), (4, 0, 1, 7)],
        "9": [(0, 0, 5, 1), (0, 0, 1, 4), (0, 3, 5, 1), (4, 0, 1, 7), (0, 6, 5, 1)],
    }[ch]
    return "".join(rect(11 + x * 2, 9 + y * 2, w * 2, h * 2, WHITE) for x, y, w, h in segs)


def build_sheet(name: str, cells: list[str], cols: int) -> Sheet:
    rows = (len(cells) + cols - 1) // cols
    body = "".join(group(i % cols, i // cols, cell) for i, cell in enumerate(cells))
    return Sheet(name, cols, rows, body)


def build_sheets() -> list[Sheet]:
    player_cells = [
        mario_frame("small", "idle"),
        mario_frame("small", "walk", 0),
        mario_frame("small", "walk", 1),
        mario_frame("small", "jump"),
        mario_frame("small", "death"),
        mario_frame("big", "idle"),
        mario_frame("big", "walk", 0),
        mario_frame("big", "walk", 1),
        mario_frame("big", "jump"),
        mario_frame("big", "crouch"),
        mario_frame("big", "flag"),
        mario_frame("fire", "idle"),
        mario_frame("fire", "walk", 0),
        mario_frame("fire", "walk", 1),
        mario_frame("fire", "jump"),
        mario_frame("fire", "crouch"),
        mario_frame("fire", "flag"),
    ]
    return [
        build_sheet("player_sheet", player_cells, 6),
        build_sheet("goomba_sheet", [goomba_frame(0), goomba_frame(1), goomba_frame(0, True)], 3),
        build_sheet("koopa_sheet", [koopa_frame(0), koopa_frame(1), koopa_frame(0)], 3),
        build_sheet("koopa_shell_sheet", [shell_frame(i) for i in range(4)], 4),
        build_sheet("piranha_plant_sheet", [piranha_frame(i) for i in [0, 8, 16, 24]], 4),
        build_sheet("coin_sheet", [coin_frame(w) for w in [7, 4, 1, 4]], 4),
        build_sheet("starman_sheet", [star_frame(c) for c in [STAR_YELLOW, FIRE_ORANGE, "#99e64d"]], 3),
        build_sheet("fireball_sheet", [fireball_frame(i) for i in range(4)], 4),
        build_sheet("powerups_sheet", [mushroom_frame(MUSHROOM_RED), mushroom_frame(MUSHROOM_GREEN)] + [flower_frame(i) for i in range(3)], 5),
        build_sheet("blocks_sheet", [block_question(i) for i in range(3)] + [used_block(), brick_block(), used_block()], 6),
        build_sheet("terrain_sheet", [terrain(k) for k in ["over_top", "over_fill", "under_top", "under_fill"]], 4),
        build_sheet("pipe_sheet", [pipe_cap(), pipe_body()], 2),
        build_sheet("flagpole_sheet", [flagpole_parts(k) for k in ["pole", "ball", "flag", "base"]], 4),
        build_sheet("castle_sheet", [castle()], 1),
        build_sheet("background_decor_sheet", [decor(k) for k in ["cloud", "hill", "bush"]], 3),
        build_sheet("effects_sheet", [
            rect(11, 11, 10, 10, BRICK_RED, BRICK_DARK),
            circle(16, 16, 10, WHITE),
            circle(16, 16, 5, WHITE),
            circle(16, 16, 12, STAR_YELLOW),
            rect(12, 8, 8, 16, MARIO_RED),
            coin_frame(5),
        ], 6),
        build_sheet("score_digits_sheet", [digit(str(i)) for i in range(10)], 10),
    ]


def write_svg(sheet: Sheet) -> Path:
    SVG_DIR.mkdir(parents=True, exist_ok=True)
    path = SVG_DIR / f"{sheet.name}.svg"
    path.write_text(svg(sheet.width, sheet.height, sheet.content), encoding="utf-8")
    return path


def export_png(inkscape: Path, svg_path: Path, sheet: Sheet) -> Path:
    PNG_DIR.mkdir(parents=True, exist_ok=True)
    png_path = PNG_DIR / f"{sheet.name}.png"
    subprocess.run(
        [
            str(inkscape),
            str(svg_path),
            "--export-type=png",
            f"--export-filename={png_path}",
            f"--export-width={sheet.width}",
            f"--export-height={sheet.height}",
        ],
        check=True,
    )
    return png_path


def main() -> None:
    parser = argparse.ArgumentParser(description="Generate SVG sprite sources and export PNG sheets.")
    parser.add_argument("--inkscape", type=Path, default=DEFAULT_INKSCAPE)
    parser.add_argument("--svg-only", action="store_true", help="Write SVG sources without exporting PNGs.")
    args = parser.parse_args()

    sheets = build_sheets()
    if not args.svg_only and not args.inkscape.exists():
        raise SystemExit(f"Inkscape not found: {args.inkscape}")

    for sheet in sheets:
        svg_path = write_svg(sheet)
        if args.svg_only:
            print(f"wrote {svg_path.relative_to(ROOT)}")
        else:
            png_path = export_png(args.inkscape, svg_path, sheet)
            print(f"exported {png_path.relative_to(ROOT)} ({sheet.width}x{sheet.height})")

    print(f"done: {len(sheets)} sheets")


if __name__ == "__main__":
    main()
