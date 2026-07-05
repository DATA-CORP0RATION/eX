from django.urls import path

from .views import (
    FavoriteListView,
    FavoriteToggleView,
    MyReviewDetailView,
    ReviewListCreateView,
)

urlpatterns = [
    path("favorites/", FavoriteListView.as_view(), name="favorite-list"),
    path("places/<uuid:pk>/favorite/", FavoriteToggleView.as_view(), name="favorite-toggle"),
    path("places/<uuid:pk>/reviews/", ReviewListCreateView.as_view(), name="review-list-create"),
    path("places/<uuid:pk>/reviews/me/", MyReviewDetailView.as_view(), name="review-mine"),
]
