# -*- coding: utf-8 -*-
import sys, os
sys.stdout.reconfigure(encoding='utf-8')
from PIL import Image, ImageDraw

ORIG = r"C:\Users\My laptop\Desktop\smarthome-hub\fantatech-flutter\assets\images\app_icon_original_backup.png"
NEW  = r"C:\Users\My laptop\Desktop\smarthome-hub\fantatech-flutter\assets\images\app_icon.png"
OUT  = r"C:\Users\My laptop\Desktop\smarthome-hub\fantatech-flutter\icon_before_after.png"

def rounded(img, size, r_pct=0.215):
    r = int(size * r_pct)
    ico = img.resize((size, size), Image.LANCZOS).convert("RGBA")
    mask = Image.new("L", (size, size), 0)
    ImageDraw.Draw(mask).rounded_rectangle([0,0,size-1,size-1], radius=r, fill=255)
    out = Image.new("RGBA", (size, size), (0,0,0,0))
    out.paste(ico, mask=mask)
    return out

orig = Image.open(ORIG)
new  = Image.open(NEW)

SIZES = [512, 192, 128, 64]
PAD   = 24
LBL   = 60
COL   = 512 + PAD

# canvas: 2 rows (before / after), columns = sizes
W = LBL + len(SIZES) * COL + PAD
H = PAD + LBL + 512 + PAD + LBL + 512 + PAD + 40

canvas = Image.new("RGB", (W, H), (10, 10, 18))
draw   = ImageDraw.Draw(canvas)

def paste_row(img, label, y_top):
    draw.text((PAD, y_top), label, fill=(255, 220, 80))
    x = LBL
    for sz in SIZES:
        ico  = rounded(img, sz)
        tile = Image.new("RGB", (sz, sz), (22, 22, 32))
        tile.paste(ico, mask=ico.split()[3])
        iy = y_top + LBL + (512 - sz) // 2
        canvas.paste(tile, (x, iy))
        draw.text((x + sz//2 - 14, iy + sz + 5), f"{sz}px", fill=(90, 90, 110))
        x += COL

paste_row(orig, "BEFORE  (לפני)", PAD)
paste_row(new,  "AFTER   (אחרי)",  PAD + LBL + 512 + PAD)

# Divider line
dy = PAD + LBL + 512 + PAD // 2
draw.line([(0, dy), (W, dy)], fill=(40, 40, 60), width=2)

canvas.save(OUT)
print(f"Saved: {OUT}")
