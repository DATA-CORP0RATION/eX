#!/usr/bin/env bash
# Script de build pour Render (à configurer comme "Build Command").
# Start Command sur Render : gunicorn explore_ci.wsgi --log-file - --bind 0.0.0.0:$PORT
set -o errexit

pip install -r requirements.txt

python manage.py collectstatic --noinput
python manage.py migrate --noinput
