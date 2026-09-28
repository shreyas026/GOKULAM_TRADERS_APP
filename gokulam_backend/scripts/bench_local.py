"""Time the Django stack locally to split network vs framework vs database cost."""

import os
import statistics
import sys
import time
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
os.environ.setdefault("DJANGO_SETTINGS_MODULE", "gokulam_backend.settings")

if len(sys.argv) > 1 and sys.argv[1] == "live-db":
    os.environ["DATABASE_URL"] = (
        "postgresql://postgres:SdfgMeauOkWCwROAjsWSYcjHWedvSFFW@127.0.0.1:15432/railway"
    )
else:
    os.environ.pop("DATABASE_URL", None)

import django  # noqa: E402

django.setup()

from django.test import Client  # noqa: E402


def bench(client, path, runs=8):
    samples = []
    for _ in range(runs):
        started = time.perf_counter()
        res = client.get(path)
        samples.append((time.perf_counter() - started) * 1000)
        assert res.status_code == 200, (path, res.status_code)
    return statistics.mean(samples), min(samples), max(samples)


def main():
    target = sys.argv[1] if len(sys.argv) > 1 else "sqlite"

    from django.db import connection

    connection.ensure_connection()
    vendor = connection.vendor

    client = Client()
    for path in ("/api/store/location/", "/api/products/", "/api/categories/"):
        avg, lo, hi = bench(client, path)
        print(f"{target:<9} {path:<24} avg={avg:7.1f}ms  min={lo:7.1f}  max={hi:7.1f}  ({vendor})")


if __name__ == "__main__":
    main()
