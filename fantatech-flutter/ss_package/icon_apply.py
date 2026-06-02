# -*- coding: utf-8 -*-
import sys, os, math
sys.stdout.reconfigure(encoding='utf-8')
from PIL import Image, ImageDraw, ImageFilter
import numpy as np

SRC   = r"C:\Users\My laptop\Desktop\smarthome-hub\fantatech-flutter\assets\images\icon_extract_1.png"
SAVE  = r"C:\Users\My laptop\Desktop\smarthome-hub\fantatech-flutter\assets\images"
PREV  = r"C:\Users\My laptop\Desktop\smarthome-hub\fantatech-flutter\icon_final_preview.png"

src = Image.open(SRC).convert("RGBA")
W, H = src.size   # 1620 x 1080
print(f"Source: {W}x{H}")

# ── Best crop: slight left shift to include more IoT icons ────────────────
# Center crop would be [270,0,1350,1080]
# Shift 120px left to include more left-side icons (lightning, bulb, etc.)
# New crop: [150, 0, 1230, 1080]
x0, x1 = 120, 1200   # 1080px wide
crop = src.crop((x0, 0, x1, H))   # 1080x1080
print(f"Crop: [{x0},0,{x1},{H}]  -> {crop.size}")

# ── Add subtle dark vignette on edges to focus center ─────────────────────
arr = np.array(crop.convert("RGB"), dtype=np.float32)
cx, cy = H//2, H//2
max_r  = H * 0.72  # vignette starts at 72% from center
vig    = np.zeros((H, H), dtype=np.float32)
for y in range(H):
    for x in range(H):
        d = math.sqrt((x-cx)**2 + (y-cy)**2)
        t = max(0, (d - max_r*0.5) / (max_r*0.5))
        vig[y,x] = min(1, t*t*0.35)   # max 35% darkening
arr[...,0] *= (1 - vig)
arr[...,1] *= (1 - vig)
arr[...,2] *= (1 - vig)
crop_vig = Image.fromarray(arr.clip(0,255).astype(np.uint8))

def rounded_icon(img, size, radius_pct=0.215):
    r = int(size * radius_pct)
    ico = img.resize((size, size), Image.LANCZOS)
    mask = Image.new("L", (size, size), 0)
    ImageDraw.Draw(mask).rounded_rectangle([0,0,size-1,size-1], radius=r, fill=255)
    result = Image.new("RGBA", (size, size), (0,0,0,0))
    result.paste(ico.convert("RGBA"), mask=mask)
    return result

# ── Final 1024x1024 icon ─────────────────────────────────────────────────
icon_1024 = rounded_icon(crop_vig, 1024)
final_path = os.path.join(SAVE, "app_icon_new.png")
icon_1024.save(final_path)
print(f"Final icon -> {final_path}")

# ── Preview: show at key sizes on dark background ─────────────────────────
SIZES = [1024, 512, 192, 128, 64, 48]
PAD   = 20
total_w = sum(s + PAD for s in SIZES) + PAD
total_h = 1024 + 80

canvas = Image.new("RGB", (total_w, total_h), (12, 12, 20))
draw   = ImageDraw.Draw(canvas)

x = PAD
for sz in SIZES:
    ico  = rounded_icon(crop_vig, sz)
    tile = Image.new("RGB", (sz, sz), (22, 22, 32))
    tile.paste(ico, mask=ico.split()[3])
    iy   = PAD + (1024 - sz) // 2
    canvas.paste(tile, (x, iy))
    label = f"{sz}px"
    draw.text((x + sz//2 - len(label)*3, iy + sz + 5), label, fill=(100,100,120))
    x += sz + PAD

canvas.save(PREV)
print(f"Preview -> {PREV}")
