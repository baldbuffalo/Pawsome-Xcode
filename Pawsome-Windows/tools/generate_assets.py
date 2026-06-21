#!/usr/bin/env python3
"""Generate Windows MSIX tile/icon assets + app.ico for Pawsome.

Source of truth: Pawsome.App/Assets/icon-source.png (a square copy of the iOS
AppIcon). For Windows we crop that icon down to its paw-heart mark on a
transparent background, because the full Apple icon (lots of white margin + fine
text) is illegible at small Explorer/taskbar icon sizes. The mark stays crisp at
every size, on light or dark.

Run: python3 tools/generate_assets.py   (requires Pillow)
"""
import os
from PIL import Image

HERE = os.path.dirname(__file__)
ASSETS = os.path.join(HERE, "..", "Pawsome.App", "Assets")
SOURCE = os.path.join(ASSETS, "icon-source.png")

WHITE = (255, 255, 255, 255)
WHITE_CUTOFF = 232  # pixels brighter than this (the icon's white field) become transparent


def build_mark() -> Image.Image:
    """Crop the source icon to its red paw-heart and knock out the white field."""
    src = Image.open(SOURCE).convert("RGBA")
    px = src.load()
    w, h = src.size

    # Bounding box of the red artwork (the paw + heart; the text is blue).
    minx, miny, maxx, maxy = w, h, 0, 0
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if r > 120 and g < 110 and b < 110 and a > 10:
                minx, miny = min(minx, x), min(miny, y)
                maxx, maxy = max(maxx, x), max(maxy, y)

    cx, cy = (minx + maxx) // 2, (miny + maxy) // 2
    half = int(max(maxx - minx, maxy - miny) * 0.62)  # square crop + breathing room
    crop = src.crop((cx - half, cy - half, cx + half, cy + half)).convert("RGBA")

    # Make the white background transparent so the mark reads on any surface.
    out = crop.load()
    cw, ch = crop.size
    for y in range(ch):
        for x in range(cw):
            r, g, b, a = out[x, y]
            if r >= WHITE_CUTOFF and g >= WHITE_CUTOFF and b >= WHITE_CUTOFF:
                out[x, y] = (r, g, b, 0)
    return crop


def square(mark: Image.Image, size: int) -> Image.Image:
    return mark.resize((size, size), Image.LANCZOS)


def wide(mark: Image.Image, width: int, height: int) -> Image.Image:
    canvas = Image.new("RGBA", (width, height), WHITE)
    side = int(height * 0.78)
    logo = mark.resize((side, side), Image.LANCZOS)
    canvas.alpha_composite(logo, ((width - side) // 2, (height - side) // 2))
    return canvas


SQUARE_ASSETS = {
    "Square44x44Logo.png": 44,
    "Square71x71Logo.png": 71,
    "Square150x150Logo.png": 150,
    "Square310x310Logo.png": 310,
    "StoreLogo.png": 50,
    "LockScreenLogo.png": 24,
    "Square44x44Logo.targetsize-24_altform-unplated.png": 24,
    "AppIcon.png": 256,
}

WIDE_ASSETS = {
    "Wide310x150Logo.png": (310, 150),
    "SplashScreen.png": (620, 300),
}

mark = build_mark()
mark.save(os.path.join(ASSETS, "icon-mark.png"))
print("built paw mark", mark.size)

for name, size in SQUARE_ASSETS.items():
    square(mark, size).save(os.path.join(ASSETS, name))
    print("wrote", name, f"{size}x{size}")

for name, (w, h) in WIDE_ASSETS.items():
    wide(mark, w, h).save(os.path.join(ASSETS, name))
    print("wrote", name, f"{w}x{h}")

ico_sizes = [(s, s) for s in (16, 24, 32, 48, 64, 128, 256)]
mark.save(os.path.join(ASSETS, "app.ico"), sizes=ico_sizes)
print("wrote app.ico", ico_sizes)
print("done.")
