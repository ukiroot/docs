#!/bin/bash

set -o xtrace
set -o verbose
set -o errexit

function 0_step_preparation(){
export PYTHONDONTWRITEBYTECODE=1
rm -rfv ~/Documents/django_from_scratch
mkdir -p ~/Documents/django_from_scratch
pushd ~/Documents/django_from_scratch
}

function 0_step_init_empty_git_project(){
git init 
git config user.name "Alexey Veselov"
git config user.email "ukiroot@gmail.com"
cat > .gitignore << EOF
.gitignore
.django_venv
EOF
}

function 1_step_init_virtual_ENV(){
python3 -m venv .django_venv
source .django_venv/bin/activate
}

function 2_step_add_minimal_necessary_requirements_for_Django_and_install_them(){
cat > requirements.txt << EOF
django==5.1.5
EOF
python3 -m pip install -r requirements.txt
git add requirements.txt
git commit -a -m "${FUNCNAME[*]}"
}

function 3_step_init_new_django_project_with_name_django_project(){
django-admin startproject django_project .
git add django_project/ manage.py
git commit -a -m "${FUNCNAME[*]}"
}

function 4_step_create_simple_views_based_on_HttpResponse(){
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
git commit -a -m "${FUNCNAME[*]}"
}

function 5_step_add_to_views.py_new_views_based_on_render_templating(){
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
git commit -a -m "${FUNCNAME[*]}"
}

6_step_add_static_css_styles(){
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
git commit -a -m "${FUNCNAME[*]}"
}

function 7_step_add_static_javaScript_code(){
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
git commit -a -m "${FUNCNAME[*]}"
}

function 8_step_add_base_html_layout.html_and_use_it_root_and_info_templates(){
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
git commit -a -m "${FUNCNAME[*]}"
}

function 9_step_apply_migrations(){
python3 manage.py migrate
git add db.sqlite3
git commit -a -m "${FUNCNAME[*]}"
}

function 10_step_create_django_superuser(){
DJANGO_SUPERUSER_USERNAME=django DJANGO_SUPERUSER_EMAIL=django@example.com DJANGO_SUPERUSER_PASSWORD=django python3 manage.py createsuperuser --noinput
git commit db.sqlite3 -m "${FUNCNAME[*]}"
}

function 11_step_create_new_django_app_unixusers(){
python3 manage.py startapp unixusers
sed -i \
    -e "39 a\     'unixusers'," \
    django_project/settings.py
git add unixusers/
git commit -a -m "${FUNCNAME[*]}"
}

function 12_step_create_model_for_app_unixusers(){
cat > unixusers/models.py << "EOF"
from django.db import models

class UnixUser(models.Model):
    name = models.CharField(max_length=120, unique=True)
    user_id = models.IntegerField(unique=True)
    date = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return "Name: {}, userId: {}, date_creation: {}".format(self.name, self.user_id, self.date)
EOF
python3 manage.py makemigrations
python3 manage.py migrate
git add .
git commit -a -m "${FUNCNAME[*]}"
}

function 13_step_register_unixusers_in_django_admin(){
cat > unixusers/admin.py << "EOF"
from django.contrib import admin
from .models import UnixUser

admin.site.register(UnixUser)
EOF
git commit -a -m "${FUNCNAME[*]}"
}

function 14_step_add_to_DB_new_UnixUser_from_CMD(){
python3 manage.py shell -c "from unixusers.models import UnixUser;UnixUser(name='lol', user_id=7777777).save()"
git commit db.sqlite3 -m "${FUNCNAME[*]}"
}

function 15_step_add_new_endpoint_for_sync_api-unixusers-sync_and_get_api-unixusers_users(){
cat > unixusers/views.py << "EOF"
from django.http import HttpResponse
from django.core import serializers
from .models import UnixUser
import json


def get(request):
    return HttpResponse(
        serializers.serialize(
            'json',
            UnixUser.objects.all()
        )
    )

def sync(request):
    synced_users = set()
    with open('/etc/passwd', 'r') as file:
        for user_record in file:
            user_recorld_list = user_record.split(':')
            user_name=user_recorld_list[0]
            user_id=user_recorld_list[2]
            if not UnixUser.objects.filter(name=user_name).exists():
                new_user = UnixUser(name=user_name, user_id=user_id)
                new_user.save()
                synced_users.add(new_user)
    count = len(synced_users)
    return HttpResponse(
        json.dumps({"count":count})
    )
EOF
cat > unixusers/urls.py << "EOF"
from django.urls import path
from . import views

urlpatterns = [
    path('', views.get),
    path('sync', views.sync),
]
EOF
sed -i \
    -e 's/^from django.urls import path$/from django.urls import path, include/' \
    -e "26 a\    path('api/unixusers/', include('unixusers.urls'))," \
     django_project/urls.py
git add .
git commit -a -m "${FUNCNAME[*]}"
}


0_step_preparation
0_step_init_empty_git_project
1_step_init_virtual_ENV
2_step_add_minimal_necessary_requirements_for_Django_and_install_them
3_step_init_new_django_project_with_name_django_project
4_step_create_simple_views_based_on_HttpResponse
5_step_add_to_views.py_new_views_based_on_render_templating
7_step_add_static_javaScript_code
8_step_add_base_html_layout.html_and_use_it_root_and_info_templates
9_step_apply_migrations
10_step_create_django_superuser
11_step_create_new_django_app_unixusers
12_step_create_model_for_app_unixusers
13_step_register_unixusers_in_django_admin
14_step_add_to_DB_new_UnixUser_from_CMD
15_step_add_new_endpoint_for_sync_api-unixusers-sync_and_get_api-unixusers_users
