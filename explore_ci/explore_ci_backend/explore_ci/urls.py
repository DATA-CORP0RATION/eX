from django.contrib import admin
from django.urls import path, include

urlpatterns = [
    path("admin/", admin.site.urls),
    path("api/auth/", include("accounts.urls")),
    path("api/tourism/", include("tourism.urls")),
    path("api/tourism/", include("interactions.urls")),
    path("api/gamification/", include("gamification.urls")),
    path("api/events/", include("events.urls")),
    path("api/community/", include("community.urls")),
]
