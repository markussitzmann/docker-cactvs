from django.contrib import admin
from django.urls import path, include

from simple import views

urlpatterns = [
    path('resolver/<str:smiles>', views.resolver),
]
