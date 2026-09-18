#!/usr/bin/env python3
"""Generates the MyPri app icon: the Sword of Damocles hanging by a thread,
symbolizing priorities that demand constant attention. Charcoal background
with electric blue -> purple gradient sword."""

import math
from PIL import Image, ImageDraw, ImageFilter

SIZE = 1024
CX = SIZE // 2

BG_TOP = (37, 37, 46)
BG_BOTTOM = (18, 18, 22)
BLUE = (34, 195, 255)
PURPLE = (177, 92, 255)
STEEL_LIGHT = (226, 235, 245)
STEEL_DARK = (150, 165, 185)
THREAD = (214, 214, 224)


def lerp(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))


def rounded_mask(size, radius):
    mask = Image.new("L", (size, size), 0)
    d = ImageDraw.Draw(mask)
    d.rounded_rectangle([0, 0, size - 1, size - 1], radius=radius, fill=255)
    return mask


def make_background_fast():
    top = Image.new("RGBA", (1, SIZE), (0, 0, 0, 255))
    for y in range(SIZE):
        t = y / (SIZE - 1)
        top.putpixel((0, y), (*lerp(BG_TOP, BG_BOTTOM, t), 255))
    return top.resize((SIZE, SIZE))


def add_glow(base, center, radius, color, alpha, blur):
    glow = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    d = ImageDraw.Draw(glow)
    x, y = center
    d.ellipse([x - radius, y - radius, x + radius, y + radius], fill=(*color, alpha))
    glow = glow.filter(ImageFilter.GaussianBlur(blur))
    return Image.alpha_composite(base, glow)


def vertical_gradient_mask_fill(draw_target, box, color_top, color_bottom):
    x0, y0, x1, y1 = box
    h = int(y1 - y0)
    if h <= 0:
        return
    grad = Image.new("RGBA", (1, h), (0, 0, 0, 0))
    for i in range(h):
        t = i / max(1, h - 1)
        grad.putpixel((0, i), (*lerp(color_top, color_bottom, t), 255))
    grad = grad.resize((int(x1 - x0), h))
    draw_target.paste(grad, (int(x0), int(y0)), grad)


def polygon_gradient(img, points, color_top, color_bottom):
    xs = [p[0] for p in points]
    ys = [p[1] for p in points]
    box = (min(xs), min(ys), max(xs), max(ys))
    layer = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    mask = Image.new("L", (SIZE, SIZE), 0)
    ImageDraw.Draw(mask).polygon(points, fill=255)
    vertical_gradient_mask_fill(layer, box, color_top, color_bottom)
    layer.putalpha(Image.composite(layer.split()[3], Image.new("L", (SIZE, SIZE), 0), mask))
    img.alpha_composite(layer)


def build_icon(rounded=True):
    base = make_background_fast().convert("RGBA")

    if rounded:
        mask = rounded_mask(SIZE, radius=224)
        bg_layer = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
        bg_layer.paste(base, (0, 0), mask)
        img = bg_layer
    else:
        img = base

    # Ambient glows matching the app theme
    img = add_glow(img, (SIZE - 180, 180), 380, PURPLE, 60, 140)
    img = add_glow(img, (180, SIZE - 160), 360, BLUE, 55, 140)

    # --- Sword of Damocles geometry (hangs point-down by a thread) ---
    thread_top = (CX, 96)
    pommel_center = (CX, 258)
    pommel_r = 20

    grip_w, grip_top, grip_bottom = 38, 276, 350
    guard_w, guard_h, guard_y = 230, 32, 362
    blade_top_w = 96
    blade_top_y = guard_y + guard_h
    blade_tip = (CX, 900)

    # Soft glow silhouette behind the whole blade for a neon accent
    glow_poly = [
        (CX - blade_top_w / 2 - 10, blade_top_y - 6),
        (CX + blade_top_w / 2 + 10, blade_top_y - 6),
        blade_tip,
    ]
    glow_layer = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    ImageDraw.Draw(glow_layer).polygon(glow_poly, fill=(*BLUE, 120))
    glow_layer = glow_layer.filter(ImageFilter.GaussianBlur(28))
    img = Image.alpha_composite(img, glow_layer)

    draw = ImageDraw.Draw(img)

    # Thread
    draw.line([thread_top, (CX, pommel_center[1] - pommel_r)], fill=(*THREAD, 235), width=5)

    # Pommel
    draw.ellipse(
        [pommel_center[0] - pommel_r, pommel_center[1] - pommel_r,
         pommel_center[0] + pommel_r, pommel_center[1] + pommel_r],
        fill=PURPLE,
    )

    # Grip
    draw.rounded_rectangle(
        [CX - grip_w / 2, grip_top, CX + grip_w / 2, grip_bottom],
        radius=10, fill=(58, 58, 68), outline=BLUE, width=3,
    )

    # Crossguard (gradient blue -> purple)
    guard_points = [
        (CX - guard_w / 2, guard_y),
        (CX + guard_w / 2, guard_y),
        (CX + guard_w / 2, guard_y + guard_h),
        (CX - guard_w / 2, guard_y + guard_h),
    ]
    polygon_gradient(img, guard_points, BLUE, PURPLE)
    draw = ImageDraw.Draw(img)
    for side in (-1, 1):
        cx_end = CX + side * guard_w / 2
        draw.ellipse([cx_end - guard_h / 2, guard_y, cx_end + guard_h / 2, guard_y + guard_h],
                     fill=BLUE if side < 0 else PURPLE)

    # Blade (tapered polygon, steel gradient with electric edge)
    blade_points = [
        (CX - blade_top_w / 2, blade_top_y),
        (CX + blade_top_w / 2, blade_top_y),
        blade_tip,
    ]
    polygon_gradient(img, blade_points, STEEL_LIGHT, STEEL_DARK)

    # Center fuller (ridge highlight) for dimensionality
    draw = ImageDraw.Draw(img)
    fuller_top = (CX, blade_top_y + 10)
    fuller_bottom = (CX, blade_tip[1] - 30)
    draw.line([fuller_top, fuller_bottom], fill=(255, 255, 255, 90), width=3)

    # Thin electric outline on the blade edges for the neon accent
    draw.line([blade_points[0], blade_tip], fill=(*BLUE, 200), width=3)
    draw.line([blade_points[1], blade_tip], fill=(*PURPLE, 200), width=3)

    if rounded:
        # Subtle inner border for polish (macOS applies its own mask too,
        # but this keeps a crisp edge if it doesn't).
        border_mask = rounded_mask(SIZE, radius=224)
        border_layer = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
        ImageDraw.Draw(border_layer).rounded_rectangle(
            [3, 3, SIZE - 4, SIZE - 4], radius=222, outline=(255, 255, 255, 30), width=3
        )
        img = Image.alpha_composite(img, border_layer)
        img.putalpha(Image.composite(img.split()[3], Image.new("L", (SIZE, SIZE), 0), border_mask))

    return img


if __name__ == "__main__":
    import os

    out_dir = os.path.join(os.path.dirname(__file__), "..", "Resources")
    os.makedirs(out_dir, exist_ok=True)

    # macOS: rounded square with alpha (matches iconutil/.icns conventions).
    icon = build_icon(rounded=True)
    master_path = os.path.join(out_dir, "icon_master_1024.png")
    icon.save(master_path)
    print("Saved", master_path)

    # iOS: full-bleed square, no alpha (App Store requires opaque icons;
    # iOS applies its own corner mask at render time).
    ios_icon = build_icon(rounded=False).convert("RGB")
    ios_path = os.path.join(out_dir, "icon_ios_1024.png")
    ios_icon.save(ios_path)
    print("Saved", ios_path)
