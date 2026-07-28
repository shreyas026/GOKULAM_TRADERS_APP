import os
from django.core.wsgi import get_wsgi_application

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'gokulam_backend.settings')

# Run migrations and seed data on startup
from django.core.management import call_command
import sys

if 'migrate' not in ' '.join(sys.argv):
    try:
        call_command('migrate', '--noinput')
        call_command('seed_data')
    except Exception as e:
        print(f"Startup migration error: {e}")

application = get_wsgi_application()