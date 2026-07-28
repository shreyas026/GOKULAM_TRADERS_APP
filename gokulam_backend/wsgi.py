import os
import django
from django.core.management import call_command

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'gokulam_backend.settings')
django.setup()

import sys
if 'migrate' not in ' '.join(sys.argv):
    call_command('migrate', '--noinput')
    call_command('seed_data')

from django.core.wsgi import get_wsgi_application
application = get_wsgi_application()