"""
Portable database backup and provider-migration helper.

Usage:
    python scripts/db_transfer.py dump [outfile]
    python scripts/db_transfer.py load [infile]

The active database is taken from the DATABASE_URL environment variable, so the
same commands work against any provider (Railway, Supabase, Neon, local...).

Example: move a production database to a new provider
    python scripts/db_transfer.py dump backups/prod.json
    $env:DATABASE_URL = "postgresql://user:pass@host/db"
    python scripts/db_transfer.py load backups/prod.json
"""

import json
import os
import sys
from pathlib import Path

BACKUP_DIR = Path(__file__).resolve().parent.parent / "backups"

# Recreated by `migrate`, so loading them causes permission/content-type clashes.
EXCLUDED = ["auth.permission", "contenttypes.contenttype"]


def _setup_django():
    import django

    sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
    os.environ.setdefault("DJANGO_SETTINGS_MODULE", "gokulam_backend.settings")
    django.setup()


def dump(outfile=None):
    from django.core.management import call_command

    if outfile is None:
        outfile = BACKUP_DIR / f"gokulam_{_stamp()}.json"
    outfile = Path(outfile)
    outfile.parent.mkdir(parents=True, exist_ok=True)

    import io
    import contextlib

    buffer = io.StringIO()
    # dumpdata writes to stdout; capture it so warnings cannot corrupt the file.
    with contextlib.redirect_stdout(buffer):
        call_command("dumpdata", exclude=EXCLUDED, indent=2, natural_foreign=True)

    payload = buffer.getvalue()
    json.loads(payload)  # fail loudly rather than write an unusable backup
    outfile.write_text(payload, encoding="utf-8")

    count = len(json.loads(payload))
    print(f"Wrote {count} objects to {outfile} ({outfile.stat().st_size / 1024:.1f} KB)")


def load(infile=None):
    from django.core.management import call_command

    if infile is None:
        candidates = sorted(BACKUP_DIR.glob("gokulam_*.json"), key=lambda p: p.stat().st_mtime)
        if not candidates:
            raise SystemExit("No backup found in backups/. Run: python scripts/db_transfer.py dump")
        infile = candidates[-1]

    infile = Path(infile)
    if not infile.exists():
        raise SystemExit(f"No such backup: {infile}")

    json.loads(infile.read_text(encoding="utf-8"))

    print(f"Applying migrations to target database...")
    call_command("migrate", interactive=False, verbosity=0)

    print(f"Loading {infile}...")
    call_command("loaddata", str(infile), verbosity=1)


def _stamp():
    from datetime import datetime

    return datetime.now().strftime("%Y%m%d_%H%M%S")


def main(argv):
    if not os.environ.get("DATABASE_URL"):
        raise SystemExit("DATABASE_URL is not set - point it at the database you want to act on.")

    _setup_django()

    command = argv[1] if len(argv) > 1 else "dump"
    target = argv[2] if len(argv) > 2 else None

    if command == "dump":
        dump(target)
    elif command == "load":
        load(target)
    else:
        raise SystemExit(f"Unknown command '{command}'. Use 'dump' or 'load'.")


if __name__ == "__main__":
    main(sys.argv)
