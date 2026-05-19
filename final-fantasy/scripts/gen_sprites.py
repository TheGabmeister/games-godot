"""Generate all Phase 1 character sprite sheets and NPC sprites."""
import subprocess, os
from PIL import Image

W, H = 64, 96
BASE = "c:/dev/games-godot/final-fantasy/characters"

def svg_header():
    return '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 96" shape-rendering="crispEdges">\n'

def svg_footer():
    return '</svg>'

def rect(x, y, w, h, fill):
    return f'  <rect x="{x}" y="{y}" width="{w}" height="{h}" fill="{fill}"/>\n'

# ── MONK ──────────────────────────────────────────────────────────────────────

def monk_down_idle():
    s = svg_header()
    # Headband
    s += rect(22, 10, 20, 6, "#C03030")
    s += rect(24, 8, 16, 4, "#C03030")
    # Hair
    s += rect(22, 16, 20, 4, "#402010")
    # Face
    s += rect(22, 20, 20, 12, "#F0C090")
    s += rect(26, 24, 4, 4, "#303030")
    s += rect(34, 24, 4, 4, "#303030")
    # Gi body
    s += rect(16, 32, 32, 24, "#C08040")
    s += rect(24, 32, 16, 24, "#D09050")
    # Belt/sash
    s += rect(16, 52, 32, 4, "#202020")
    s += rect(28, 50, 8, 8, "#303030")
    # Arms (bare)
    s += rect(8, 34, 8, 20, "#E0A870")
    s += rect(48, 34, 8, 20, "#E0A870")
    # Fists
    s += rect(8, 54, 8, 6, "#E0A870")
    s += rect(48, 54, 8, 6, "#E0A870")
    # Legs
    s += rect(20, 56, 10, 20, "#C08040")
    s += rect(34, 56, 10, 20, "#C08040")
    # Feet
    s += rect(18, 76, 12, 8, "#604020")
    s += rect(34, 76, 12, 8, "#604020")
    s += svg_footer()
    return s

def monk_down_walk1():
    s = svg_header()
    s += rect(22, 10, 20, 6, "#C03030")
    s += rect(24, 8, 16, 4, "#C03030")
    s += rect(22, 16, 20, 4, "#402010")
    s += rect(22, 20, 20, 12, "#F0C090")
    s += rect(26, 24, 4, 4, "#303030")
    s += rect(34, 24, 4, 4, "#303030")
    s += rect(16, 32, 32, 24, "#C08040")
    s += rect(24, 32, 16, 24, "#D09050")
    s += rect(16, 52, 32, 4, "#202020")
    s += rect(28, 50, 8, 8, "#303030")
    s += rect(6, 32, 8, 20, "#E0A870")
    s += rect(50, 36, 8, 20, "#E0A870")
    s += rect(6, 52, 8, 6, "#E0A870")
    s += rect(50, 56, 8, 6, "#E0A870")
    s += rect(18, 56, 10, 24, "#C08040")
    s += rect(36, 56, 10, 18, "#C08040")
    s += rect(16, 80, 12, 8, "#604020")
    s += rect(36, 74, 12, 8, "#604020")
    s += svg_footer()
    return s

def monk_down_walk2():
    s = svg_header()
    s += rect(22, 10, 20, 6, "#C03030")
    s += rect(24, 8, 16, 4, "#C03030")
    s += rect(22, 16, 20, 4, "#402010")
    s += rect(22, 20, 20, 12, "#F0C090")
    s += rect(26, 24, 4, 4, "#303030")
    s += rect(34, 24, 4, 4, "#303030")
    s += rect(16, 32, 32, 24, "#C08040")
    s += rect(24, 32, 16, 24, "#D09050")
    s += rect(16, 52, 32, 4, "#202020")
    s += rect(28, 50, 8, 8, "#303030")
    s += rect(10, 36, 8, 20, "#E0A870")
    s += rect(46, 32, 8, 20, "#E0A870")
    s += rect(10, 56, 8, 6, "#E0A870")
    s += rect(46, 52, 8, 6, "#E0A870")
    s += rect(20, 56, 10, 18, "#C08040")
    s += rect(34, 56, 10, 24, "#C08040")
    s += rect(20, 74, 12, 8, "#604020")
    s += rect(32, 80, 12, 8, "#604020")
    s += svg_footer()
    return s

def monk_up_idle():
    s = svg_header()
    s += rect(22, 10, 20, 6, "#C03030")
    s += rect(24, 8, 16, 4, "#C03030")
    # Tail of headband
    s += rect(40, 12, 8, 4, "#C03030")
    s += rect(44, 16, 8, 4, "#C03030")
    s += rect(22, 16, 20, 8, "#402010")
    s += rect(24, 20, 16, 8, "#402010")
    s += rect(16, 32, 32, 24, "#C08040")
    s += rect(24, 32, 16, 24, "#D09050")
    s += rect(16, 52, 32, 4, "#202020")
    s += rect(8, 34, 8, 20, "#E0A870")
    s += rect(48, 34, 8, 20, "#E0A870")
    s += rect(8, 54, 8, 6, "#E0A870")
    s += rect(48, 54, 8, 6, "#E0A870")
    s += rect(20, 56, 10, 20, "#C08040")
    s += rect(34, 56, 10, 20, "#C08040")
    s += rect(18, 76, 12, 8, "#604020")
    s += rect(34, 76, 12, 8, "#604020")
    s += svg_footer()
    return s

def monk_up_walk1():
    s = svg_header()
    s += rect(22, 10, 20, 6, "#C03030")
    s += rect(24, 8, 16, 4, "#C03030")
    s += rect(40, 12, 8, 4, "#C03030")
    s += rect(44, 16, 8, 4, "#C03030")
    s += rect(22, 16, 20, 8, "#402010")
    s += rect(24, 20, 16, 8, "#402010")
    s += rect(16, 32, 32, 24, "#C08040")
    s += rect(24, 32, 16, 24, "#D09050")
    s += rect(16, 52, 32, 4, "#202020")
    s += rect(6, 32, 8, 20, "#E0A870")
    s += rect(50, 36, 8, 20, "#E0A870")
    s += rect(6, 52, 8, 6, "#E0A870")
    s += rect(50, 56, 8, 6, "#E0A870")
    s += rect(18, 56, 10, 24, "#C08040")
    s += rect(36, 56, 10, 18, "#C08040")
    s += rect(16, 80, 12, 8, "#604020")
    s += rect(36, 74, 12, 8, "#604020")
    s += svg_footer()
    return s

def monk_up_walk2():
    s = svg_header()
    s += rect(22, 10, 20, 6, "#C03030")
    s += rect(24, 8, 16, 4, "#C03030")
    s += rect(40, 12, 8, 4, "#C03030")
    s += rect(44, 16, 8, 4, "#C03030")
    s += rect(22, 16, 20, 8, "#402010")
    s += rect(24, 20, 16, 8, "#402010")
    s += rect(16, 32, 32, 24, "#C08040")
    s += rect(24, 32, 16, 24, "#D09050")
    s += rect(16, 52, 32, 4, "#202020")
    s += rect(10, 36, 8, 20, "#E0A870")
    s += rect(46, 32, 8, 20, "#E0A870")
    s += rect(10, 56, 8, 6, "#E0A870")
    s += rect(46, 52, 8, 6, "#E0A870")
    s += rect(20, 56, 10, 18, "#C08040")
    s += rect(34, 56, 10, 24, "#C08040")
    s += rect(20, 74, 12, 8, "#604020")
    s += rect(32, 80, 12, 8, "#604020")
    s += svg_footer()
    return s

def monk_left_idle():
    s = svg_header()
    s += rect(18, 10, 20, 6, "#C03030")
    s += rect(20, 8, 16, 4, "#C03030")
    s += rect(18, 16, 16, 4, "#402010")
    s += rect(16, 20, 16, 12, "#F0C090")
    s += rect(18, 24, 4, 4, "#303030")
    s += rect(12, 26, 4, 4, "#E0B080")
    s += rect(18, 32, 24, 24, "#C08040")
    s += rect(22, 34, 16, 20, "#D09050")
    s += rect(18, 52, 24, 4, "#202020")
    s += rect(10, 34, 8, 22, "#E0A870")
    s += rect(10, 56, 8, 6, "#E0A870")
    s += rect(22, 56, 10, 20, "#C08040")
    s += rect(32, 56, 10, 20, "#C08040")
    s += rect(18, 76, 14, 8, "#604020")
    s += rect(32, 76, 12, 8, "#604020")
    s += svg_footer()
    return s

def monk_left_walk1():
    s = svg_header()
    s += rect(18, 10, 20, 6, "#C03030")
    s += rect(20, 8, 16, 4, "#C03030")
    s += rect(18, 16, 16, 4, "#402010")
    s += rect(16, 20, 16, 12, "#F0C090")
    s += rect(18, 24, 4, 4, "#303030")
    s += rect(12, 26, 4, 4, "#E0B080")
    s += rect(18, 32, 24, 24, "#C08040")
    s += rect(22, 34, 16, 20, "#D09050")
    s += rect(18, 52, 24, 4, "#202020")
    s += rect(8, 32, 8, 24, "#E0A870")
    s += rect(8, 56, 8, 6, "#E0A870")
    s += rect(16, 56, 10, 24, "#C08040")
    s += rect(34, 56, 10, 18, "#C08040")
    s += rect(12, 80, 14, 8, "#604020")
    s += rect(34, 74, 12, 8, "#604020")
    s += svg_footer()
    return s

def monk_left_walk2():
    s = svg_header()
    s += rect(18, 10, 20, 6, "#C03030")
    s += rect(20, 8, 16, 4, "#C03030")
    s += rect(18, 16, 16, 4, "#402010")
    s += rect(16, 20, 16, 12, "#F0C090")
    s += rect(18, 24, 4, 4, "#303030")
    s += rect(12, 26, 4, 4, "#E0B080")
    s += rect(18, 32, 24, 24, "#C08040")
    s += rect(22, 34, 16, 20, "#D09050")
    s += rect(18, 52, 24, 4, "#202020")
    s += rect(12, 36, 8, 22, "#E0A870")
    s += rect(12, 58, 8, 6, "#E0A870")
    s += rect(24, 56, 10, 18, "#C08040")
    s += rect(28, 56, 10, 24, "#C08040")
    s += rect(22, 74, 12, 8, "#604020")
    s += rect(26, 80, 14, 8, "#604020")
    s += svg_footer()
    return s

def monk_right_idle():
    s = svg_header()
    s += rect(26, 10, 20, 6, "#C03030")
    s += rect(28, 8, 16, 4, "#C03030")
    s += rect(30, 16, 16, 4, "#402010")
    s += rect(32, 20, 16, 12, "#F0C090")
    s += rect(42, 24, 4, 4, "#303030")
    s += rect(48, 26, 4, 4, "#E0B080")
    s += rect(22, 32, 24, 24, "#C08040")
    s += rect(26, 34, 16, 20, "#D09050")
    s += rect(22, 52, 24, 4, "#202020")
    s += rect(46, 34, 8, 22, "#E0A870")
    s += rect(46, 56, 8, 6, "#E0A870")
    s += rect(22, 56, 10, 20, "#C08040")
    s += rect(32, 56, 10, 20, "#C08040")
    s += rect(18, 76, 12, 8, "#604020")
    s += rect(32, 76, 14, 8, "#604020")
    s += svg_footer()
    return s

def monk_right_walk1():
    s = svg_header()
    s += rect(26, 10, 20, 6, "#C03030")
    s += rect(28, 8, 16, 4, "#C03030")
    s += rect(30, 16, 16, 4, "#402010")
    s += rect(32, 20, 16, 12, "#F0C090")
    s += rect(42, 24, 4, 4, "#303030")
    s += rect(48, 26, 4, 4, "#E0B080")
    s += rect(22, 32, 24, 24, "#C08040")
    s += rect(26, 34, 16, 20, "#D09050")
    s += rect(22, 52, 24, 4, "#202020")
    s += rect(48, 32, 8, 24, "#E0A870")
    s += rect(48, 56, 8, 6, "#E0A870")
    s += rect(20, 56, 10, 18, "#C08040")
    s += rect(34, 56, 10, 24, "#C08040")
    s += rect(20, 74, 12, 8, "#604020")
    s += rect(32, 80, 14, 8, "#604020")
    s += svg_footer()
    return s

def monk_right_walk2():
    s = svg_header()
    s += rect(26, 10, 20, 6, "#C03030")
    s += rect(28, 8, 16, 4, "#C03030")
    s += rect(30, 16, 16, 4, "#402010")
    s += rect(32, 20, 16, 12, "#F0C090")
    s += rect(42, 24, 4, 4, "#303030")
    s += rect(48, 26, 4, 4, "#E0B080")
    s += rect(22, 32, 24, 24, "#C08040")
    s += rect(26, 34, 16, 20, "#D09050")
    s += rect(22, 52, 24, 4, "#202020")
    s += rect(44, 36, 8, 22, "#E0A870")
    s += rect(44, 58, 8, 6, "#E0A870")
    s += rect(26, 56, 10, 24, "#C08040")
    s += rect(28, 56, 10, 18, "#C08040")
    s += rect(24, 80, 14, 8, "#604020")
    s += rect(28, 74, 12, 8, "#604020")
    s += svg_footer()
    return s

# ── WHITE MAGE ────────────────────────────────────────────────────────────────

def wmage_down_idle():
    s = svg_header()
    # Hood
    s += rect(18, 4, 28, 16, "#F0F0F0")
    s += rect(20, 4, 24, 4, "#E0E0E0")
    # Hood trim
    s += rect(18, 16, 28, 4, "#C02020")
    # Face
    s += rect(22, 20, 20, 10, "#F0C090")
    s += rect(26, 22, 4, 4, "#303030")
    s += rect(34, 22, 4, 4, "#303030")
    # Robe body
    s += rect(14, 30, 36, 30, "#F0F0F0")
    s += rect(22, 30, 20, 30, "#E8E8E8")
    # Red trim on robe
    s += rect(14, 30, 36, 4, "#C02020")
    s += rect(14, 56, 36, 4, "#C02020")
    # Sleeves
    s += rect(6, 32, 10, 18, "#F0F0F0")
    s += rect(48, 32, 10, 18, "#F0F0F0")
    # Hands
    s += rect(8, 50, 8, 6, "#F0C090")
    s += rect(48, 50, 8, 6, "#F0C090")
    # Staff (left hand)
    s += rect(10, 10, 4, 46, "#806020")
    s += rect(6, 6, 12, 8, "#FFD700")
    s += rect(10, 2, 4, 6, "#FFD700")
    # Robe bottom
    s += rect(16, 60, 14, 20, "#F0F0F0")
    s += rect(34, 60, 14, 20, "#F0F0F0")
    # Red trim bottom
    s += rect(16, 76, 14, 4, "#C02020")
    s += rect(34, 76, 14, 4, "#C02020")
    # Shoes
    s += rect(16, 80, 12, 8, "#C02020")
    s += rect(36, 80, 12, 8, "#C02020")
    s += svg_footer()
    return s

def wmage_down_walk1():
    s = svg_header()
    s += rect(18, 4, 28, 16, "#F0F0F0")
    s += rect(20, 4, 24, 4, "#E0E0E0")
    s += rect(18, 16, 28, 4, "#C02020")
    s += rect(22, 20, 20, 10, "#F0C090")
    s += rect(26, 22, 4, 4, "#303030")
    s += rect(34, 22, 4, 4, "#303030")
    s += rect(14, 30, 36, 30, "#F0F0F0")
    s += rect(22, 30, 20, 30, "#E8E8E8")
    s += rect(14, 30, 36, 4, "#C02020")
    s += rect(14, 56, 36, 4, "#C02020")
    s += rect(4, 30, 10, 18, "#F0F0F0")
    s += rect(50, 34, 10, 18, "#F0F0F0")
    s += rect(6, 48, 8, 6, "#F0C090")
    s += rect(50, 52, 8, 6, "#F0C090")
    s += rect(8, 8, 4, 46, "#806020")
    s += rect(4, 4, 12, 8, "#FFD700")
    s += rect(8, 0, 4, 6, "#FFD700")
    s += rect(14, 60, 14, 24, "#F0F0F0")
    s += rect(36, 60, 14, 18, "#F0F0F0")
    s += rect(14, 80, 14, 4, "#C02020")
    s += rect(36, 74, 14, 4, "#C02020")
    s += rect(12, 84, 14, 4, "#C02020")
    s += rect(36, 78, 12, 4, "#C02020")
    s += svg_footer()
    return s

def wmage_down_walk2():
    s = svg_header()
    s += rect(18, 4, 28, 16, "#F0F0F0")
    s += rect(20, 4, 24, 4, "#E0E0E0")
    s += rect(18, 16, 28, 4, "#C02020")
    s += rect(22, 20, 20, 10, "#F0C090")
    s += rect(26, 22, 4, 4, "#303030")
    s += rect(34, 22, 4, 4, "#303030")
    s += rect(14, 30, 36, 30, "#F0F0F0")
    s += rect(22, 30, 20, 30, "#E8E8E8")
    s += rect(14, 30, 36, 4, "#C02020")
    s += rect(14, 56, 36, 4, "#C02020")
    s += rect(8, 34, 10, 18, "#F0F0F0")
    s += rect(46, 30, 10, 18, "#F0F0F0")
    s += rect(10, 52, 8, 6, "#F0C090")
    s += rect(46, 48, 8, 6, "#F0C090")
    s += rect(12, 12, 4, 46, "#806020")
    s += rect(8, 8, 12, 8, "#FFD700")
    s += rect(12, 4, 4, 6, "#FFD700")
    s += rect(16, 60, 14, 18, "#F0F0F0")
    s += rect(34, 60, 14, 24, "#F0F0F0")
    s += rect(16, 74, 14, 4, "#C02020")
    s += rect(34, 80, 14, 4, "#C02020")
    s += rect(16, 78, 12, 4, "#C02020")
    s += rect(34, 84, 14, 4, "#C02020")
    s += svg_footer()
    return s

def wmage_up_idle():
    s = svg_header()
    s += rect(18, 4, 28, 20, "#F0F0F0")
    s += rect(20, 4, 24, 4, "#E0E0E0")
    s += rect(18, 20, 28, 4, "#C02020")
    s += rect(22, 24, 20, 4, "#806040")
    s += rect(14, 30, 36, 30, "#F0F0F0")
    s += rect(22, 30, 20, 30, "#E8E8E8")
    s += rect(14, 30, 36, 4, "#C02020")
    s += rect(14, 56, 36, 4, "#C02020")
    s += rect(6, 32, 10, 18, "#F0F0F0")
    s += rect(48, 32, 10, 18, "#F0F0F0")
    s += rect(8, 50, 8, 6, "#F0C090")
    s += rect(48, 50, 8, 6, "#F0C090")
    s += rect(10, 10, 4, 46, "#806020")
    s += rect(6, 6, 12, 8, "#FFD700")
    s += rect(10, 2, 4, 6, "#FFD700")
    s += rect(16, 60, 14, 20, "#F0F0F0")
    s += rect(34, 60, 14, 20, "#F0F0F0")
    s += rect(16, 76, 14, 4, "#C02020")
    s += rect(34, 76, 14, 4, "#C02020")
    s += rect(16, 80, 12, 8, "#C02020")
    s += rect(36, 80, 12, 8, "#C02020")
    s += svg_footer()
    return s

def wmage_up_walk1():
    s = svg_header()
    s += rect(18, 4, 28, 20, "#F0F0F0")
    s += rect(20, 4, 24, 4, "#E0E0E0")
    s += rect(18, 20, 28, 4, "#C02020")
    s += rect(22, 24, 20, 4, "#806040")
    s += rect(14, 30, 36, 30, "#F0F0F0")
    s += rect(22, 30, 20, 30, "#E8E8E8")
    s += rect(14, 30, 36, 4, "#C02020")
    s += rect(14, 56, 36, 4, "#C02020")
    s += rect(4, 30, 10, 18, "#F0F0F0")
    s += rect(50, 34, 10, 18, "#F0F0F0")
    s += rect(6, 48, 8, 6, "#F0C090")
    s += rect(50, 52, 8, 6, "#F0C090")
    s += rect(8, 8, 4, 46, "#806020")
    s += rect(4, 4, 12, 8, "#FFD700")
    s += rect(8, 0, 4, 6, "#FFD700")
    s += rect(14, 60, 14, 24, "#F0F0F0")
    s += rect(36, 60, 14, 18, "#F0F0F0")
    s += rect(14, 80, 14, 4, "#C02020")
    s += rect(36, 74, 14, 4, "#C02020")
    s += rect(12, 84, 14, 4, "#C02020")
    s += rect(36, 78, 12, 4, "#C02020")
    s += svg_footer()
    return s

def wmage_up_walk2():
    s = svg_header()
    s += rect(18, 4, 28, 20, "#F0F0F0")
    s += rect(20, 4, 24, 4, "#E0E0E0")
    s += rect(18, 20, 28, 4, "#C02020")
    s += rect(22, 24, 20, 4, "#806040")
    s += rect(14, 30, 36, 30, "#F0F0F0")
    s += rect(22, 30, 20, 30, "#E8E8E8")
    s += rect(14, 30, 36, 4, "#C02020")
    s += rect(14, 56, 36, 4, "#C02020")
    s += rect(8, 34, 10, 18, "#F0F0F0")
    s += rect(46, 30, 10, 18, "#F0F0F0")
    s += rect(10, 52, 8, 6, "#F0C090")
    s += rect(46, 48, 8, 6, "#F0C090")
    s += rect(12, 12, 4, 46, "#806020")
    s += rect(8, 8, 12, 8, "#FFD700")
    s += rect(12, 4, 4, 6, "#FFD700")
    s += rect(16, 60, 14, 18, "#F0F0F0")
    s += rect(34, 60, 14, 24, "#F0F0F0")
    s += rect(16, 74, 14, 4, "#C02020")
    s += rect(34, 80, 14, 4, "#C02020")
    s += rect(16, 78, 12, 4, "#C02020")
    s += rect(34, 84, 14, 4, "#C02020")
    s += svg_footer()
    return s

def wmage_left_idle():
    s = svg_header()
    s += rect(16, 4, 24, 20, "#F0F0F0")
    s += rect(18, 4, 20, 4, "#E0E0E0")
    s += rect(16, 20, 24, 4, "#C02020")
    s += rect(16, 24, 16, 8, "#F0C090")
    s += rect(18, 26, 4, 4, "#303030")
    s += rect(12, 28, 4, 4, "#E0B080")
    s += rect(14, 30, 28, 30, "#F0F0F0")
    s += rect(20, 30, 16, 30, "#E8E8E8")
    s += rect(14, 30, 28, 4, "#C02020")
    s += rect(14, 56, 28, 4, "#C02020")
    s += rect(6, 32, 10, 18, "#F0F0F0")
    s += rect(8, 50, 8, 6, "#F0C090")
    s += rect(10, 10, 4, 46, "#806020")
    s += rect(6, 6, 12, 8, "#FFD700")
    s += rect(10, 2, 4, 6, "#FFD700")
    s += rect(16, 60, 12, 20, "#F0F0F0")
    s += rect(30, 60, 12, 20, "#F0F0F0")
    s += rect(16, 76, 12, 4, "#C02020")
    s += rect(30, 76, 12, 4, "#C02020")
    s += rect(14, 80, 12, 8, "#C02020")
    s += rect(30, 80, 12, 8, "#C02020")
    s += svg_footer()
    return s

def wmage_left_walk1():
    s = svg_header()
    s += rect(16, 4, 24, 20, "#F0F0F0")
    s += rect(18, 4, 20, 4, "#E0E0E0")
    s += rect(16, 20, 24, 4, "#C02020")
    s += rect(16, 24, 16, 8, "#F0C090")
    s += rect(18, 26, 4, 4, "#303030")
    s += rect(12, 28, 4, 4, "#E0B080")
    s += rect(14, 30, 28, 30, "#F0F0F0")
    s += rect(20, 30, 16, 30, "#E8E8E8")
    s += rect(14, 30, 28, 4, "#C02020")
    s += rect(14, 56, 28, 4, "#C02020")
    s += rect(4, 30, 10, 18, "#F0F0F0")
    s += rect(6, 48, 8, 6, "#F0C090")
    s += rect(8, 8, 4, 46, "#806020")
    s += rect(4, 4, 12, 8, "#FFD700")
    s += rect(8, 0, 4, 6, "#FFD700")
    s += rect(10, 60, 14, 24, "#F0F0F0")
    s += rect(32, 60, 12, 18, "#F0F0F0")
    s += rect(10, 80, 14, 4, "#C02020")
    s += rect(32, 74, 12, 4, "#C02020")
    s += rect(8, 84, 14, 4, "#C02020")
    s += rect(32, 78, 10, 4, "#C02020")
    s += svg_footer()
    return s

def wmage_left_walk2():
    s = svg_header()
    s += rect(16, 4, 24, 20, "#F0F0F0")
    s += rect(18, 4, 20, 4, "#E0E0E0")
    s += rect(16, 20, 24, 4, "#C02020")
    s += rect(16, 24, 16, 8, "#F0C090")
    s += rect(18, 26, 4, 4, "#303030")
    s += rect(12, 28, 4, 4, "#E0B080")
    s += rect(14, 30, 28, 30, "#F0F0F0")
    s += rect(20, 30, 16, 30, "#E8E8E8")
    s += rect(14, 30, 28, 4, "#C02020")
    s += rect(14, 56, 28, 4, "#C02020")
    s += rect(8, 34, 10, 18, "#F0F0F0")
    s += rect(10, 52, 8, 6, "#F0C090")
    s += rect(12, 12, 4, 46, "#806020")
    s += rect(8, 8, 12, 8, "#FFD700")
    s += rect(12, 4, 4, 6, "#FFD700")
    s += rect(20, 60, 12, 18, "#F0F0F0")
    s += rect(28, 60, 14, 24, "#F0F0F0")
    s += rect(20, 74, 12, 4, "#C02020")
    s += rect(28, 80, 14, 4, "#C02020")
    s += rect(20, 78, 10, 4, "#C02020")
    s += rect(28, 84, 14, 4, "#C02020")
    s += svg_footer()
    return s

def wmage_right_idle():
    s = svg_header()
    s += rect(24, 4, 24, 20, "#F0F0F0")
    s += rect(26, 4, 20, 4, "#E0E0E0")
    s += rect(24, 20, 24, 4, "#C02020")
    s += rect(32, 24, 16, 8, "#F0C090")
    s += rect(42, 26, 4, 4, "#303030")
    s += rect(48, 28, 4, 4, "#E0B080")
    s += rect(22, 30, 28, 30, "#F0F0F0")
    s += rect(28, 30, 16, 30, "#E8E8E8")
    s += rect(22, 30, 28, 4, "#C02020")
    s += rect(22, 56, 28, 4, "#C02020")
    s += rect(48, 32, 10, 18, "#F0F0F0")
    s += rect(48, 50, 8, 6, "#F0C090")
    s += rect(50, 10, 4, 46, "#806020")
    s += rect(46, 6, 12, 8, "#FFD700")
    s += rect(50, 2, 4, 6, "#FFD700")
    s += rect(22, 60, 12, 20, "#F0F0F0")
    s += rect(36, 60, 12, 20, "#F0F0F0")
    s += rect(22, 76, 12, 4, "#C02020")
    s += rect(36, 76, 12, 4, "#C02020")
    s += rect(22, 80, 12, 8, "#C02020")
    s += rect(38, 80, 12, 8, "#C02020")
    s += svg_footer()
    return s

def wmage_right_walk1():
    s = svg_header()
    s += rect(24, 4, 24, 20, "#F0F0F0")
    s += rect(26, 4, 20, 4, "#E0E0E0")
    s += rect(24, 20, 24, 4, "#C02020")
    s += rect(32, 24, 16, 8, "#F0C090")
    s += rect(42, 26, 4, 4, "#303030")
    s += rect(48, 28, 4, 4, "#E0B080")
    s += rect(22, 30, 28, 30, "#F0F0F0")
    s += rect(28, 30, 16, 30, "#E8E8E8")
    s += rect(22, 30, 28, 4, "#C02020")
    s += rect(22, 56, 28, 4, "#C02020")
    s += rect(50, 30, 10, 18, "#F0F0F0")
    s += rect(50, 48, 8, 6, "#F0C090")
    s += rect(52, 8, 4, 46, "#806020")
    s += rect(48, 4, 12, 8, "#FFD700")
    s += rect(52, 0, 4, 6, "#FFD700")
    s += rect(20, 60, 12, 18, "#F0F0F0")
    s += rect(36, 60, 14, 24, "#F0F0F0")
    s += rect(20, 74, 12, 4, "#C02020")
    s += rect(36, 80, 14, 4, "#C02020")
    s += rect(20, 78, 10, 4, "#C02020")
    s += rect(36, 84, 14, 4, "#C02020")
    s += svg_footer()
    return s

def wmage_right_walk2():
    s = svg_header()
    s += rect(24, 4, 24, 20, "#F0F0F0")
    s += rect(26, 4, 20, 4, "#E0E0E0")
    s += rect(24, 20, 24, 4, "#C02020")
    s += rect(32, 24, 16, 8, "#F0C090")
    s += rect(42, 26, 4, 4, "#303030")
    s += rect(48, 28, 4, 4, "#E0B080")
    s += rect(22, 30, 28, 30, "#F0F0F0")
    s += rect(28, 30, 16, 30, "#E8E8E8")
    s += rect(22, 30, 28, 4, "#C02020")
    s += rect(22, 56, 28, 4, "#C02020")
    s += rect(46, 34, 10, 18, "#F0F0F0")
    s += rect(46, 52, 8, 6, "#F0C090")
    s += rect(48, 12, 4, 46, "#806020")
    s += rect(44, 8, 12, 8, "#FFD700")
    s += rect(48, 4, 4, 6, "#FFD700")
    s += rect(26, 60, 14, 24, "#F0F0F0")
    s += rect(32, 60, 12, 18, "#F0F0F0")
    s += rect(26, 80, 14, 4, "#C02020")
    s += rect(32, 74, 12, 4, "#C02020")
    s += rect(26, 84, 14, 4, "#C02020")
    s += rect(32, 78, 10, 4, "#C02020")
    s += svg_footer()
    return s

# ── BLACK MAGE ────────────────────────────────────────────────────────────────

def bmage_down_idle():
    s = svg_header()
    # Pointed hat
    s += rect(28, 0, 8, 4, "#2020A0")
    s += rect(24, 4, 16, 4, "#2020A0")
    s += rect(20, 8, 24, 8, "#2020A0")
    # Hat brim
    s += rect(14, 16, 36, 4, "#2020A0")
    # Face (dark/shadow)
    s += rect(22, 20, 20, 10, "#301810")
    # Glowing eyes
    s += rect(26, 22, 4, 4, "#FFD700")
    s += rect(34, 22, 4, 4, "#FFD700")
    # Robe body
    s += rect(14, 30, 36, 30, "#2020A0")
    s += rect(22, 30, 20, 30, "#3030C0")
    # Robe collar
    s += rect(18, 30, 28, 4, "#4040D0")
    # Sleeves
    s += rect(6, 32, 10, 18, "#2020A0")
    s += rect(48, 32, 10, 18, "#2020A0")
    # Hands
    s += rect(8, 50, 6, 6, "#806040")
    s += rect(50, 50, 6, 6, "#806040")
    # Staff (right hand)
    s += rect(52, 8, 4, 48, "#604020")
    s += rect(48, 4, 12, 8, "#40C040")
    s += rect(52, 0, 4, 6, "#40C040")
    # Robe bottom
    s += rect(16, 60, 14, 20, "#2020A0")
    s += rect(34, 60, 14, 20, "#2020A0")
    # Shoes
    s += rect(16, 80, 12, 8, "#402010")
    s += rect(36, 80, 12, 8, "#402010")
    s += svg_footer()
    return s

def bmage_down_walk1():
    s = svg_header()
    s += rect(28, 0, 8, 4, "#2020A0")
    s += rect(24, 4, 16, 4, "#2020A0")
    s += rect(20, 8, 24, 8, "#2020A0")
    s += rect(14, 16, 36, 4, "#2020A0")
    s += rect(22, 20, 20, 10, "#301810")
    s += rect(26, 22, 4, 4, "#FFD700")
    s += rect(34, 22, 4, 4, "#FFD700")
    s += rect(14, 30, 36, 30, "#2020A0")
    s += rect(22, 30, 20, 30, "#3030C0")
    s += rect(18, 30, 28, 4, "#4040D0")
    s += rect(4, 30, 10, 18, "#2020A0")
    s += rect(50, 34, 10, 18, "#2020A0")
    s += rect(6, 48, 6, 6, "#806040")
    s += rect(52, 52, 6, 6, "#806040")
    s += rect(54, 12, 4, 48, "#604020")
    s += rect(50, 8, 12, 8, "#40C040")
    s += rect(54, 4, 4, 6, "#40C040")
    s += rect(14, 60, 14, 24, "#2020A0")
    s += rect(36, 60, 14, 18, "#2020A0")
    s += rect(12, 84, 14, 4, "#402010")
    s += rect(36, 78, 12, 4, "#402010")
    s += svg_footer()
    return s

def bmage_down_walk2():
    s = svg_header()
    s += rect(28, 0, 8, 4, "#2020A0")
    s += rect(24, 4, 16, 4, "#2020A0")
    s += rect(20, 8, 24, 8, "#2020A0")
    s += rect(14, 16, 36, 4, "#2020A0")
    s += rect(22, 20, 20, 10, "#301810")
    s += rect(26, 22, 4, 4, "#FFD700")
    s += rect(34, 22, 4, 4, "#FFD700")
    s += rect(14, 30, 36, 30, "#2020A0")
    s += rect(22, 30, 20, 30, "#3030C0")
    s += rect(18, 30, 28, 4, "#4040D0")
    s += rect(8, 34, 10, 18, "#2020A0")
    s += rect(46, 30, 10, 18, "#2020A0")
    s += rect(10, 52, 6, 6, "#806040")
    s += rect(48, 48, 6, 6, "#806040")
    s += rect(50, 8, 4, 48, "#604020")
    s += rect(46, 4, 12, 8, "#40C040")
    s += rect(50, 0, 4, 6, "#40C040")
    s += rect(16, 60, 14, 18, "#2020A0")
    s += rect(34, 60, 14, 24, "#2020A0")
    s += rect(16, 78, 12, 4, "#402010")
    s += rect(34, 84, 14, 4, "#402010")
    s += svg_footer()
    return s

def bmage_up_idle():
    s = svg_header()
    s += rect(28, 0, 8, 4, "#2020A0")
    s += rect(24, 4, 16, 4, "#2020A0")
    s += rect(20, 8, 24, 8, "#2020A0")
    s += rect(14, 16, 36, 4, "#2020A0")
    s += rect(22, 20, 20, 10, "#2020A0")
    s += rect(14, 30, 36, 30, "#2020A0")
    s += rect(22, 30, 20, 30, "#1818A0")
    s += rect(18, 30, 28, 4, "#4040D0")
    s += rect(6, 32, 10, 18, "#2020A0")
    s += rect(48, 32, 10, 18, "#2020A0")
    s += rect(8, 50, 6, 6, "#806040")
    s += rect(50, 50, 6, 6, "#806040")
    s += rect(52, 8, 4, 48, "#604020")
    s += rect(48, 4, 12, 8, "#40C040")
    s += rect(52, 0, 4, 6, "#40C040")
    s += rect(16, 60, 14, 20, "#2020A0")
    s += rect(34, 60, 14, 20, "#2020A0")
    s += rect(16, 80, 12, 8, "#402010")
    s += rect(36, 80, 12, 8, "#402010")
    s += svg_footer()
    return s

def bmage_up_walk1():
    s = svg_header()
    s += rect(28, 0, 8, 4, "#2020A0")
    s += rect(24, 4, 16, 4, "#2020A0")
    s += rect(20, 8, 24, 8, "#2020A0")
    s += rect(14, 16, 36, 4, "#2020A0")
    s += rect(22, 20, 20, 10, "#2020A0")
    s += rect(14, 30, 36, 30, "#2020A0")
    s += rect(22, 30, 20, 30, "#1818A0")
    s += rect(18, 30, 28, 4, "#4040D0")
    s += rect(4, 30, 10, 18, "#2020A0")
    s += rect(50, 34, 10, 18, "#2020A0")
    s += rect(6, 48, 6, 6, "#806040")
    s += rect(52, 52, 6, 6, "#806040")
    s += rect(54, 12, 4, 48, "#604020")
    s += rect(50, 8, 12, 8, "#40C040")
    s += rect(54, 4, 4, 6, "#40C040")
    s += rect(14, 60, 14, 24, "#2020A0")
    s += rect(36, 60, 14, 18, "#2020A0")
    s += rect(12, 84, 14, 4, "#402010")
    s += rect(36, 78, 12, 4, "#402010")
    s += svg_footer()
    return s

def bmage_up_walk2():
    s = svg_header()
    s += rect(28, 0, 8, 4, "#2020A0")
    s += rect(24, 4, 16, 4, "#2020A0")
    s += rect(20, 8, 24, 8, "#2020A0")
    s += rect(14, 16, 36, 4, "#2020A0")
    s += rect(22, 20, 20, 10, "#2020A0")
    s += rect(14, 30, 36, 30, "#2020A0")
    s += rect(22, 30, 20, 30, "#1818A0")
    s += rect(18, 30, 28, 4, "#4040D0")
    s += rect(8, 34, 10, 18, "#2020A0")
    s += rect(46, 30, 10, 18, "#2020A0")
    s += rect(10, 52, 6, 6, "#806040")
    s += rect(48, 48, 6, 6, "#806040")
    s += rect(50, 8, 4, 48, "#604020")
    s += rect(46, 4, 12, 8, "#40C040")
    s += rect(50, 0, 4, 6, "#40C040")
    s += rect(16, 60, 14, 18, "#2020A0")
    s += rect(34, 60, 14, 24, "#2020A0")
    s += rect(16, 78, 12, 4, "#402010")
    s += rect(34, 84, 14, 4, "#402010")
    s += svg_footer()
    return s

def bmage_left_idle():
    s = svg_header()
    s += rect(24, 0, 8, 4, "#2020A0")
    s += rect(20, 4, 16, 4, "#2020A0")
    s += rect(16, 8, 24, 8, "#2020A0")
    s += rect(10, 16, 32, 4, "#2020A0")
    s += rect(18, 20, 16, 10, "#301810")
    s += rect(20, 22, 4, 4, "#FFD700")
    s += rect(14, 30, 28, 30, "#2020A0")
    s += rect(20, 30, 16, 30, "#3030C0")
    s += rect(16, 30, 24, 4, "#4040D0")
    s += rect(6, 32, 10, 18, "#2020A0")
    s += rect(8, 50, 6, 6, "#806040")
    s += rect(16, 60, 12, 20, "#2020A0")
    s += rect(30, 60, 12, 20, "#2020A0")
    s += rect(14, 80, 12, 8, "#402010")
    s += rect(30, 80, 12, 8, "#402010")
    s += svg_footer()
    return s

def bmage_left_walk1():
    s = svg_header()
    s += rect(24, 0, 8, 4, "#2020A0")
    s += rect(20, 4, 16, 4, "#2020A0")
    s += rect(16, 8, 24, 8, "#2020A0")
    s += rect(10, 16, 32, 4, "#2020A0")
    s += rect(18, 20, 16, 10, "#301810")
    s += rect(20, 22, 4, 4, "#FFD700")
    s += rect(14, 30, 28, 30, "#2020A0")
    s += rect(20, 30, 16, 30, "#3030C0")
    s += rect(16, 30, 24, 4, "#4040D0")
    s += rect(4, 30, 10, 18, "#2020A0")
    s += rect(6, 48, 6, 6, "#806040")
    s += rect(10, 60, 14, 24, "#2020A0")
    s += rect(32, 60, 12, 18, "#2020A0")
    s += rect(8, 84, 14, 4, "#402010")
    s += rect(32, 78, 10, 4, "#402010")
    s += svg_footer()
    return s

def bmage_left_walk2():
    s = svg_header()
    s += rect(24, 0, 8, 4, "#2020A0")
    s += rect(20, 4, 16, 4, "#2020A0")
    s += rect(16, 8, 24, 8, "#2020A0")
    s += rect(10, 16, 32, 4, "#2020A0")
    s += rect(18, 20, 16, 10, "#301810")
    s += rect(20, 22, 4, 4, "#FFD700")
    s += rect(14, 30, 28, 30, "#2020A0")
    s += rect(20, 30, 16, 30, "#3030C0")
    s += rect(16, 30, 24, 4, "#4040D0")
    s += rect(8, 34, 10, 18, "#2020A0")
    s += rect(10, 52, 6, 6, "#806040")
    s += rect(20, 60, 12, 18, "#2020A0")
    s += rect(28, 60, 14, 24, "#2020A0")
    s += rect(20, 78, 10, 4, "#402010")
    s += rect(28, 84, 14, 4, "#402010")
    s += svg_footer()
    return s

def bmage_right_idle():
    s = svg_header()
    s += rect(32, 0, 8, 4, "#2020A0")
    s += rect(28, 4, 16, 4, "#2020A0")
    s += rect(24, 8, 24, 8, "#2020A0")
    s += rect(22, 16, 32, 4, "#2020A0")
    s += rect(30, 20, 16, 10, "#301810")
    s += rect(40, 22, 4, 4, "#FFD700")
    s += rect(22, 30, 28, 30, "#2020A0")
    s += rect(28, 30, 16, 30, "#3030C0")
    s += rect(24, 30, 24, 4, "#4040D0")
    s += rect(48, 32, 10, 18, "#2020A0")
    s += rect(50, 50, 6, 6, "#806040")
    s += rect(52, 8, 4, 48, "#604020")
    s += rect(48, 4, 12, 8, "#40C040")
    s += rect(52, 0, 4, 6, "#40C040")
    s += rect(22, 60, 12, 20, "#2020A0")
    s += rect(36, 60, 12, 20, "#2020A0")
    s += rect(22, 80, 12, 8, "#402010")
    s += rect(38, 80, 12, 8, "#402010")
    s += svg_footer()
    return s

def bmage_right_walk1():
    s = svg_header()
    s += rect(32, 0, 8, 4, "#2020A0")
    s += rect(28, 4, 16, 4, "#2020A0")
    s += rect(24, 8, 24, 8, "#2020A0")
    s += rect(22, 16, 32, 4, "#2020A0")
    s += rect(30, 20, 16, 10, "#301810")
    s += rect(40, 22, 4, 4, "#FFD700")
    s += rect(22, 30, 28, 30, "#2020A0")
    s += rect(28, 30, 16, 30, "#3030C0")
    s += rect(24, 30, 24, 4, "#4040D0")
    s += rect(50, 30, 10, 18, "#2020A0")
    s += rect(52, 48, 6, 6, "#806040")
    s += rect(54, 8, 4, 48, "#604020")
    s += rect(50, 4, 12, 8, "#40C040")
    s += rect(54, 0, 4, 6, "#40C040")
    s += rect(20, 60, 12, 18, "#2020A0")
    s += rect(36, 60, 14, 24, "#2020A0")
    s += rect(20, 78, 10, 4, "#402010")
    s += rect(36, 84, 14, 4, "#402010")
    s += svg_footer()
    return s

def bmage_right_walk2():
    s = svg_header()
    s += rect(32, 0, 8, 4, "#2020A0")
    s += rect(28, 4, 16, 4, "#2020A0")
    s += rect(24, 8, 24, 8, "#2020A0")
    s += rect(22, 16, 32, 4, "#2020A0")
    s += rect(30, 20, 16, 10, "#301810")
    s += rect(40, 22, 4, 4, "#FFD700")
    s += rect(22, 30, 28, 30, "#2020A0")
    s += rect(28, 30, 16, 30, "#3030C0")
    s += rect(24, 30, 24, 4, "#4040D0")
    s += rect(46, 34, 10, 18, "#2020A0")
    s += rect(48, 52, 6, 6, "#806040")
    s += rect(50, 12, 4, 48, "#604020")
    s += rect(46, 8, 12, 8, "#40C040")
    s += rect(50, 4, 4, 6, "#40C040")
    s += rect(26, 60, 14, 24, "#2020A0")
    s += rect(32, 60, 12, 18, "#2020A0")
    s += rect(26, 84, 14, 4, "#402010")
    s += rect(32, 78, 10, 4, "#402010")
    s += svg_footer()
    return s

# ── NPCs ──────────────────────────────────────────────────────────────────────

def npc_king():
    s = svg_header()
    # Crown
    s += rect(20, 2, 24, 4, "#FFD700")
    s += rect(22, 0, 4, 4, "#FFD700")
    s += rect(30, 0, 4, 4, "#FFD700")
    s += rect(38, 0, 4, 4, "#FFD700")
    # Crown jewels
    s += rect(24, 2, 4, 2, "#C02020")
    s += rect(32, 2, 4, 2, "#2020C0")
    # Hair
    s += rect(20, 6, 24, 6, "#806040")
    # Face
    s += rect(22, 12, 20, 14, "#F0C090")
    s += rect(26, 16, 4, 4, "#303030")
    s += rect(34, 16, 4, 4, "#303030")
    # Beard
    s += rect(24, 24, 16, 6, "#806040")
    # Cape/mantle
    s += rect(8, 30, 48, 36, "#6020A0")
    s += rect(10, 32, 44, 32, "#7030B0")
    # Royal tunic underneath
    s += rect(20, 30, 24, 30, "#FFD700")
    s += rect(24, 32, 16, 26, "#E8C020")
    # Royal sash
    s += rect(20, 56, 24, 4, "#C02020")
    # Arms (hidden by cape, just hands)
    s += rect(10, 60, 8, 6, "#F0C090")
    s += rect(46, 60, 8, 6, "#F0C090")
    # Legs
    s += rect(22, 60, 10, 20, "#6020A0")
    s += rect(32, 60, 10, 20, "#6020A0")
    # Royal shoes
    s += rect(20, 80, 12, 8, "#402010")
    s += rect(32, 80, 12, 8, "#402010")
    s += svg_footer()
    return s

def npc_princess():
    s = svg_header()
    # Tiara
    s += rect(24, 4, 16, 4, "#FFD700")
    s += rect(30, 2, 4, 4, "#FFD700")
    s += rect(30, 0, 4, 4, "#FF80C0")
    # Hair (long, flowing)
    s += rect(18, 8, 28, 16, "#FFD060")
    s += rect(16, 20, 8, 20, "#FFD060")
    s += rect(40, 20, 8, 20, "#FFD060")
    # Face
    s += rect(22, 16, 20, 12, "#F0C8A0")
    s += rect(26, 20, 4, 4, "#303030")
    s += rect(34, 20, 4, 4, "#303030")
    # Mouth
    s += rect(30, 26, 4, 2, "#D08080")
    # Dress - top
    s += rect(16, 28, 32, 12, "#FFB0D0")
    s += rect(24, 28, 16, 12, "#FFC0E0")
    # Necklace
    s += rect(26, 28, 12, 2, "#FFD700")
    # Dress - middle
    s += rect(12, 40, 40, 20, "#FFB0D0")
    s += rect(20, 40, 24, 20, "#FFC0E0")
    # Dress sash
    s += rect(22, 40, 20, 4, "#FF80C0")
    # Sleeves
    s += rect(8, 30, 10, 14, "#FFB0D0")
    s += rect(46, 30, 10, 14, "#FFB0D0")
    # Hands
    s += rect(10, 44, 6, 6, "#F0C8A0")
    s += rect(48, 44, 6, 6, "#F0C8A0")
    # Dress - bottom (flared)
    s += rect(8, 60, 48, 24, "#FFB0D0")
    s += rect(16, 60, 32, 24, "#FFC0E0")
    # Dress hem
    s += rect(8, 80, 48, 4, "#FF80C0")
    # Shoes (peeking out)
    s += rect(20, 84, 10, 4, "#FFD700")
    s += rect(34, 84, 10, 4, "#FFD700")
    s += svg_footer()
    return s

def npc_shopkeeper():
    s = svg_header()
    # Hat/bandana
    s += rect(20, 6, 24, 8, "#40A040")
    s += rect(22, 4, 20, 4, "#40A040")
    # Face
    s += rect(22, 14, 20, 14, "#F0C090")
    s += rect(26, 18, 4, 4, "#303030")
    s += rect(34, 18, 4, 4, "#303030")
    # Smile
    s += rect(28, 26, 8, 2, "#C08060")
    # Apron body
    s += rect(16, 28, 32, 32, "#F0E8D0")
    s += rect(24, 28, 16, 32, "#E8E0C0")
    # Apron straps
    s += rect(20, 28, 4, 10, "#E0D0A0")
    s += rect(40, 28, 4, 10, "#E0D0A0")
    # Shirt underneath (sleeves visible)
    s += rect(8, 30, 10, 16, "#C06020")
    s += rect(46, 30, 10, 16, "#C06020")
    # Hands
    s += rect(8, 46, 8, 6, "#F0C090")
    s += rect(48, 46, 8, 6, "#F0C090")
    # Apron pocket
    s += rect(26, 44, 12, 8, "#E0D0A0")
    # Belt
    s += rect(16, 56, 32, 4, "#604020")
    # Pants
    s += rect(20, 60, 10, 18, "#604020")
    s += rect(34, 60, 10, 18, "#604020")
    # Shoes
    s += rect(18, 78, 12, 8, "#402010")
    s += rect(34, 78, 12, 8, "#402010")
    s += svg_footer()
    return s

def npc_townsperson_a():
    """Male townsperson - brown hair, blue shirt"""
    s = svg_header()
    s += rect(22, 6, 20, 10, "#604020")
    s += rect(22, 16, 20, 12, "#F0C090")
    s += rect(26, 20, 4, 4, "#303030")
    s += rect(34, 20, 4, 4, "#303030")
    s += rect(16, 28, 32, 28, "#3060C0")
    s += rect(24, 28, 16, 28, "#4070D0")
    s += rect(8, 30, 10, 16, "#3060C0")
    s += rect(46, 30, 10, 16, "#3060C0")
    s += rect(8, 46, 8, 6, "#F0C090")
    s += rect(48, 46, 8, 6, "#F0C090")
    s += rect(16, 52, 32, 4, "#604020")
    s += rect(20, 56, 10, 22, "#806040")
    s += rect(34, 56, 10, 22, "#806040")
    s += rect(18, 78, 12, 8, "#402010")
    s += rect(34, 78, 12, 8, "#402010")
    s += svg_footer()
    return s

def npc_townsperson_b():
    """Female townsperson - red hair, green dress"""
    s = svg_header()
    s += rect(18, 4, 28, 14, "#C04020")
    s += rect(16, 14, 8, 16, "#C04020")
    s += rect(40, 14, 8, 16, "#C04020")
    s += rect(22, 14, 20, 14, "#F0C8A0")
    s += rect(26, 18, 4, 4, "#303030")
    s += rect(34, 18, 4, 4, "#303030")
    s += rect(14, 28, 36, 32, "#208040")
    s += rect(22, 28, 20, 32, "#309050")
    s += rect(6, 30, 10, 16, "#208040")
    s += rect(48, 30, 10, 16, "#208040")
    s += rect(8, 46, 6, 6, "#F0C8A0")
    s += rect(50, 46, 6, 6, "#F0C8A0")
    s += rect(20, 56, 24, 4, "#106030")
    s += rect(12, 60, 40, 24, "#208040")
    s += rect(20, 60, 24, 24, "#309050")
    s += rect(12, 80, 40, 4, "#106030")
    s += rect(22, 84, 8, 4, "#604020")
    s += rect(34, 84, 8, 4, "#604020")
    s += svg_footer()
    return s

def npc_townsperson_c():
    """Old man - gray hair, brown vest"""
    s = svg_header()
    s += rect(22, 4, 20, 8, "#C0C0C0")
    s += rect(20, 8, 6, 12, "#C0C0C0")
    s += rect(38, 8, 6, 12, "#C0C0C0")
    s += rect(22, 12, 20, 16, "#F0C090")
    s += rect(26, 16, 4, 4, "#303030")
    s += rect(34, 16, 4, 4, "#303030")
    # Mustache
    s += rect(26, 24, 12, 4, "#A0A0A0")
    # Vest
    s += rect(16, 28, 32, 28, "#604020")
    s += rect(24, 28, 16, 28, "#785030")
    # Shirt under vest
    s += rect(26, 30, 12, 24, "#E0D8C0")
    s += rect(8, 30, 10, 16, "#E0D8C0")
    s += rect(46, 30, 10, 16, "#E0D8C0")
    s += rect(8, 46, 8, 6, "#F0C090")
    s += rect(48, 46, 8, 6, "#F0C090")
    # Walking stick
    s += rect(52, 30, 4, 56, "#806020")
    s += rect(48, 28, 12, 4, "#806020")
    s += rect(16, 52, 32, 4, "#402010")
    s += rect(20, 56, 10, 22, "#505050")
    s += rect(34, 56, 10, 22, "#505050")
    s += rect(18, 78, 12, 8, "#402010")
    s += rect(34, 78, 12, 8, "#402010")
    s += svg_footer()
    return s

# ── GENERATION ────────────────────────────────────────────────────────────────

def write_svg(path, content):
    with open(path, 'w') as f:
        f.write(content)
    print(f"  SVG: {os.path.basename(path)}")

def export_png(svg_path, png_path, w=W, h=H):
    subprocess.run([
        "inkscape", svg_path,
        "--export-type=png",
        f"--export-filename={png_path}",
        f"-w", str(w), f"-h", str(h)
    ], capture_output=True)
    print(f"  PNG: {os.path.basename(png_path)}")

def make_sheet(char_dir, char_name, frames_map):
    """Create a sprite sheet from direction->frame function mapping."""
    COLS, ROWS = 3, 4
    sheet = Image.new('RGBA', (W * COLS, H * ROWS), (0, 0, 0, 0))
    directions = ['down', 'left', 'right', 'up']

    for row, direction in enumerate(directions):
        for col, suffix in enumerate(['idle', 'walk1', 'walk2']):
            key = f"{direction}_{suffix}"
            svg_path = os.path.join(char_dir, f"{char_name}_{key}.svg")
            png_path = os.path.join(char_dir, f"{char_name}_{key}_tmp.png")
            write_svg(svg_path, frames_map[key]())
            export_png(svg_path, png_path)
            img = Image.open(png_path)
            sheet.paste(img, (col * W, row * H))
            os.remove(png_path)

    sheet_path = os.path.join(char_dir, f"{char_name}_sheet.png")
    sheet.save(sheet_path)
    print(f"  SHEET: {sheet_path}")

def make_npc(npc_dir, name, svg_func):
    svg_path = os.path.join(npc_dir, f"{name}.svg")
    png_path = os.path.join(npc_dir, f"{name}.png")
    write_svg(svg_path, svg_func())
    export_png(svg_path, png_path)

# ── MAIN ──────────────────────────────────────────────────────────────────────

print("=== MONK ===")
monk_frames = {
    'down_idle': monk_down_idle, 'down_walk1': monk_down_walk1, 'down_walk2': monk_down_walk2,
    'up_idle': monk_up_idle, 'up_walk1': monk_up_walk1, 'up_walk2': monk_up_walk2,
    'left_idle': monk_left_idle, 'left_walk1': monk_left_walk1, 'left_walk2': monk_left_walk2,
    'right_idle': monk_right_idle, 'right_walk1': monk_right_walk1, 'right_walk2': monk_right_walk2,
}
make_sheet(f"{BASE}/monk", "monk", monk_frames)

print("\n=== WHITE MAGE ===")
wmage_frames = {
    'down_idle': wmage_down_idle, 'down_walk1': wmage_down_walk1, 'down_walk2': wmage_down_walk2,
    'up_idle': wmage_up_idle, 'up_walk1': wmage_up_walk1, 'up_walk2': wmage_up_walk2,
    'left_idle': wmage_left_idle, 'left_walk1': wmage_left_walk1, 'left_walk2': wmage_left_walk2,
    'right_idle': wmage_right_idle, 'right_walk1': wmage_right_walk1, 'right_walk2': wmage_right_walk2,
}
make_sheet(f"{BASE}/white_mage", "white_mage", wmage_frames)

print("\n=== BLACK MAGE ===")
bmage_frames = {
    'down_idle': bmage_down_idle, 'down_walk1': bmage_down_walk1, 'down_walk2': bmage_down_walk2,
    'up_idle': bmage_up_idle, 'up_walk1': bmage_up_walk1, 'up_walk2': bmage_up_walk2,
    'left_idle': bmage_left_idle, 'left_walk1': bmage_left_walk1, 'left_walk2': bmage_left_walk2,
    'right_idle': bmage_right_idle, 'right_walk1': bmage_right_walk1, 'right_walk2': bmage_right_walk2,
}
make_sheet(f"{BASE}/black_mage", "black_mage", bmage_frames)

print("\n=== NPCs ===")
npc_dir = f"{BASE}/npcs"
make_npc(npc_dir, "king", npc_king)
make_npc(npc_dir, "princess", npc_princess)
make_npc(npc_dir, "shopkeeper", npc_shopkeeper)
make_npc(npc_dir, "townsperson_a", npc_townsperson_a)
make_npc(npc_dir, "townsperson_b", npc_townsperson_b)
make_npc(npc_dir, "townsperson_c", npc_townsperson_c)

print("\nDone! All sprites generated.")
