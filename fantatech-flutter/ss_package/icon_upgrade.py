# -*- coding: utf-8 -*-
import sys, os, math
sys.stdout.reconfigure(encoding='utf-8')
from PIL import Image, ImageDraw, ImageFilter, ImageChops

SRC  = r"C:\Users\My laptop\Desktop\smarthome-hub\fantatech-flutter\assets\images\app_icon.png"
OUT  = r"C:\Users\My laptop\Desktop\smarthome-hub\fantatech-flutter\icon_upgrade_preview.png"
SAVE = r"C:\Users\My laptop\Desktop\smarthome-hub\fantatech-flutter\assets\images"

S = 1024  # working size

# ── helpers ──────────────────────────────────────────────────────────────────

def rounded_mask(size, radius_pct=0.22):
    r = int(size * radius_pct)
    m = Image.new("L", (size, size), 0)
    ImageDraw.Draw(m).rounded_rectangle([0,0,size-1,size-1], radius=r, fill=255)
    return m

def apply_mask(img, mask):
    out = img.convert("RGBA")
    out.putalpha(mask)
    return out

def vertical_gradient(size, top_color, bot_color):
    img = Image.new("RGB", (size, size))
    draw = ImageDraw.Draw(img)
    tr,tg,tb = top_color
    br,bg,bb = bot_color
    for y in range(size):
        t = y / (size - 1)
        r = int(tr + (br-tr)*t)
        g = int(tg + (bg-tg)*t)
        b = int(tb + (bb-tb)*t)
        draw.line([(0,y),(size-1,y)], fill=(r,g,b))
    return img

def radial_gradient(size, center_color, edge_color):
    img = Image.new("RGB", (size, size))
    cx, cy = size//2, size//2
    max_r = math.sqrt(2) * size / 2
    data = []
    cr,cg,cb = center_color
    er,eg,eb = edge_color
    for y in range(size):
        for x in range(size):
            d = math.sqrt((x-cx)**2 + (y-cy)**2) / max_r
            d = min(1, d)
            data.append((
                int(cr + (er-cr)*d),
                int(cg + (eg-cg)*d),
                int(cb + (eb-cb)*d),
            ))
    img.putdata(data)
    return img

def glow_around(house_rgba, bg_img, glow_color, glow_radius=40, glow_alpha=180):
    """Add a soft glow behind the house silhouette."""
    # Extract alpha of house and blur it for glow
    alpha = house_rgba.split()[3]
    glow_layer = Image.new("RGBA", bg_img.size, (0,0,0,0))
    glow_color_img = Image.new("RGBA", bg_img.size, glow_color + (glow_alpha,))
    # Use alpha as mask, blur for glow effect
    blurred_alpha = alpha.filter(ImageFilter.GaussianBlur(glow_radius))
    glow_layer.paste(glow_color_img, mask=blurred_alpha)
    result = Image.alpha_composite(bg_img.convert("RGBA"), glow_layer)
    return result

def composite(bg, house_rgba):
    result = bg.convert("RGBA")
    result = Image.alpha_composite(result, house_rgba)
    return result

# ── Load source icon and extract the house (remove background) ───────────────
src = Image.open(SRC).convert("RGBA").resize((S, S), Image.LANCZOS)
# The source already has rounded corners + house on blue bg
# We need to extract just the house element — use the existing icon directly
# and rebuild bg only

# Get house pixels (non-blue area) by threshold
src_rgb = src.convert("RGB")
px = src_rgb.load()
house_mask = Image.new("L", (S, S), 0)
hmask = house_mask.load()
for y in range(S):
    for x in range(S):
        r, g, b = px[x, y]
        # Blue background pixels: high blue, low red
        is_blue_bg = (b > 140 and r < 120 and g < 140) or (b > 160 and r < 160)
        if not is_blue_bg:
            hmask[x, y] = 255

# Clean up mask with slight blur + threshold
house_mask = house_mask.filter(ImageFilter.GaussianBlur(1))
house_rgba = src.copy()
house_rgba.putalpha(house_mask)

# ── Version 1: Deep Navy + Cyan Glow ─────────────────────────────────────────
bg1 = radial_gradient(S, (15, 35, 80), (5, 10, 40))
bg1_glow = glow_around(house_rgba, bg1, (0, 200, 255), glow_radius=45, glow_alpha=120)
v1 = Image.alpha_composite(bg1_glow, house_rgba)
v1 = apply_mask(v1, rounded_mask(S))

# ── Version 2: Purple-Blue gradient + gold glow ───────────────────────────────
bg2 = vertical_gradient(S, (30, 10, 80), (5, 20, 120))
# add subtle radial highlight
highlight = radial_gradient(S, (80, 40, 160), (20, 10, 80))
bg2 = Image.blend(bg2, highlight, 0.4)
bg2_glow = glow_around(house_rgba, bg2, (255, 200, 50), glow_radius=50, glow_alpha=100)
v2 = Image.alpha_composite(bg2_glow.convert("RGBA"), house_rgba)
v2 = apply_mask(v2, rounded_mask(S))

# ── Version 3: Dark charcoal + teal glow (matches app dark theme) ─────────────
bg3 = radial_gradient(S, (25, 45, 55), (8, 20, 28))
bg3_glow = glow_around(house_rgba, bg3, (0, 180, 180), glow_radius=55, glow_alpha=140)
v3 = Image.alpha_composite(bg3_glow.convert("RGBA"), house_rgba)
v3 = apply_mask(v3, rounded_mask(S))

# ── Version 4: Original blue + stronger glow (safe upgrade) ──────────────────
bg4 = radial_gradient(S, (20, 70, 200), (5, 25, 100))
bg4_glow = glow_around(house_rgba, bg4, (100, 200, 255), glow_radius=40, glow_alpha=160)
v4 = Image.alpha_composite(bg4_glow.convert("RGBA"), house_rgba)
v4 = apply_mask(v4, rounded_mask(S))

versions = [
    ("1 - Navy + Cyan Glow",    v1),
    ("2 - Purple + Gold Glow",  v2),
    ("3 - Dark + Teal Glow",    v3),
    ("4 - Blue+ (שדרוג עדין)",   v4),
]

# ── Save each version ────────────────────────────────────────────────────────
for label, img in versions:
    letter = label[0]
    p = os.path.join(SAVE, f"icon_v{letter}.png")
    img.save(p)
    print(f"Saved {p}")

# ── Preview grid: 4 versions × sizes 512, 256, 128, 64 ───────────────────────
SIZES  = [512, 256, 128, 64]
PAD    = 20
LPAD   = 220
COL_W  = 512 + PAD
ROW_H  = 512 + 40
C_W    = LPAD + len(SIZES) * COL_W + PAD
C_H    = len(versions) * (ROW_H + 30) + PAD * 2

canvas = Image.new("RGB", (C_W, C_H), (12, 12, 20))
draw   = ImageDraw.Draw(canvas)

y_off = PAD
for label, vimg in versions:
    draw.text((PAD, y_off + 8), label, fill=(220, 200, 100))
    x_off = LPAD
    for size in SIZES:
        sm = vimg.resize((size, size), Image.LANCZOS)
        tile = Image.new("RGB", (size, size), (20, 20, 30))
        tile.paste(sm, mask=sm.split()[3] if sm.mode == "RGBA" else None)
        canvas.paste(tile, (x_off, y_off + 30 + (512 - size) // 2))
        draw.text((x_off + size//2 - 14, y_off + 30 + 512 + 6), f"{size}px", fill=(100,100,120))
        x_off += COL_W
    y_off += ROW_H + 30

canvas.save(OUT)
print(f"\nPreview -> {OUT}")
