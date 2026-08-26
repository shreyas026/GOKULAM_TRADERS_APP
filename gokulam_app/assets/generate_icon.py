#!/usr/bin/env python3
"""Generate app icon for Gokulam Traders with GT text and gear/cog design."""
import math
from PIL import Image, ImageDraw, ImageFont

SIZE = 1024
CENTER = SIZE // 2
BG_COLOR = (27, 94, 32)  # #1B5E20 dark green
GEAR_COLOR = (46, 125, 50)  # #2E7D32 lighter green
GEAR_INNER_COLOR = (56, 142, 60)  # #388E3C
WHITE = (255, 255, 255)
ACCENT_COLOR = (200, 230, 201)  # Light green accent

img = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
draw = ImageDraw.Draw(img)

# 1. Draw outer green circle background
margin = 20
draw.ellipse([margin, margin, SIZE - margin, SIZE - margin], fill=BG_COLOR)

# 2. Draw gear/cog behind the text
gear_center_x, gear_center_y = CENTER, CENTER - 20
gear_outer_r = 340
gear_inner_r = 260
num_teeth = 12
tooth_height = 80
tooth_width = 40

# Draw gear body (filled circle)
draw.ellipse(
    [gear_center_x - gear_inner_r, gear_center_y - gear_inner_r,
     gear_center_x + gear_inner_r, gear_center_y + gear_inner_r],
    fill=GEAR_COLOR
)

# Draw gear teeth
for i in range(num_teeth):
    angle = (2 * math.pi / num_teeth) * i
    # Outer tooth point
    x1 = gear_center_x + gear_inner_r * math.cos(angle)
    y1 = gear_center_y + gear_inner_r * math.sin(angle)
    x2 = gear_center_x + (gear_inner_r + tooth_height) * math.cos(angle)
    y2 = gear_center_y + (gear_inner_r + tooth_height) * math.sin(angle)

    # Create tooth as a rotated rectangle
    perp_angle = angle + math.pi / 2
    hw = tooth_width / 2
    pts = [
        (x1 + hw * math.cos(perp_angle), y1 + hw * math.sin(perp_angle)),
        (x2 + hw * math.cos(perp_angle), y2 + hw * math.sin(perp_angle)),
        (x2 - hw * math.cos(perp_angle), y2 - hw * math.sin(perp_angle)),
        (x1 - hw * math.cos(perp_angle), y1 - hw * math.sin(perp_angle)),
    ]
    draw.polygon(pts, fill=GEAR_COLOR)

# 3. Draw gear inner hole (circle)
hole_r = 140
draw.ellipse(
    [gear_center_x - hole_r, gear_center_y - hole_r,
     gear_center_x + hole_r, gear_center_y + hole_r],
    fill=BG_COLOR
)

# 4. Draw inner ring detail
ring_r = 180
draw.ellipse(
    [gear_center_x - ring_r, gear_center_y - ring_r,
     gear_center_x + ring_r, gear_center_y + ring_r],
    outline=GEAR_INNER_COLOR, width=12
)

# 5. Draw GT text
try:
    # Try to find a bold font
    font_paths = [
        "C:/Windows/Fonts/arialbd.ttf",
        "C:/Windows/Fonts/calibrib.ttf",
        "C:/Windows/Fonts/segoeui.ttf",
        "C:/Windows/Fonts/tahoma.ttf",
    ]
    font = None
    for fp in font_paths:
        try:
            font = ImageFont.truetype(fp, 260)
            break
        except:
            continue
    if font is None:
        font = ImageFont.truetype("C:/Windows/Fonts/arial.ttf", 260)
except:
    font = ImageFont.load_default()

text = "GT"
bbox = draw.textbbox((0, 0), text, font=font)
tw = bbox[2] - bbox[0]
th = bbox[3] - bbox[1]
tx = CENTER - tw // 2
ty = CENTER - th // 2 - 40  # Slightly above center

# Draw text shadow
draw.text((tx + 4, ty + 4), text, fill=(0, 0, 0, 60), font=font)
# Draw main text
draw.text((tx, ty), text, fill=WHITE, font=font)

# 6. Draw small "TRADERS" text below GT
try:
    small_font = ImageFont.truetype("C:/Windows/Fonts/arialbd.ttf", 60)
except:
    try:
        small_font = ImageFont.truetype("C:/Windows/Fonts/arial.ttf", 60)
    except:
        small_font = ImageFont.load_default()

sub_text = "TRADERS"
bbox2 = draw.textbbox((0, 0), sub_text, font=small_font)
sw = bbox2[2] - bbox2[0]
sx = CENTER - sw // 2
sy = CENTER + 120

draw.text((sx, sy), sub_text, fill=ACCENT_COLOR, font=small_font)

# 7. Draw subtle ring around the outer edge
draw.ellipse([margin + 10, margin + 10, SIZE - margin - 10, SIZE - margin - 10],
             outline=ACCENT_COLOR, width=6)

# Save
output_path = "C:/Users/shrey/Desktop/MCA_OC/gokulam_app/assets/images/app_icon.png"
img.save(output_path, "PNG")
print(f"Icon saved to {output_path}")
print(f"Size: {img.size}")
