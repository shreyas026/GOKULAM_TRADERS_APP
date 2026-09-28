"""Verification: confirm every generated image actually contains its icon."""

import importlib.util
from pathlib import Path

from PIL import Image, ImageChops

spec = importlib.util.spec_from_file_location(
    "gen", Path(__file__).parent / "generate_catalog_images.py"
)
gen = importlib.util.module_from_spec(spec)
spec.loader.exec_module(gen)

rows = []
for sku, category, icon in gen.PRODUCTS:
    path = Path("static/images/products") / f"{sku.lower()}.jpg"
    real = Image.open(path).convert("RGB")
    label, sub = gen.LABELS.get(sku, (sku, ""))
    blank = gen.compose(category, None, gen.SIZE, label, sub)
    diff = ImageChops.difference(real, blank).convert("L")
    changed = sum(1 for p in diff.getdata() if p > 18)
    rows.append((sku, 100 * changed / (diff.width * diff.height)))

rows.sort(key=lambda r: r[1])
print(f"checked {len(rows)} product images")
print("smallest icon footprints:")
for sku, pct in rows[:6]:
    print(f"  {sku:<16} {pct:5.2f}% of pixels")
failing = [r for r in rows if r[1] < 2.0]
print("FAILING (<2%):", failing if failing else "none")
