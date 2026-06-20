#!/usr/bin/env python3
"""Generates branded Pawsome MSIX logo assets (purple->blue gradient + paw).

Pure standard-library (zlib) PNG writer with 3x supersampling for smooth edges.
Run:  python3 tools/generate_assets.py
"""
import math, struct, zlib, os

OUT = os.path.join(os.path.dirname(__file__), "..", "Pawsome.App", "Assets")
PURPLE = (124, 58, 237)   # #7c3aed
BLUE = (37, 99, 235)      # #2563eb
WHITE = (255, 255, 255)


def lerp(a, b, t):
    return tuple(int(round(a[i] + (b[i] - a[i]) * t)) for i in range(3))


def inside_circle(px, py, cx, cy, r):
    return (px - cx) ** 2 + (py - cy) ** 2 <= r * r


def render(w, h, transparent_bg=False):
    """Returns an RGBA pixel buffer rendered at 3x then box-downsampled."""
    ss = 3
    W, H = w * ss, h * ss
    buf = bytearray(W * H * 4)

    # Paw geometry (relative to min dimension), centered.
    m = min(W, H)
    cx, cy = W / 2, H / 2
    pad_r = m * 0.20
    pad_cy = cy + m * 0.12
    toe_r = m * 0.085
    toes = [(-0.20, -0.16), (-0.07, -0.26), (0.07, -0.26), (0.20, -0.16)]

    for y in range(H):
        for x in range(W):
            t = (x + y) / (W + H)             # diagonal gradient
            bg = lerp(PURPLE, BLUE, t)
            i = (y * W + x) * 4
            if transparent_bg:
                r, g, b, a = 0, 0, 0, 0
            else:
                r, g, b, a = bg[0], bg[1], bg[2], 255

            # Paw pad + toes in white.
            paw = inside_circle(x, y, cx, pad_cy, pad_r)
            if not paw:
                for dx, dy in toes:
                    if inside_circle(x, y, cx + dx * m, cy + dy * m, toe_r):
                        paw = True
                        break
            if paw:
                r, g, b, a = WHITE[0], WHITE[1], WHITE[2], 255

            buf[i:i + 4] = bytes((r, g, b, a))

    # Box downsample ss x ss -> final.
    out = bytearray(w * h * 4)
    for y in range(h):
        for x in range(w):
            acc = [0, 0, 0, 0]
            for sy in range(ss):
                for sx in range(ss):
                    si = ((y * ss + sy) * W + (x * ss + sx)) * 4
                    for c in range(4):
                        acc[c] += buf[si + c]
            oi = (y * w + x) * 4
            for c in range(4):
                out[oi + c] = acc[c] // (ss * ss)
    return out


def write_png(path, w, h, rgba):
    def chunk(tag, data):
        return (struct.pack(">I", len(data)) + tag + data +
                struct.pack(">I", zlib.crc32(tag + data) & 0xffffffff))

    raw = bytearray()
    for y in range(h):
        raw.append(0)  # filter type 0
        raw += rgba[y * w * 4:(y + 1) * w * 4]

    png = (b"\x89PNG\r\n\x1a\n" +
           chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 6, 0, 0, 0)) +
           chunk(b"IDAT", zlib.compress(bytes(raw), 9)) +
           chunk(b"IEND", b""))
    with open(path, "wb") as f:
        f.write(png)
    print("wrote", os.path.relpath(path), f"{w}x{h}")


# name -> (w, h, transparent background?)
ASSETS = {
    "Square44x44Logo.png": (44, 44, False),
    "Square71x71Logo.png": (71, 71, False),
    "Square150x150Logo.png": (150, 150, False),
    "Square310x310Logo.png": (310, 310, False),
    "Wide310x150Logo.png": (310, 150, False),
    "StoreLogo.png": (50, 50, False),
    "SplashScreen.png": (620, 300, False),
    "LockScreenLogo.png": (24, 24, True),
    "Square44x44Logo.targetsize-24_altform-unplated.png": (24, 24, True),
    "AppIcon.png": (256, 256, False),
}

os.makedirs(OUT, exist_ok=True)
for name, (w, h, tb) in ASSETS.items():
    write_png(os.path.join(OUT, name), w, h, render(w, h, tb))
print("done.")
