# Sprite Pipeline

Generated SVG sources live in `tools/sprites/svg/`.
Runtime PNG sheets are exported directly to `res://sprites/`.

Run from the project root:

```powershell
python tools/sprites/generate_sprites.py
```

Use a custom Inkscape path if needed:

```powershell
python tools/sprites/generate_sprites.py --inkscape "C:\Program Files\Inkscape\bin\inkscape.exe"
```
