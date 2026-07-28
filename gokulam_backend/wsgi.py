import os
import sys

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'gokulam_backend.settings')

import django
django.setup()

from django.core.management import call_command
if 'migrate' not in ' '.join(sys.argv):
    call_command('migrate', '--noinput')

from django.core.wsgi import get_wsgi_application
application = get_wsgi_application()