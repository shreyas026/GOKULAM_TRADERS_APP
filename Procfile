release: python manage.py migrate --noinput && python seed_data.py
web: gunicorn gokulam_backend.wsgi --bind 0.0.0.0:$PORT