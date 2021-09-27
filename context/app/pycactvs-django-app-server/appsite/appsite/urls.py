from django.contrib import admin
from django.urls import path, include

import simple.urls

urlpatterns = [
    path('simple/', include('simple.urls')),
    path('admin/', admin.site.urls),
]
