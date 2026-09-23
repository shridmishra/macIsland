#!/usr/bin/env python3
import os
import math
import subprocess
from PIL import Image, ImageDraw, ImageFilter

def create_mac_island_icon():
    size = 1024
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Margins for standard macOS squircle (Apple HIG specifies ~824x824 icon inside 1024x1024 canvas with shadow)
    padding = 90
    x0, y0 = padding, padding
    x1, y1 = size - padding, size - padding
    radius = 185  # Standard macOS squircle radius

    # 1. Subtle drop shadow for the squircle
    shadow = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    s_draw = ImageDraw.Draw(shadow)
    s_draw.rounded_rectangle([x0 + 6, y0 + 16, x1 + 6, y1 + 22], radius=radius, fill=(0, 0, 0, 110))
    shadow = shadow.filter(ImageFilter.GaussianBlur(28))
    img.alpha_composite(shadow)

    # 2. Main squircle background gradient
    base = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    b_draw = ImageDraw.Draw(base)

    # Render vertical gradient
    for y in range(y0, y1):
        t = (y - y0) / float(y1 - y0)
        # Deep space black-slate to obsidian blue
        r = int(14 * (1 - t) + 20 * t)
        g = int(17 * (1 - t) + 26 * t)
        b = int(24 * (1 - t) + 40 * t)
        b_draw.line([(x0, y), (x1, y)], fill=(r, g, b, 255))

    # Mask to rounded squircle
    mask = Image.new("L", (size, size), 0)
    m_draw = ImageDraw.Draw(mask)
    m_draw.rounded_rectangle([x0, y0, x1, y1], radius=radius, fill=255)
    base.putalpha(mask)
    img.alpha_composite(base)

    # 3. Ambient colorful glow radiating from center
    glow = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    g_draw = ImageDraw.Draw(glow)
    
    # Cyan / Blue glow top left
    g_draw.ellipse([300, 260, 720, 680], fill=(59, 130, 246, 65))
    # Violet / Purple glow bottom
    g_draw.ellipse([260, 380, 760, 780], fill=(147, 51, 234, 55))
    # Emerald accent
    g_draw.ellipse([400, 320, 620, 540], fill=(16, 185, 129, 45))
    glow = glow.filter(ImageFilter.GaussianBlur(50))
    glow.putalpha(mask)
    img.alpha_composite(glow)

    # 4. Subtle inner border / rim light
    rim = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    r_draw = ImageDraw.Draw(rim)
    r_draw.rounded_rectangle([x0, y0, x1, y1], radius=radius, outline=(255, 255, 255, 38), width=3)
    r_draw.rounded_rectangle([x0 + 2, y0 + 2, x1 - 2, y1 - 2], radius=radius - 2, outline=(255, 255, 255, 12), width=2)
    img.alpha_composite(rim)

    # 5. The Dynamic Island Pill (Centerpiece)
    pw, ph = 460, 160
    px0 = (size - pw) // 2
    py0 = 340
    px1 = px0 + pw
    py1 = py0 + ph
    pradius = ph // 2

    # Island shadow
    pill_shadow = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    ps_draw = ImageDraw.Draw(pill_shadow)
    ps_draw.rounded_rectangle([px0, py0 + 10, px1, py1 + 18], radius=pradius, fill=(0, 0, 0, 180))
    pill_shadow = pill_shadow.filter(ImageFilter.GaussianBlur(22))
    img.alpha_composite(pill_shadow)

    # Island body (Glossy deep black with subtle glass reflection)
    pill = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    p_draw = ImageDraw.Draw(pill)
    p_draw.rounded_rectangle([px0, py0, px1, py1], radius=pradius, fill=(8, 10, 14, 250))
    # Island border
    p_draw.rounded_rectangle([px0, py0, px1, py1], radius=pradius, outline=(255, 255, 255, 45), width=3)
    img.alpha_composite(pill)

    # 6. Inside the Island: Mini Album Art / Icon on Left, Equalizer Bars on Right
    inside = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    in_draw = ImageDraw.Draw(inside)

    # Left: Circular Music / Wave badge
    cx, cy, cr = px0 + 80, (py0 + py1) // 2, 42
    in_draw.ellipse([cx - cr, cy - cr, cx + cr, cy + cr], fill=(30, 41, 59, 230), outline=(59, 130, 246, 180), width=3)
    # Inner vibrant accent
    in_draw.ellipse([cx - cr + 10, cy - cr + 10, cx + cr - 10, cy + cr - 10], fill=(59, 130, 246, 200))
    in_draw.ellipse([cx - 10, cy - 10, cx + 10, cy + 10], fill=(255, 255, 255, 240))

    # Center: Island Camera Dot (Notch sensor aesthetic)
    cam_x = (px0 + px1) // 2 - 40
    in_draw.ellipse([cam_x - 9, cy - 9, cam_x + 9, cy + 9], fill=(18, 24, 38, 255), outline=(37, 99, 235, 120), width=2)
    in_draw.ellipse([cam_x - 3, cy - 3, cam_x + 3, cy + 3], fill=(56, 189, 248, 180))

    # Right: Animated Audio Waveform Equalizer Bars
    bar_start_x = px0 + 260
    bar_width = 12
    bar_gap = 10
    bar_heights = [38, 64, 88, 52, 76, 44]
    bar_colors = [
        (56, 189, 248, 240),   # Sky blue
        (96, 165, 250, 245),   # Blue
        (168, 85, 247, 255),   # Purple
        (236, 72, 153, 245),   # Pink
        (52, 211, 153, 240),   # Emerald
        (56, 189, 248, 230),   # Sky blue
    ]

    for i, h in enumerate(bar_heights):
        bx = bar_start_x + i * (bar_width + bar_gap)
        by0 = cy - h // 2
        by1 = cy + h // 2
        in_draw.rounded_rectangle([bx, by0, bx + bar_width, by1], radius=bar_width // 2, fill=bar_colors[i])

    img.alpha_composite(inside)

    # 7. Subtle Sound Wave Arcs below the Island
    waves = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    w_draw = ImageDraw.Draw(waves)
    arc_center = (size // 2, py1 + 40)
    
    for r_arc, alpha in [(90, 45), (140, 30), (190, 18)]:
        bbox = [arc_center[0] - r_arc, arc_center[1] - r_arc // 3, arc_center[0] + r_arc, arc_center[1] + r_arc // 3]
        w_draw.arc(bbox, start=20, end=160, fill=(96, 165, 250, alpha), width=3)

    waves = waves.filter(ImageFilter.GaussianBlur(1))
    waves.putalpha(mask)
    img.alpha_composite(waves)

    return img

def export_iconset_and_icns(img, output_icns_path):
    iconset_dir = "MacIsland.iconset"
    os.makedirs(iconset_dir, exist_ok=True)

    sizes = [
        (16, "icon_16x16.png"),
        (32, "icon_16x16@2x.png"),
        (32, "icon_32x32.png"),
        (64, "icon_32x32@2x.png"),
        (128, "icon_128x128.png"),
        (256, "icon_128x128@2x.png"),
        (256, "icon_256x256.png"),
        (512, "icon_256x256@2x.png"),
        (512, "icon_512x512.png"),
        (1024, "icon_512x512@2x.png"),
    ]

    for s, name in sizes:
        resized = img.resize((s, s), Image.Resampling.LANCZOS)
        resized.save(os.path.join(iconset_dir, name))

    subprocess.run(["iconutil", "-c", "icns", iconset_dir, "-o", output_icns_path], check=True)
    print(f"Successfully generated {output_icns_path}")
    # Cleanup iconset folder
    import shutil
    shutil.rmtree(iconset_dir, ignore_errors=True)

if __name__ == "__main__":
    icon = create_mac_island_icon()
    os.makedirs("Sources/MacIsland/Resources", exist_ok=True)
    export_iconset_and_icns(icon, "Sources/MacIsland/Resources/AppIcon.icns")
