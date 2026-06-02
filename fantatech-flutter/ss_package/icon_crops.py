# -*- coding: utf-8 -*-
import sys, os
sys.stdout.reconfigure(encoding='utf-8')
from PIL import Image, ImageDraw, ImageFont

src_path = r"C:\Users\My laptop\Desktop\smarthome-hub\fantatech-flutter\assets\images\icon_extract_1.png"
out_path = r"C:\Users\My laptop\Desktop\smarthome-hub\fantatech-flutter\icon_crops_preview.png"

src = Image.open(src_path).convert("RGBA")
W, H = src.size  # 1620 x 1080
print(f"Source: {W}x{H}")

def rounded_icon(img, size, radius_pct=0.22):
    r = int(size * radius_pct)
    icon = img.resize((size, size), Image.LANCZOS)
    mask = Image.new("L", (size, size), 0)
    d = ImageDraw.Draw(mask)
    d.rounded_rectangle([0, 0, size-1, size-1], radius=r, fill=255)
    result = Image.new("RGBA", (size, size), (0,0,0,0))
    result.paste(icon, mask=mask)
    return result

# Define 3 crop options
crops = {
    "A - מרכז (Center crop)":
        src.crop(((W - H) // 2, 0, (W - H) // 2 + H, H)),

    "B - בית (House focus - right half)":
        src.crop((W // 2 - 50, 0, W, H)),          # right ~half: house + some icons

    "C - כל התמונה (Full image, letterbox)": (
        lambda: (
            lambda canvas: (
                canvas.paste(src.resize((W * 1080 // H, 1080), Image.LANCZOS),
                             ((1080 - W * 1080 // H) // 2, 0)),
                canvas
            )[-1]
        )(Image.new("RGBA", (1080, 1080), (30, 120, 220, 255)))
    )(),
}

# Preview canvas: 3 options × 5 sizes
SIZES  = [512, 256, 128, 64, 48]
PAD    = 16
COL_W  = 512 + PAD
ROW_H  = 512 + 30 + PAD
ROWS   = len(crops)
COLS   = len(SIZES)
C_W    = COLS * COL_W + PAD + 180   # +180 for label column
C_H    = ROWS * (ROW_H + 24) + PAD * 2

canvas = Image.new("RGB", (C_W, C_H), (14, 14, 24))
draw   = ImageDraw.Draw(canvas)

y = PAD
for label, crop_img in crops.items():
    # Row label
    draw.text((PAD, y + 4), label, fill=(220, 200, 100))
    x = 180
    for size in SIZES:
        icon = rounded_icon(crop_img, size)
        # place on dark bg tile
        tile = Image.new("RGB", (size, size), (24, 40, 80))
        tile.paste(icon, mask=icon.split()[3])
        iy = y + 24 + (512 - size) // 2
        canvas.paste(tile, (x, iy))
        draw.text((x + size // 2 - 14, iy + size + 4), f"{size}px", fill=(100, 100, 120))
        x += COL_W
    y += ROW_H + 24

canvas.save(out_path)
print(f"Saved: {out_path}")

# Also save each crop as individual 1024px icon
for label, crop_img in crops.items():
    letter = label[0]
    p = f"C:\\Users\\My laptop\\Desktop\\smarthome-hub\\fantatech-flutter\\assets\\images\\icon_crop_{letter}.png"
    crop_img.resize((1024, 1024), Image.LANCZOS).save(p)
    print(f"  Saved crop {letter} -> {p}")
