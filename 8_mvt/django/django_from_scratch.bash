#!/bin/bash

#Step preparation
export PYTHONDONTWRITEBYTECODE=1
rm -rfv ~/Documents/django_from_scratch
mkdir -p ~/Documents/django_from_scratch
pushd ~/Documents/django_from_scratch


#Step 0: init empty git project
git init 
git config user.name "Alexey Veselov"
git config user.email "ukiroot@gmail.com"
cat > .gitignore << EOF
.gitignore
.django_venv
EOF


#Step 1: init virtual ENV
python3 -m venv .django_venv
source .django_venv/bin/activate


#Step 2: add minimal necessary requirements for Django and install them
cat > requirements.txt << EOF
django==5.1.5
EOF
python3 -m pip install -r requirements.txt
git add requirements.txt
git commit -a -m "Step 2: add minimal necessary requirements for Django and install them"


#Step 3: init new  django project with name 'django_project' 
django-admin startproject django_project .
git add django_project/ manage.py
git commit -a -m "Step 3: init new  django project with name 'django_project'"


#Step 4: create simple views based on HttpResponse
cat > django_project/views.py << "EOF"
from django.http import HttpResponse

def api_hello_world(request):
   return HttpResponse("Hello World.")

def api_request_info(request):
   import json
   response_data = {
      "request.method": request.method,
      "request.path": request.path
   }
   response_body = json.dumps(response_data)
   return HttpResponse(response_body)
EOF
sed -i \
    -e '18 a\from . import views' \
    -e "21 a\    path('api/hello_world', views.api_hello_world),\n    path('api/request_info', views.api_request_info)," \
    django_project/urls.py
git add django_project/views.py
git commit -a -m "Step 4: create simple views based on HttpResponse"


#Step 5: add to 'views.py' new views based on render 'templating' 
mkdir templates
cat > templates/root.html << "EOF"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>root</title>
</head>
<body>
    <main>
        <h1>root</h1>
        <p>Current page link <a href="/">Root</a> page.</p>
        <p>Check out my <a href="/info">Info</a> page.</p>
    </main>
</body>
</html>
EOF
cat > templates/info.html << "EOF"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Info</title>
</head>
<body>
    <main>
        <h1>Info</h1>
        <p>Current page link <a href="/info">Info</a> page.</p>
        <p>Check out my <a href="/">Root</a> page.</p>
    </main>
</body>
</html>
EOF
cat >>  django_project/views.py << "EOF"

########################################
########################################

from django.shortcuts import render


def root(request):
    return render(request, 'root.html')


def info(request):
    return render(request, 'info.html')
EOF
sed -i "s/^        'DIRS': \[\],/        'DIRS': ['templates'],/"  django_project/settings.py
sed -i \
    -e "23 a\    path('', views.root),\n    path('info', views.info)," \
    django_project/urls.py
git add templates/
git commit -a -m 'Step 5: add to 'views.py' new views based on render 'templating' '


#Step 6: add static, css styles
sed -i \
    -e "12 a\import os" \
    -e "118 a\STATICFILES_DIRS = [os.path.join(BASE_DIR, 'static')]" \
    django_project/settings.py
mkdir -p static/css
cat > static/css/style.css << "EOF"
body {
    margin: 0;
    height: 100vh;
    display: flex;
    justify-content: center;
    align-items: center;
    font-family: Arial, sans-serif;
}
EOF
sed -i \
    -e '2 a\{% load static %}' \
    -e '6 a\    <link rel="stylesheet" href="{% static '"'"css/style.css"'"' %}">' \
    templates/root.html
sed -i \
    -e '2 a\{% load static %}' \
    -e '6 a\    <link rel="stylesheet" href="{% static '"'"css/style.css"'"' %}">' \
    templates/info.html
git add static
git commit -a -m 'Step 6: add static, css styles'


#Step 7: add static, javaScript code
mkdir -p static/js/
cat > static/js/main.js << "EOF"
console.log('Just debug console message from ' + window.location.href)
EOF
sed -i \
    -e '8 a\    <script src="{% static '"'"js/main.js"'"' %}" defer></script>' \
    templates/root.html
sed -i \
    -e '8 a\    <script src="{% static '"'"js/main.js"'"' %}" defer></script>' \
    templates/info.html
git commit -a -m 'Step 7: add static, javaScript code'


#Step 8: add base_html_layout.html and use it root and info templates
cat > templates/base_html_layout.html << "EOF"
<!DOCTYPE html>
{% load static %}
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>
        {% block title %}
            Django App
        {% endblock %}
    </title>
    <link rel="stylesheet" href="{% static 'css/style.css' %}">
    <script src="{% static 'js/main.js' %}" defer></script>
</head>
<body>
    <main>
           {% block content_current_page %}
           {% endblock %}
           {% block content_other_page %}
           {% endblock %}
    </main>
</body>
</html>
EOF
cat > templates/info.html << "EOF"
{% extends 'base_html_layout.html' %}
{% block title %}
    Info
{% endblock %}

{% block content_current_page %}
    <h1>Info</h1>
    <p>Current page link <a href="/">Info</a> page.</p>
{% endblock %}

{% block content_other_page %}
    <p>Check out my <a href="/">Root</a> page.</p>
{% endblock %}
EOF

cat > templates/root.html << "EOF"
{% extends 'base_html_layout.html' %}
{% block title %}
    Root
{% endblock %}

{% block content_current_page %}
    <h1>Root</h1>
    <p>Current page link <a href="/">Root</a> page.</p>
{% endblock %}

{% block content_other_page %}
    <p>Check out my <a href="/info">Info</a> page.</p>
{% endblock %}
EOF
git add .
git commit -a -m 'Step 8: add base_html_layout.html and use it root and info templates'


#Step 9: apply migrations
python3 manage.py migrate
git add db.sqlite3
git commit -a -m "Step 9: apply migrations"


#Step 10: create django superuser
DJANGO_SUPERUSER_USERNAME=django DJANGO_SUPERUSER_EMAIL=django@example.com DJANGO_SUPERUSER_PASSWORD=django python3 manage.py createsuperuser --noinput
git commit db.sqlite3 -m "Step 10: create django superuser"


#Step 11: create new django app 'unixusers'
python3 manage.py startapp unixusers
sed -i \
    -e "40 a\     'unixusers'," \
    django_project/settings.py
git add unixusers/
git commit -a -m "Step 11: Create new django app 'unixusers'"


#Step 12: create model for app "unixusers"
cat > unixusers/models.py << "EOF"
from django.db import models

class UnixUser(models.Model):
    name = models.CharField(max_length=120)
    user_id = models.IntegerField()
EOF
python3 manage.py makemigrations
python3 manage.py migrate
git add .
git commit -a -m 'Step 12: Create model for app "unixusers"'


#Step 13: register "unixusers" in django admin
cat > unixusers/admin.py << "EOF"
from django.contrib import admin
from .models import UnixUser

admin.site.register(UnixUser)
EOF
git commit -a -m 'Step 13: register "unixusers" in django admin'
