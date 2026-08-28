web: MALLOC_ARENA_MAX=2 MALLOC_TRIM_THRESHOLD_=65536 gunicorn web_app:app --bind 0.0.0.0:$PORT --workers 1 --threads 2 --worker-class gthread --max-requests 25 --max-requests-jitter 5 --timeout 120
