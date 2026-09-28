"""
Generates the catalog artwork used by the storefront.

Every product, category and banner gets its own illustration so the menu never
shows two products sharing a single photo. Output is written to the static
source tree, which `collectstatic` publishes and WhiteNoise serves - meaning the
images survive a redeploy, unlike uploads written to MEDIA_ROOT.

    python scripts/generate_catalog_images.py

Drop a real photograph at static/images/products/<sku>.jpg (same filename) to
override the generated one; the seed step prefers a real file when it exists.
"""

import math
import os
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

BASE_DIR = Path(__file__).resolve().parent.parent
OUT_ROOT = BASE_DIR / "static" / "images"

SIZE = 800
FONT_BOLD = r"C:\Windows\Fonts\segoeuib.ttf"
FONT_REG = r"C:\Windows\Fonts\segoeui.ttf"

PALETTES = {
    "Hardware":        ((38, 52, 66), (86, 104, 122), (214, 178, 118)),
    "Electrical":      ((24, 46, 62), (54, 92, 118), (250, 206, 92)),
    "Switches & Sockets": ((40, 44, 56), (92, 98, 116), (238, 238, 244)),
    "Lighting":        ((48, 38, 20), (104, 84, 38), (255, 224, 130)),
    "Pipes":           ((18, 52, 54), (44, 96, 100), (120, 216, 214)),
    "Plumbing":        ((16, 48, 62), (40, 92, 116), (110, 200, 230)),
    "Bathroom Fittings": ((26, 48, 62), (60, 96, 120), (222, 240, 246)),
    "Tools":           ((44, 36, 24), (96, 80, 52), (240, 160, 60)),
    "Paints":          ((40, 30, 48), (92, 70, 106), (232, 120, 180)),
    "Safety Equipment": ((56, 42, 16), (116, 90, 34), (255, 200, 60)),
    "Fasteners":       ((34, 36, 40), (82, 86, 94), (188, 194, 204)),
    "Chemicals":       ((22, 48, 40), (52, 100, 84), (120, 224, 168)),
}

STEEL = (196, 202, 212)
STEEL_DARK = (120, 128, 142)
DARK = (46, 52, 62)
WHITE = (247, 249, 252)


def font(path, size):
    try:
        return ImageFont.truetype(path, size)
    except OSError:
        return ImageFont.load_default()


def gradient(top, bottom, size=SIZE):
    img = Image.new("RGB", (1, size))
    d = ImageDraw.Draw(img)
    for y in range(size):
        t = y / max(size - 1, 1)
        d.point(
            (0, y),
            fill=(
                int(top[0] + (bottom[0] - top[0]) * t),
                int(top[1] + (bottom[1] - top[1]) * t),
                int(top[2] + (bottom[2] - top[2]) * t),
            ),
        )
    return img.resize((size, size), Image.BICUBIC)


def vignette(img):
    w, h = img.size
    mask = Image.new("L", img.size, 255)
    d = ImageDraw.Draw(mask)
    pad_x, pad_y = int(w * 0.20), int(h * 0.20)
    d.ellipse([pad_x, pad_y, w - pad_x, h - pad_y], fill=0)
    mask = mask.filter(ImageFilter.GaussianBlur(int(min(w, h) * 0.20)))
    dark = Image.new("RGB", img.size, (0, 0, 0))
    return Image.composite(img, dark, mask)


# --- individual product renderers -----------------------------------------

def icon_lock(d, c):
    d.rounded_rectangle([280, 350, 520, 560], 22, fill=STEEL, outline=STEEL_DARK, width=5)
    d.arc([320, 220, 480, 400], 180, 360, fill=STEEL, width=34)
    d.arc([320, 220, 480, 400], 180, 360, fill=STEEL_DARK, width=8)
    d.ellipse([386, 420, 414, 448], fill=DARK)
    d.polygon([(392, 440), (408, 440), (404, 500), (396, 500)], fill=DARK)


def icon_handle(d, c):
    d.rounded_rectangle([210, 330, 300, 470], 18, fill=STEEL, outline=STEEL_DARK, width=5)
    d.rounded_rectangle([300, 372, 540, 428], 26, fill=STEEL, outline=STEEL_DARK, width=5)
    d.ellipse([505, 372, 545, 428], fill=STEEL_DARK)
    d.ellipse([240, 356, 274, 390], fill=DARK)


def icon_hinge(d, c):
    d.rounded_rectangle([250, 200, 380, 400], 12, fill=STEEL, outline=STEEL_DARK, width=5)
    d.rounded_rectangle([420, 400, 550, 600], 12, fill=STEEL, outline=STEEL_DARK, width=5)
    d.rectangle([360, 180, 440, 620], fill=STEEL_DARK)
    for y in (250, 320, 460, 540):
        d.ellipse([382, y, 418, y + 36], fill=STEEL, outline=STEEL_DARK, width=4)


def icon_towerbolt(d, c):
    d.rectangle([330, 200, 470, 600], fill=STEEL, outline=STEEL_DARK, width=5)
    d.rectangle([330, 180, 470, 250], fill=STEEL_DARK)
    d.rectangle([330, 590, 470, 640], fill=c)
    for y in range(280, 580, 34):
        d.line([(340, y), (460, y + 22)], fill=STEEL_DARK, width=6)


def icon_wire(d, c):
    d.ellipse([220, 220, 580, 580], fill=DARK)
    d.ellipse([270, 270, 530, 530], fill=c)
    for i in range(9):
        a = i * (2 * math.pi / 9)
        d.arc([280 + 26 * math.cos(a), 280 + 26 * math.sin(a),
               520 + 26 * math.cos(a), 520 + 26 * math.sin(a)], 0, 360, fill=(255, 255, 255), width=4)
    d.ellipse([368, 368, 432, 432], fill=DARK)
    d.arc([560, 470, 720, 610], 90, 260, fill=c, width=16)


def icon_mcb(d, c):
    d.rounded_rectangle([300, 150, 500, 650], 16, fill=WHITE, outline=STEEL_DARK, width=6)
    d.rectangle([320, 190, 480, 250], fill=DARK)
    d.rounded_rectangle([355, 280, 445, 420], 10, fill=c, outline=STEEL_DARK, width=4)
    d.rounded_rectangle([360, 450, 440, 600], 8, fill=(226, 230, 238), outline=STEEL_DARK, width=4)
    d.text((400, 300), "32A", font=font(FONT_BOLD, 34), fill=DARK, anchor="mm")


def icon_db(d, c):
    d.rounded_rectangle([200, 200, 600, 600], 18, fill=(226, 230, 238), outline=STEEL_DARK, width=7)
    d.rounded_rectangle([240, 240, 560, 560], 10, fill=(248, 250, 253), outline=STEEL_DARK, width=4)
    for i in range(4):
        x = 275 + i * 68
        d.rounded_rectangle([x, 290, x + 44, 400], 6, fill=STEEL, outline=STEEL_DARK, width=3)
        d.rounded_rectangle([x, 430, x + 44, 520], 6, fill=c if i % 2 else STEEL, outline=STEEL_DARK, width=3)
    d.ellipse([540, 210, 580, 250], fill=(90, 190, 110))


def icon_switch(d, c):
    d.rounded_rectangle([250, 250, 550, 550], 26, fill=WHITE, outline=STEEL_DARK, width=7)
    d.rounded_rectangle([300, 296, 500, 396], 16, fill=c, outline=STEEL_DARK, width=5)
    d.rounded_rectangle([300, 404, 500, 504], 16, fill=(226, 230, 238), outline=STEEL_DARK, width=5)
    d.text((400, 600), "16A", font=font(FONT_BOLD, 40), fill=STEEL_DARK, anchor="mm")


def icon_socket(d, c):
    d.ellipse([220, 220, 580, 580], fill=WHITE, outline=STEEL_DARK, width=7)
    d.ellipse([280, 280, 520, 520], fill=(240, 243, 248), outline=STEEL_DARK, width=4)
    for a in range(5):
        ang = math.radians(-90 + a * 72)
        x, y = 400 + 95 * math.cos(ang), 400 + 95 * math.sin(ang)
        d.ellipse([x - 26, y - 26, x + 26, y + 26], fill=DARK)
    d.ellipse([368, 368, 432, 432], fill=DARK)


def icon_bulb(d, c):
    d.ellipse([280, 190, 520, 430], fill=c, outline=STEEL_DARK, width=5)
    d.pieslice([300, 300, 500, 560], 0, 180, fill=c, outline=STEEL_DARK, width=5)
    for y in range(500, 580, 26):
        d.rectangle([340, y, 460, y + 16], fill=STEEL_DARK)
    d.line([(400, 250), (400, 400)], fill=(200, 120, 30), width=12)
    for a in range(0, 360, 45):
        r = math.radians(a)
        d.line([(400 + 155 * math.cos(r), 310 + 155 * math.sin(r)),
                (400 + 195 * math.cos(r), 310 + 195 * math.sin(r))], fill=(255, 236, 170), width=10)


def icon_batten(d, c):
    d.rounded_rectangle([120, 330, 680, 470], 30, fill=WHITE, outline=STEEL_DARK, width=6)
    d.rounded_rectangle([110, 320, 160, 480], 12, fill=c, outline=STEEL_DARK, width=4)
    d.rounded_rectangle([640, 320, 690, 480], 12, fill=c, outline=STEEL_DARK, width=4)
    for x in (300, 360, 420, 480):
        d.line([(x, 350), (x, 450)], fill=(214, 222, 236), width=8)


def icon_panel(d, c):
    d.rounded_rectangle([220, 220, 580, 580], 30, fill=WHITE, outline=STEEL_DARK, width=7)
    d.ellipse([280, 280, 520, 520], fill=(238, 242, 248), outline=STEEL_DARK, width=4)
    for i in range(12):
        a = 2 * math.pi * i / 12
        d.ellipse([400 + 100 * math.cos(a) - 12, 400 + 100 * math.sin(a) - 12,
                   400 + 100 * math.cos(a) + 12, 400 + 100 * math.sin(a) + 12], fill=c)


def icon_pipe(d, c):
    d.rounded_rectangle([120, 330, 680, 470], 16, fill=c, outline=DARK, width=6)
    d.ellipse([90, 315, 175, 485], fill=tuple(min(255, v + 45) for v in c), outline=DARK, width=6)
    d.ellipse([118, 355, 148, 445], fill=DARK)
    d.rounded_rectangle([560, 300, 690, 500], 14, fill=tuple(min(255, v + 30) for v in c), outline=DARK, width=6)
    d.line([(200, 400), (560, 400)], fill=(255, 255, 255, 90), width=12)


def icon_elbow(d, c):
    d.rounded_rectangle([250, 200, 380, 470], 14, fill=c, outline=DARK, width=6)
    d.rounded_rectangle([250, 400, 620, 530], 14, fill=c, outline=DARK, width=6)
    d.ellipse([238, 188, 306, 256], fill=tuple(min(255, v + 45) for v in c), outline=DARK, width=5)
    d.ellipse([560, 388, 632, 460], fill=tuple(min(255, v + 45) for v in c), outline=DARK, width=5)
    d.arc([250, 400, 380, 530], 0, 90, fill=(255, 255, 255), width=8)


def icon_basin(d, c):
    d.polygon([(250, 330), (550, 330), (470, 430), (330, 430)], fill=WHITE, outline=STEEL_DARK, width=5)
    d.rounded_rectangle([360, 430, 440, 600], 10, fill=WHITE, outline=STEEL_DARK, width=5)
    d.rounded_rectangle([300, 596, 500, 640], 12, fill=WHITE, outline=STEEL_DARK, width=5)
    d.line([(400, 340), (400, 430)], fill=STEEL_DARK, width=4)
    d.arc([360, 230, 440, 310], 180, 360, fill=STEEL, width=12)
    d.ellipse([228, 320, 272, 348], fill=STEEL_DARK)


def icon_commode(d, c):
    d.rounded_rectangle([300, 200, 500, 330], 14, fill=WHITE, outline=STEEL_DARK, width=6)
    d.ellipse([220, 330, 580, 500], fill=WHITE, outline=STEEL_DARK, width=6)
    d.ellipse([270, 360, 530, 450], fill=(232, 238, 246), outline=STEEL_DARK, width=4)
    d.polygon([(250, 470), (550, 470), (500, 610), (300, 610)], fill=WHITE, outline=STEEL_DARK, width=6)
    d.rounded_rectangle([380, 240, 420, 270], 6, fill=c)


def icon_faucet(d, c):
    d.rounded_rectangle([330, 180, 400, 340], 16, fill=STEEL, outline=STEEL_DARK, width=4)
    d.rounded_rectangle([300, 320, 430, 400], 18, fill=STEEL, outline=STEEL_DARK, width=4)
    d.rounded_rectangle([300, 380, 560, 440], 20, fill=STEEL, outline=STEEL_DARK, width=4)
    d.polygon([(520, 380), (580, 380), (566, 470), (534, 470)], fill=STEEL_DARK)
    d.rounded_rectangle([300, 300, 470, 340], 12, fill=c)
    d.ellipse([510, 470, 590, 550], fill=(120, 200, 230))


def icon_shower(d, c):
    d.line([(400, 560), (400, 330)], fill=STEEL, width=26)
    d.line([(400, 330), (400, 250)], fill=STEEL, width=26)
    d.ellipse([260, 150, 540, 300], fill=STEEL, outline=STEEL_DARK, width=5)
    d.ellipse([285, 175, 515, 275], fill=tuple(min(255, v + 40) for v in c), outline=STEEL_DARK, width=4)
    for i in range(5):
        d.ellipse([310 + i * 45, 205, 330 + i * 45, 225], fill=DARK)
    for i, x in enumerate((300, 360, 420, 480)):
        d.polygon([(x, 320 + (i % 2) * 22), (x + 20, 320 + (i % 2) * 22), (x + 10, 380 + (i % 2) * 22)],
                  fill=(150, 215, 240))


def icon_drill(d, c):
    d.polygon([(210, 290), (400, 250), (440, 360), (250, 400)], fill=c, outline=DARK, width=5)
    d.rounded_rectangle([430, 290, 500, 350], 8, fill=STEEL_DARK)
    d.polygon([(498, 296), (600, 288), (600, 336), (498, 344)], fill=STEEL)
    d.rounded_rectangle([250, 395, 350, 540], 18, fill=DARK, outline=(20, 24, 30), width=4)
    d.rounded_rectangle([340, 330, 400, 420], 12, fill=STEEL_DARK)
    d.text((330, 318), "800W", font=font(FONT_BOLD, 30), fill=WHITE, anchor="mm")


def icon_tape(d, c):
    d.rounded_rectangle([200, 250, 520, 520], 44, fill=c, outline=DARK, width=6)
    d.ellipse([250, 300, 420, 470], fill=tuple(max(0, v - 45) for v in c), outline=DARK, width=4)
    d.ellipse([300, 350, 370, 420], fill=DARK)
    d.rectangle([510, 370, 730, 420], fill=(240, 224, 150), outline=DARK, width=3)
    for x in range(530, 720, 26):
        d.line([(x, 372), (x, 418)], fill=DARK, width=3)
    d.rounded_rectangle([250, 285, 300, 330], 8, fill=STEEL_DARK)


def icon_wrench(d, c):
    d.polygon([(560, 180), (680, 250), (640, 320), (520, 250)], fill=STEEL, outline=STEEL_DARK, width=5)
    d.polygon([(600, 200), (668, 258), (642, 288), (574, 232)], fill=DARK)
    d.rounded_rectangle([300, 380, 580, 450], 14, fill=STEEL, outline=STEEL_DARK, width=5)
    d.rounded_rectangle([180, 350, 330, 480], 20, fill=c, outline=DARK, width=5)
    d.ellipse([160, 330, 350, 500], fill=None, outline=c, width=26)
    d.text((470, 415), "14\"", font=font(FONT_BOLD, 30), fill=STEEL_DARK, anchor="mm")


def icon_level(d, c):
    d.rounded_rectangle([120, 340, 680, 460], 14, fill=(226, 214, 120), outline=STEEL_DARK, width=5)
    for cx in (280, 400, 520):
        d.rounded_rectangle([cx - 36, 366, cx + 36, 434], 8, fill=(238, 244, 250), outline=STEEL_DARK, width=3)
        d.ellipse([cx - 14, 386, cx + 14, 414], fill=(90, 190, 110) if cx != 400 else (220, 80, 80))
    d.text((630, 400), "24\"", font=font(FONT_BOLD, 28), fill=STEEL_DARK, anchor="mm")


def icon_paint(d, c):
    d.rounded_rectangle([230, 250, 570, 620], 18, fill=c, outline=DARK, width=6)
    d.ellipse([230, 200, 570, 300], fill=tuple(max(0, v - 40) for v in c), outline=DARK, width=6)
    d.ellipse([300, 232, 500, 288], fill=(250, 250, 252), outline=DARK, width=4)
    d.arc([250, 150, 550, 420], 200, 340, fill=STEEL_DARK, width=14)
    d.rounded_rectangle([270, 350, 530, 500], 10, fill=WHITE)
    d.text((400, 400), c and "PAINT" or "", font=font(FONT_BOLD, 46), fill=DARK, anchor="mm")
    d.text((400, 452), "20L", font=font(FONT_BOLD, 30), fill=STEEL_DARK, anchor="mm")


def icon_helmet(d, c):
    d.pieslice([230, 250, 570, 560], 180, 360, fill=c, outline=DARK, width=6)
    d.rectangle([300, 250, 500, 300], fill=c)
    d.rounded_rectangle([190, 540, 610, 592], 22, fill=tuple(max(0, v - 50) for v in c), outline=DARK, width=5)
    d.arc([300, 210, 500, 340], 180, 360, fill=DARK, width=12)
    d.text((400, 430), "3M", font=font(FONT_BOLD, 52), fill=DARK, anchor="mm")


def icon_shoe(d, c):
    d.polygon([(220, 560), (230, 420), (330, 400), (420, 300), (520, 330), (540, 470), (560, 560)],
              fill=c, outline=DARK, width=6)
    d.rounded_rectangle([200, 556, 580, 616], 18, fill=DARK)
    d.line([(300, 430), (400, 400)], fill=STEEL_DARK, width=6)
    d.line([(330, 460), (430, 430)], fill=STEEL_DARK, width=6)
    d.ellipse([470, 350, 520, 400], fill=(230, 235, 245))


def icon_gloves(d, c):
    d.rounded_rectangle([300, 300, 520, 560], 40, fill=c, outline=DARK, width=6)
    for i, x in enumerate((326, 374, 422, 470)):
        d.rounded_rectangle([x, 190 + i * 6, x + 42, 340], 20, fill=c, outline=DARK, width=5)
    d.rounded_rectangle([240, 430, 300, 520], 28, fill=c, outline=DARK, width=5)
    d.rectangle([300, 300, 520, 340], fill=tuple(max(0, v - 45) for v in c))


def icon_goggles(d, c):
    d.rounded_rectangle([190, 300, 610, 500], 40, fill=(210, 226, 240), outline=STEEL_DARK, width=7)
    d.ellipse([215, 325, 390, 465], fill=(160, 205, 235), outline=DARK, width=5)
    d.ellipse([410, 325, 585, 465], fill=(160, 205, 235), outline=DARK, width=5)
    d.rectangle([380, 360, 420, 440], fill=STEEL_DARK)
    d.line([(190, 380), (140, 350)], fill=DARK, width=16)
    d.line([(610, 380), (660, 350)], fill=DARK, width=16)


def icon_anchor(d, c):
    d.rounded_rectangle([370, 130, 430, 300], 8, fill=STEEL, outline=STEEL_DARK, width=4)
    d.rounded_rectangle([300, 300, 500, 430], 10, fill=STEEL, outline=STEEL_DARK, width=4)
    for i in range(4):
        d.line([(320 + i * 46, 310), (320 + i * 46, 420)], fill=STEEL_DARK, width=7)
    d.polygon([(400, 430), (330, 520), (470, 520)], fill=STEEL_DARK)
    d.rounded_rectangle([360, 500, 440, 590], 8, fill=STEEL, outline=STEEL_DARK, width=4)


def icon_screw(d, c):
    d.polygon([(300, 160), (500, 160), (500, 300), (400, 380), (300, 300)], fill=STEEL, outline=STEEL_DARK, width=5)
    d.line([(340, 230), (460, 230)], fill=STEEL_DARK, width=8)
    d.line([(400, 375), (400, 600)], fill=STEEL, width=34)
    for y in range(400, 590, 40):
        d.line([(383, y), (417, y + 20)], fill=STEEL_DARK, width=6)
    d.polygon([(378, 600), (422, 600), (400, 650)], fill=STEEL_DARK)


def icon_nutbolt(d, c):
    pts = [(400 + 110 * math.cos(math.radians(a)), 330 + 110 * math.sin(math.radians(a)))
           for a in range(0, 360, 60)]
    d.polygon(pts, fill=STEEL, outline=STEEL_DARK)
    d.ellipse([350, 280, 450, 380], fill=(40, 44, 52))
    d.rounded_rectangle([380, 430, 420, 660], 6, fill=STEEL, outline=STEEL_DARK, width=4)
    for y in range(460, 640, 38):
        d.line([(382, y), (418, y + 18)], fill=STEEL_DARK, width=5)


def icon_bottle(d, c):
    d.rounded_rectangle([340, 160, 460, 250], 10, fill=DARK)
    d.rounded_rectangle([300, 250, 500, 620], 26, fill=c, outline=DARK, width=6)
    d.rounded_rectangle([280, 340, 520, 500], 12, fill=WHITE)
    d.text((400, 400), "ADHESIVE", font=font(FONT_BOLD, 30), fill=DARK, anchor="mm")
    d.text((400, 448), "50g", font=font(FONT_REG, 26), fill=STEEL_DARK, anchor="mm")
    d.rounded_rectangle([330, 190, 470, 250], 8, fill=STEEL_DARK)


def icon_taperoll(d, c):
    d.ellipse([250, 250, 550, 550], fill=(248, 248, 244), outline=STEEL_DARK, width=6)
    d.ellipse([340, 340, 460, 460], fill=(70, 78, 92))
    d.ellipse([300, 300, 500, 500], outline=(226, 226, 220), width=10)
    d.arc([250, 250, 550, 550], 300, 60, fill=(215, 215, 205), width=18)
    d.rounded_rectangle([420, 520, 620, 570], 12, fill=(248, 248, 244), outline=STEEL_DARK, width=4)


def icon_ceiling(d, c):
    d.ellipse([240, 220, 560, 540], fill=c, outline=DARK, width=6)
    d.ellipse([280, 260, 520, 500], fill=tuple(max(0, v - 40) for v in c))
    d.polygon([(400, 540), (330, 650), (470, 650)], fill=(214, 220, 230), outline=DARK, width=4)
    d.text((400, 375), "PVC", font=font(FONT_BOLD, 44), fill=WHITE, anchor="mm")


ICONS = {
    "lock": icon_lock, "handle": icon_handle, "hinge": icon_hinge, "towerbolt": icon_towerbolt,
    "wire": icon_wire, "mcb": icon_mcb, "db": icon_db, "switch": icon_switch, "socket": icon_socket,
    "bulb": icon_bulb, "batten": icon_batten, "panel": icon_panel, "pipe": icon_pipe,
    "elbow": icon_elbow, "basin": icon_basin, "commode": icon_commode, "faucet": icon_faucet,
    "shower": icon_shower, "drill": icon_drill, "tape": icon_tape, "wrench": icon_wrench,
    "level": icon_level, "paint": icon_paint, "helmet": icon_helmet, "shoe": icon_shoe,
    "gloves": icon_gloves, "goggles": icon_goggles, "anchor": icon_anchor, "screw": icon_screw,
    "nutbolt": icon_nutbolt, "bottle": icon_bottle, "taperoll": icon_taperoll, "ceiling": icon_ceiling,
}

PRODUCTS = [
    ("HW-LOCK-001", "Hardware", "lock"), ("HW-HNDL-002", "Hardware", "handle"),
    ("HW-HNGE-003", "Hardware", "hinge"), ("HW-BOLT-004", "Hardware", "towerbolt"),
    ("EL-WIRE-001", "Electrical", "wire"), ("EL-MCB-002", "Electrical", "mcb"),
    ("EL-DB-003", "Electrical", "db"), ("SW-16A-001", "Switches & Sockets", "switch"),
    ("SW-5P-002", "Switches & Sockets", "socket"), ("LT-LED-001", "Lighting", "bulb"),
    ("LT-BAT-002", "Lighting", "batten"), ("LT-PNL-003", "Lighting", "panel"),
    ("PL-CPVC-001", "Pipes", "pipe"), ("PL-PVC-002", "Pipes", "pipe"),
    ("PL-ELB-003", "Plumbing", "elbow"), ("PL-PPR-004", "Pipes", "pipe"),
    ("BT-BAS-001", "Bathroom Fittings", "basin"), ("BT-CMT-002", "Bathroom Fittings", "commode"),
    ("BT-FCT-003", "Bathroom Fittings", "faucet"), ("BT-SHW-004", "Bathroom Fittings", "shower"),
    ("TL-DRM-001", "Tools", "drill"), ("TL-TPE-002", "Tools", "tape"),
    ("TL-WRN-003", "Tools", "wrench"), ("TL-LVL-004", "Tools", "level"),
    ("PT-APX-001", "Paints", "paint"), ("PT-APEX-002", "Paints", "paint"),
    ("PT-WC-003", "Paints", "paint"), ("SF-HLM-001", "Safety Equipment", "helmet"),
    ("SF-SHO-002", "Safety Equipment", "shoe"), ("SF-GLV-003", "Safety Equipment", "gloves"),
    ("SF-GGL-004", "Safety Equipment", "goggles"), ("FN-ANC-001", "Fasteners", "anchor"),
    ("FN-SCR-002", "Fasteners", "screw"), ("FN-NB-003", "Fasteners", "nutbolt"),
    ("CH-PVC-001", "Chemicals", "bottle"), ("CH-TFL-002", "Chemicals", "taperoll"),
    ("CH-EPO-003", "Chemicals", "bottle"),
]

CATEGORIES = [(name, pal[2]) for name, pal in PALETTES.items()]

BANNERS = [
    ("summer-sale", "Tools", "drill"),
    ("electrical-essentials", "Electrical", "mcb"),
    ("bathroom-renovation", "Bathroom Fittings", "commode"),
    ("plumbing-solutions", "Plumbing", "faucet"),
]


def slug(text):
    out = []
    prev_dash = False
    for ch in text.lower():
        if ch.isalnum():
            out.append(ch)
            prev_dash = False
        elif not prev_dash:
            out.append('-')
            prev_dash = True
    return "".join(out).strip('-')


def compose(category, icon_name, size, label=None, sub=None):
    top, bottom, accent = PALETTES[category]
    base = gradient(top, bottom, size)
    canvas = base.convert("RGBA")
    layer = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    if icon_name:
        d = ImageDraw.Draw(layer)
        ICONS[icon_name](d, accent)
    canvas.paste(layer, (0, 0), layer)

    if label:
        band_h = int(size * 0.17)
        band = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
        bd = ImageDraw.Draw(band)
        bd.rectangle([0, size - band_h, size, size], fill=(14, 18, 26, 205))
        canvas.paste(band, (0, 0), band)
        dd = ImageDraw.Draw(canvas)
        fnt = font(FONT_BOLD, int(size * 0.058))
        subf = font(FONT_REG, int(size * 0.042))
        dd.text((size // 2, size - band_h // 2 - int(size * 0.015)), label,
                font=fnt, fill=(255, 255, 255), anchor="mm")
        if sub:
            dd.text((size // 2, size - band_h // 2 + int(size * 0.055)), sub,
                    font=subf, fill=accent, anchor="mm")

    out = vignette(canvas.convert("RGB"))
    return out.filter(ImageFilter.SMOOTH)


CATEGORY_ICON = {
    "Hardware": "lock", "Electrical": "mcb", "Switches & Sockets": "switch",
    "Lighting": "bulb", "Pipes": "pipe", "Plumbing": "faucet",
    "Bathroom Fittings": "basin", "Tools": "drill", "Paints": "paint",
    "Safety Equipment": "helmet", "Fasteners": "nutbolt", "Chemicals": "bottle",
}

LABELS = {
    "HW-LOCK-001": ("Steel Door Lock Set", "Stanley"), "HW-HNDL-002": ("SS Door Handle", "Stanley"),
    "HW-HNGE-003": ("Heavy Duty Hinge", "Stanley"), "HW-BOLT-004": ("Tower Bolt 8\"", "Stanley"),
    "EL-WIRE-001": ("HRFR Wire 1.5mm", "Havells"), "EL-MCB-002": ("MCB 32A DP", "Anchor"),
    "EL-DB-003": ("Distribution Board", "Anchor"), "SW-16A-001": ("Modular Switch 16A", "Anchor"),
    "SW-5P-002": ("5 Pin Socket 6A", "Anchor"), "LT-LED-001": ("LED Bulb 9W", "Syska"),
    "LT-BAT-002": ("LED Batten 20W", "Philips"), "LT-PNL-003": ("Panel Light 18W", "Philips"),
    "PL-CPVC-001": ("CPVC Pipe 1/2\"", "Astral"), "PL-PVC-002": ("PVC Pipe 4\"", "Supreme"),
    "PL-ELB-003": ("CPVC Elbow Pack", "Astral"), "PL-PPR-004": ("PPR Pipe 3/4\"", "Astral"),
    "BT-BAS-001": ("Wash Basin", "Cera"), "BT-CMT-002": ("Western Commode", "Hindware"),
    "BT-FCT-003": ("Basin Mixer", "Jaquar"), "BT-SHW-004": ("Shower Head 8\"", "Jaquar"),
    "TL-DRM-001": ("Drill Machine 800W", "Bosch"), "TL-TPE-002": ("Measuring Tape 5m", "Stanley"),
    "TL-WRN-003": ("Pipe Wrench 14\"", "Drillex"), "TL-LVL-004": ("Spirit Level 24\"", "Stanley"),
    "PT-APX-001": ("Apex Ultima 20L", "Asian Paints"), "PT-APEX-002": ("Apex 4L White", "Asian Paints"),
    "PT-WC-003": ("Weathercoat 10L", "Berger"), "SF-HLM-001": ("Safety Helmet", "3M"),
    "SF-SHO-002": ("Safety Shoes", "3M"), "SF-GLV-003": ("Work Gloves", "3M"),
    "SF-GGL-004": ("Safety Goggles", "3M"), "FN-ANC-001": ("Anchor Bolt", ""),
    "FN-SCR-002": ("Drilling Screw", ""), "FN-NB-003": ("Nut Bolt M8", ""),
    "CH-PVC-001": ("PVC Solvent Cement", "Astral"), "CH-TFL-002": ("Teflon Tape", ""),
    "CH-EPO-003": ("Epoxy Adhesive", ""),
}


def main():
    os.makedirs(OUT_ROOT / "products", exist_ok=True)
    os.makedirs(OUT_ROOT / "categories", exist_ok=True)
    os.makedirs(OUT_ROOT / "banners", exist_ok=True)

    written = 0
    for sku, category, icon in PRODUCTS:
        label, sub = LABELS.get(sku, (sku, ""))
        compose(category, icon, SIZE, label, sub).save(
            OUT_ROOT / "products" / f"{sku.lower()}.jpg", quality=88, optimize=True)
        written += 1

    for name, _accent in CATEGORIES:
        compose(name, CATEGORY_ICON[name], 512).save(
            OUT_ROOT / "categories" / f"{slug(name)}.jpg", quality=88, optimize=True)
        written += 1

    for name, category, icon in BANNERS:
        compose(category, icon, 800).save(
            OUT_ROOT / "banners" / f"{name}.jpg", quality=86, optimize=True)
        written += 1

    print(f"Generated {written} images under {OUT_ROOT}")


if __name__ == "__main__":
    main()
