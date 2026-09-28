"""Check that every static image URL referenced by seed_data.py exists on disk."""

import pathlib
import re

root = pathlib.Path(__file__).resolve().parent.parent
src = (root / "seed_data.py").read_text(encoding="utf-8")

urls = sorted(set(re.findall(r"'(/static/images/[A-Za-z0-9/_-]+\.jpg)'", src)))
missing = [u for u in urls if not (root / u.lstrip("/")).exists()]

print(f"static image URLs referenced by seed_data.py: {len(urls)}")
print("missing on disk:", missing or "none")

product_urls = [u for u in urls if "/products/" in u]
print(f"  products: {len(product_urls)}  categories: {len(urls) - len(product_urls)}")

skus = sorted(set(re.findall(r"'sku': '([A-Z0-9-]+)'", src)))
missing_products = [
    s for s in skus if not (root / "static/images/products" / f"{s.lower()}.jpg").exists()
]
print(f"product SKUs in seed_data.py: {len(skus)}")
print("SKUs with no generated image:", missing_products or "none")

on_disk = {p.stem.upper() for p in (root / "static/images/products").glob("*.jpg")}
referenced = {s.upper() for s in skus}
print("images on disk but never seeded:", sorted(on_disk - referenced) or "none")
print("SKUs seeded but no image:", sorted(referenced - on_disk) or "none")
