# Name:         django.sh
# Author:       Reagan Zierke <reagan.zierke@example.com>
# Created:      2025-09-04
# Description:  Setup a Django project using uv

#!/bin/bash
# setup_django_uv.sh
set -e

PROJECT_NAME=${1:-conf}

# Start uv
uv init
uv venv

# Install django
uv add django 
uv add django-browser-reload
uv add python-dotenv
uv run django-admin startproject conf

# Move manage.py to root
mv conf/manage.py ./

# Move inner conf/* to outer conf/
mv conf/conf/* conf/

# Remove old nested conf/
rmdir conf/conf

mkdir templates static media

cat > conf/settings.py << 'EOF'
from pathlib import Path
import os
from dotenv import load_dotenv
from django.core.management.utils import get_random_secret_key

load_dotenv()

# Build paths inside the project like this: BASE_DIR / 'subdir'.
BASE_DIR = Path(__file__).resolve().parent.parent

# Quick-start development settings - unsuitable for production
# https://docs.djangoproject.com/en/5.2/howto/deployment/checklist/

# SECURITY WARNING: keep the secret key used in production secret!
# SECURITY WARNING: don't run with debug turned on in production!
load_dotenv(BASE_DIR / ".env")

SECRET_KEY = os.environ.get("SECRET_KEY", get_random_secret_key())
DEBUG = os.environ.get("DEBUG", "0") == "1"

ALLOWED_HOSTS = []

# Application definition
INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    "django_browser_reload",
]

MIDDLEWARE = [
    'django.middleware.security.SecurityMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
    "django_browser_reload.middleware.BrowserReloadMiddleware",
]

ROOT_URLCONF = 'conf.urls'

TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [ BASE_DIR / 'templates' ],
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
                'django.contrib.messages.context_processors.messages',
            ],
        },
    },
]

WSGI_APPLICATION = 'conf.wsgi.application'

# Database
# https://docs.djangoproject.com/en/5.2/ref/settings/#databases
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.sqlite3',
        'NAME': BASE_DIR / 'db.sqlite3',
    }
}

# Password validation
# https://docs.djangoproject.com/en/5.2/ref/settings/#auth-password-validators
AUTH_PASSWORD_VALIDATORS = [
    {'NAME': 'django.contrib.auth.password_validation.UserAttributeSimilarityValidator'},
    {'NAME': 'django.contrib.auth.password_validation.MinimumLengthValidator'},
    {'NAME': 'django.contrib.auth.password_validation.CommonPasswordValidator'},
    {'NAME': 'django.contrib.auth.password_validation.NumericPasswordValidator'},
]

# Internationalization
# https://docs.djangoproject.com/en/5.2/topics/i18n/
LANGUAGE_CODE = 'en-us'
TIME_ZONE = 'America/Chicago'
USE_I18N = True
USE_TZ = True

# Static files (CSS, JavaScript, Images)
# https://docs.djangoproject.com/en/5.2/howto/static-files/
STATIC_URL = '/static/'
STATICFILES_DIRS = [ BASE_DIR / "static" ]
STATIC_ROOT = BASE_DIR / "staticfiles"

MEDIA_URL = '/media/'
MEDIA_ROOT = BASE_DIR / "media"

# Default primary key field type
# https://docs.djangoproject.com/en/5.2/ref/settings/#default-auto-field
DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'
EOF


cat > .env << 'EOF'
# Django environment variables

# Use a fixed key in dev so sessions don't reset on every restart
SECRET_KEY=dev-secret-key-change-me

# Set to 1 for development, 0 for production
DEBUG=1
EOF

# --- Patch urls.py ---
URLS_FILE="conf/urls.py"

sed -i "s/from django.urls import path/from django.urls import path, include/" $URLS_FILE

sed -i "/urlpatterns = \[/ a\ \ \ \ path('__reload__/', include('django_browser_reload.urls'))," $URLS_FILE

uv run python manage.py migrate

cat > templates/base.html << 'EOF'
{% load static %}
{% load form_extras %}

<!DOCTYPE html>
<html lang="en" class="h-full">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <style>
      :root {
        --concordia-blue: #192C53;
        --concordia-sky: #5A9DBF;
        --concordia-slate: #646464;
        --concordia-nimbus: #C8C8C8;
        --concordia-wheat: #E2C172;
        --concordia-white: #F8F4ED;
        --concordia-clay: #B2402A;
      }
    </style>
    <script src="https://unpkg.com/htmx.org@2.0.4" integrity="sha384-HGfztofotfshcF7+8n44JQL2oJmowVChPTg48S+jvZoztPfvwD79OC/LTtG6dMp+" crossorigin="anonymous"></script>
    <script type="text/javascript" src="https://cdnjs.cloudflare.com/ajax/libs/trix/1.3.1/trix.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/@tailwindcss/browser@4"></script>
    <title>Site Title</title>
</head>
<body class="min-h-screen flex flex-col bg-white">
    <header class="p-6" style="background-color: var(--concordia-blue); color: var(--concordia-white);">
        <div class="flex flex-col items-center font-sans">
            <p>This is a header</p>
        </div>
    </header>
    <main class="flex-grow">
        {% block content %}{% endblock %}
    </main>
    <footer class="text-white p-6 mt-4" style="background-color: var(--concordia-blue);">
        <div class="flex flex-col items-center font-sans">
            <p class="text-lg" style="color: var(--concordia-white);">© 2025</p>
        </div>
    </footer>
</body>
</html>
EOF
uv run python manage.py runserver

