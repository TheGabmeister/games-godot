from __future__ import annotations

from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
OUT_DIR = ROOT / "resources" / "sprite_frames"
CELL_SIZE = 32


SHEETS = {
    "player_frames": {
        "texture": "res://sprites/player_sheet.png",
        "columns": 6,
        "animations": {
            "small_idle": {"frames": [0], "fps": 1.0, "loop": False},
            "small_walk": {"frames": [1, 2], "fps": 8.0, "loop": True},
            "small_jump": {"frames": [3], "fps": 1.0, "loop": False},
            "small_death": {"frames": [4], "fps": 1.0, "loop": False},
            "big_idle": {"frames": [5], "fps": 1.0, "loop": False},
            "big_walk": {"frames": [6, 7], "fps": 8.0, "loop": True},
            "big_jump": {"frames": [8], "fps": 1.0, "loop": False},
            "big_crouch": {"frames": [9], "fps": 1.0, "loop": False},
            "big_flag": {"frames": [10], "fps": 1.0, "loop": False},
            "fire_idle": {"frames": [11], "fps": 1.0, "loop": False},
            "fire_walk": {"frames": [12, 13], "fps": 8.0, "loop": True},
            "fire_jump": {"frames": [14], "fps": 1.0, "loop": False},
            "fire_crouch": {"frames": [15], "fps": 1.0, "loop": False},
            "fire_flag": {"frames": [16], "fps": 1.0, "loop": False},
        },
    },
    "goomba_frames": {
        "texture": "res://sprites/goomba_sheet.png",
        "columns": 3,
        "animations": {
            "walk": {"frames": [0, 1], "fps": 8.0, "loop": True},
            "squished": {"frames": [2], "fps": 1.0, "loop": False},
        },
    },
    "koopa_frames": {
        "texture": "res://sprites/koopa_sheet.png",
        "columns": 3,
        "animations": {"walk": {"frames": [0, 1], "fps": 8.0, "loop": True}},
    },
    "koopa_shell_frames": {
        "texture": "res://sprites/koopa_shell_sheet.png",
        "columns": 4,
        "animations": {
            "idle": {"frames": [0], "fps": 1.0, "loop": False},
            "spin": {"frames": [0, 1, 2, 3], "fps": 8.0, "loop": True},
        },
    },
    "piranha_plant_frames": {
        "texture": "res://sprites/piranha_plant_sheet.png",
        "columns": 4,
        "animations": {"emerge": {"frames": [0, 1, 2, 3], "fps": 1.0, "loop": False}},
    },
    "coin_frames": {
        "texture": "res://sprites/coin_sheet.png",
        "columns": 4,
        "animations": {"spin": {"frames": [0, 1, 2, 3], "fps": 6.0, "loop": True}},
    },
    "blocks_frames": {
        "texture": "res://sprites/blocks_sheet.png",
        "columns": 6,
        "animations": {
            "question_active": {"frames": [0, 1, 2], "fps": 3.0, "loop": True},
            "question_used": {"frames": [3], "fps": 1.0, "loop": False},
            "brick_active": {"frames": [4], "fps": 1.0, "loop": False},
            "brick_used": {"frames": [5], "fps": 1.0, "loop": False},
            "used": {"frames": [3], "fps": 1.0, "loop": False},
        },
    },
    "powerups_frames": {
        "texture": "res://sprites/powerups_sheet.png",
        "columns": 5,
        "animations": {
            "red": {"frames": [0], "fps": 1.0, "loop": False},
            "1up": {"frames": [1], "fps": 1.0, "loop": False},
            "pulse": {"frames": [2, 3, 4], "fps": 6.0, "loop": True},
        },
    },
    "starman_frames": {
        "texture": "res://sprites/starman_sheet.png",
        "columns": 3,
        "animations": {"cycle": {"frames": [0, 1, 2], "fps": 6.0, "loop": True}},
    },
    "fireball_frames": {
        "texture": "res://sprites/fireball_sheet.png",
        "columns": 4,
        "animations": {"spin": {"frames": [0, 1, 2, 3], "fps": 12.0, "loop": True}},
    },
    "effects_frames": {
        "texture": "res://sprites/effects_sheet.png",
        "columns": 6,
        "animations": {
            "brick": {"frames": [0], "fps": 1.0, "loop": False},
            "puff": {"frames": [1], "fps": 1.0, "loop": False},
            "ring": {"frames": [3], "fps": 1.0, "loop": False},
            "trail": {"frames": [4], "fps": 1.0, "loop": False},
        },
    },
    "score_digits_frames": {
        "texture": "res://sprites/score_digits_sheet.png",
        "columns": 10,
        "animations": {str(i): {"frames": [i], "fps": 1.0, "loop": False} for i in range(10)},
    },
    "pipe_frames": {
        "texture": "res://sprites/pipe_sheet.png",
        "columns": 2,
        "animations": {
            "cap": {"frames": [0], "fps": 1.0, "loop": False},
            "body": {"frames": [1], "fps": 1.0, "loop": False},
        },
    },
    "flagpole_frames": {
        "texture": "res://sprites/flagpole_sheet.png",
        "columns": 4,
        "animations": {
            "pole": {"frames": [0], "fps": 1.0, "loop": False},
            "ball": {"frames": [1], "fps": 1.0, "loop": False},
            "flag": {"frames": [2], "fps": 1.0, "loop": False},
            "base": {"frames": [3], "fps": 1.0, "loop": False},
        },
    },
    "castle_frames": {
        "texture": "res://sprites/castle_sheet.png",
        "columns": 1,
        "animations": {"default": {"frames": [0], "fps": 1.0, "loop": False}},
    },
    "background_decor_frames": {
        "texture": "res://sprites/background_decor_sheet.png",
        "columns": 3,
        "animations": {
            "cloud": {"frames": [0], "fps": 1.0, "loop": False},
            "hill": {"frames": [1], "fps": 1.0, "loop": False},
            "bush": {"frames": [2], "fps": 1.0, "loop": False},
        },
    },
}


def atlas_id(sheet_name: str, idx: int) -> str:
    return f"AtlasTexture_{sheet_name}_{idx}"


def atlas_region(idx: int, columns: int) -> str:
    x = (idx % columns) * CELL_SIZE
    y = (idx // columns) * CELL_SIZE
    return f"Rect2({x}, {y}, {CELL_SIZE}, {CELL_SIZE})"


def bool_text(value: bool) -> str:
    return "true" if value else "false"


def render_resource(name: str, spec: dict) -> str:
    animations = spec["animations"]
    all_indices = sorted({idx for anim in animations.values() for idx in anim["frames"]})
    atlas_lookup = {idx: atlas_id(name, idx) for idx in all_indices}
    load_steps = 2 + len(all_indices)

    lines = [
        f'[gd_resource type="SpriteFrames" load_steps={load_steps} format=3]',
        "",
        f'[ext_resource type="Texture2D" path="{spec["texture"]}" id="1_texture"]',
        "",
    ]
    for idx in all_indices:
        lines.extend([
            f'[sub_resource type="AtlasTexture" id="{atlas_lookup[idx]}"]',
            'atlas = ExtResource("1_texture")',
            f"region = {atlas_region(idx, spec['columns'])}",
            "",
        ])

    lines.extend(["[resource]", "animations = [{"])
    rendered_anims: list[str] = []
    for anim_name, anim in animations.items():
        frame_lines = []
        for idx in anim["frames"]:
            frame_lines.append(
                '{\n"duration": 1.0,\n"texture": SubResource("%s")\n}' % atlas_lookup[idx]
            )
        rendered_anims.append(
            '"frames": [%s],\n"loop": %s,\n"name": &"%s",\n"speed": %.1f'
            % (", ".join(frame_lines), bool_text(anim["loop"]), anim_name, anim["fps"])
        )
    lines.append("}, {\n".join(rendered_anims))
    lines.append("}]")
    lines.append("")
    return "\n".join(lines)


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    for name, spec in SHEETS.items():
        path = OUT_DIR / f"{name}.tres"
        path.write_text(render_resource(name, spec), encoding="utf-8")
        print(f"wrote {path.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
