from django.urls import path

from .views import (
    AllBadgesListView,
    ChallengeListView,
    MyBadgesListView,
    MyVisitsListView,
    ProfileStatsView,
    VisitToggleView,
)

urlpatterns = [
    path("challenges/", ChallengeListView.as_view(), name="challenge-list"),
    path("badges/", AllBadgesListView.as_view(), name="badge-list"),
    path("badges/mine/", MyBadgesListView.as_view(), name="badge-mine"),
    path("visits/mine/", MyVisitsListView.as_view(), name="visit-mine"),
    path("places/<uuid:pk>/visit/", VisitToggleView.as_view(), name="visit-toggle"),
    path("profile/", ProfileStatsView.as_view(), name="profile-stats"),
]
