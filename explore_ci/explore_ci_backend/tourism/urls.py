from django.urls import path

from .views import CategoryListView, PlaceDetailView, PlaceListView, RegionListView

urlpatterns = [
    path("categories/", CategoryListView.as_view(), name="category-list"),
    path("regions/", RegionListView.as_view(), name="region-list"),
    path("places/", PlaceListView.as_view(), name="place-list"),
    path("places/<uuid:pk>/", PlaceDetailView.as_view(), name="place-detail"),
]
