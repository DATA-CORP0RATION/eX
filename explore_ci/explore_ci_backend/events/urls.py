from django.urls import path

from .views import (
    EventDetailView,
    EventListView,
    EventParticipationToggleView,
    MyParticipationListView,
)

urlpatterns = [
    path("", EventListView.as_view(), name="event-list"),
    path("mine/", MyParticipationListView.as_view(), name="event-participation-mine"),
    path("<uuid:pk>/", EventDetailView.as_view(), name="event-detail"),
    path("<uuid:pk>/participate/", EventParticipationToggleView.as_view(), name="event-participate"),
]
