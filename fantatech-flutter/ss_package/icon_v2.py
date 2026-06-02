# -*- coding: utf-8 -*-
import sys, os, math
sys.stdout.reconfigure(encoding='utf-8')
from PIL import Image, ImageDraw, ImageFilter, ImageEnhance
import numpy as np

SRC  = r"C:\Users\My laptop\Desktop\smarthome-hub\fantatech-flutter\assets\images\app_icon.png"
SAVE = r"C:\Users\My laptop\Desktop\smarthome-hub\fantatech-flutter\assets\images"
OUT  = r"C:\Users\My laptop\Desktop\smarthome-hub\fantatech-flutter\icon_upgrade_preview.png"

S = 1024

def rounded_mask(size, radius_pct=0.22):
    r = int(size * radius_pct)
    m = Image.new("L", (size, size), 0)
    ImageDraw.Draw(m).rounded_rectangle([0,0,size-1,size-1], radius=r, fill=255)
    return m

def make_gradient(size, stops):
    """stops = list of (y_fraction, (R,G,B))"""
    img = Image.new("RGB", (size, size))
    draw = ImageDraw.Draw(img)
    for y in range(size):
        t = y / (size - 1)
        # find surrounding stops
        c1, c2 = stops[0][1], stops[-1][1]
        f = 0.0
        for i in range(len(stops)-1):
            t0, col0 = stops[i]
            t1, col1 = stops[i+1]
            if t0 <= t <= t1:
                f = (t - t0) / (t1 - t0)
                c1, c2 = col0, col1
                break
        r = int(c1[0] + (c2[0]-c1[0])*f)
        g = int(c1[1] + (c2[1]-c1[1])*f)
        b = int(c1[2] + (c2[2]-c1[2])*f)
        draw.line([(0,y),(size-1,y)], fill=(r,g,b))
    return img

def replace_background(src_path, new_bg, hue_shift_house=None):
    """
    Replace the blue background of the icon with new_bg.
    Detect blue pixels using HSV distance and replace them.
    """
    src = Image.open(src_path).convert("RGBA").resize((S,S), Image.LANCZOS)
    arr = np.array(src, dtype=float)
    bg  = np.array(new_bg.convert("RGBA").resize((S,S)), dtype=float)

    R, G, B, A = arr[...,0], arr[...,1], arr[...,2], arr[...,3]

    # Blue-background detection: high B relative to R,G + saturation
    # bg_mask = 1.0 where pixel is "background blue"
    max_rgb = np.maximum(np.maximum(R, G), B) + 1e-6
    blueness = B / max_rgb          # 0..1, 1 = pure blue
    redness  = R / max_rgb
    greenness = G / max_rgb

    # bg pixel: blue dominant, not too light (not the white house)
    brightness = (R + G + B) / 3.0
    bg_mask = (
        (blueness > 0.45) &
        (redness  < 0.55) &
        (brightness < 210)
    ).astype(float)

    # Soften edges
    bg_mask_img = Image.fromarray((bg_mask * 255).astype(np.uint8))
    bg_mask_img = bg_mask_img.filter(ImageFilter.GaussianBlur(2))
    bg_mask_soft = np.array(bg_mask_img, dtype=float) / 255.0

    # Blend: result = new_bg * mask + original * (1-mask)
    result = arr.copy()
    for c in range(3):
        result[...,c] = bg[...,c] * bg_mask_soft + arr[...,c] * (1 - bg_mask_soft)
    result[...,3] = 255

    out = Image.fromarray(result.astype(np.uint8), "RGBA")

    # Apply rounded mask
    mask = rounded_mask(S)
    out.putalpha(mask)
    return out

# ── Define versions ───────────────────────────────────────────────────────────

# V1: Deep navy → midnight blue  +  cyan glow on WiFi dots
bg1 = make_gradient(S, [(0,(8,20,60)), (0.5,(15,40,110)), (1,(5,12,45))])
v1  = replace_background(SRC, bg1)

# V2: Deep indigo-purple gradient
bg2 = make_gradient(S, [(0,(25,10,80)), (0.45,(18,15,100)), (1,(8,5,55))])
v2  = replace_background(SRC, bg2)

# V3: Dark charcoal with teal tint (matches app dark theme #0D1117 → teal)
bg3 = make_gradient(S, [(0,(14,30,38)), (0.5,(10,25,35)), (1,(6,15,28))])
v3  = replace_background(SRC, bg3)

# V4: Richer blue (safer upgrade — stays closest to original)
bg4 = make_gradient(S, [(0,(10,55,180)), (0.6,(8,40,150)), (1,(4,20,90))])
v4  = replace_background(SRC, bg4)

# V5: Near-black premium (dark mode feel)
bg5 = make_gradient(S, [(0,(20,20,40)), (0.5,(12,12,30)), (1,(6,8,22))])
v5  = replace_background(SRC, bg5)

versions = [
    ("1  Navy + Dark Blue",      v1),
    ("2  Deep Indigo",           v2),
    ("3  Dark Teal (app theme)", v3),
    ("4  Rich Blue (safe)",      v4),
    ("5  Near-black Premium",    v5),
]

# ── Save ──────────────────────────────────────────────────────────────────────
for label, img in versions:
    n = label[0]
    p = os.path.join(SAVE, f"icon_v{n}.png")
    img.save(p)
    print(f"Saved {p}")

# ── Preview grid ──────────────────────────────────────────────────────────────
SIZES = [512, 256, 128, 64]
PAD   = 18
LPAD  = 230
C_W   = LPAD + len(SIZES)*(512+PAD) + PAD
C_H   = len(versions)*(512+60) + PAD*2

canvas = Image.new("RGB", (C_W, C_H), (10,10,18))
draw   = ImageDraw.Draw(canvas)

y_off = PAD
for label, vimg in versions:
    draw.text((PAD, y_off+10), label, fill=(220,200,80))
    x_off = LPAD
    for sz in SIZES:
        sm   = vimg.resize((sz, sz), Image.LANCZOS)
        tile = Image.new("RGB", (sz, sz), (18,18,28))
        tile.paste(sm, mask=sm.split()[3])
        iy   = y_off + 30 + (512-sz)//2
        canvas.paste(tile, (x_off, iy))
        draw.text((x_off+sz//2-14, iy+sz+4), f"{sz}px", fill=(90,90,110))
        x_off += 512+PAD
    y_off += 512+60

canvas.save(OUT)
print(f"\nPreview -> {OUT}")
