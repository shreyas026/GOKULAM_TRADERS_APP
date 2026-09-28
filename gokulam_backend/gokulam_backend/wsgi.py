import os

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'gokulam_backend.settings')

# Migrations and seeding run once in the start command, before gunicorn forks
# its workers. Running them here would execute them in every worker
# concurrently on each boot, which races on schema changes and on the
# get_or_create inserts in seed_data.py.
from django.core.wsgi import get_wsgi_application
application = get_wsgi_application()