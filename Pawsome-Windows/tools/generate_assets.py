#!/usr/bin/env python3
"""Generate the Windows MSIX tile/icon assets + app.ico from the shared Pawsome
app icon (the same icon the iOS/macOS app uses), so branding is identical on
every platform.

Source: Pawsome.App/Assets/icon-source.png  (a square copy of the iOS AppIcon)
Run:    python3 tools/generate_assets.py     (requires Pillow)
"""
import os
from PIL import Image

HERE = os.path.dirname(__file__)
ASSETS = os.path.join(HERE, "..", "Pawsome.App", "Assets")
SOURCE = os.path.join(ASSETS, "icon-source.png")

# The icon artwork sits on a white field, so wide/splash tiles use white too.
BG = (255, 255, 255, 255)


def source() -> Image.Image:
    return Image.open(SOURCE).convert("RGBA")


def square(size: int) -> Image.Image:
    return source().resize((size, size), Image.LANCZOS)


def wide(width: int, height: int) -> Image.Image:
    canvas = Image.new("RGBA", (width, height), BG)
    side = int(height * 0.92)
    logo = source().resize((side, side), Image.LANCZOS)
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

os.makedirs(ASSETS, exist_ok=True)

for name, size in SQUARE_ASSETS.items():
    square(size).save(os.path.join(ASSETS, name))
    print("wrote", name, f"{size}x{size}")

for name, (w, h) in WIDE_ASSETS.items():
    wide(w, h).save(os.path.join(ASSETS, name))
    print("wrote", name, f"{w}x{h}")

# Multi-resolution Windows .ico for the window/taskbar/exe icon.
ico_sizes = [(s, s) for s in (16, 32, 48, 64, 128, 256)]
source().save(os.path.join(ASSETS, "app.ico"), sizes=ico_sizes)
print("wrote app.ico", ico_sizes)
print("done.")
