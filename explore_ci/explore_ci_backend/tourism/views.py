from django.db.models import Avg, Count
from rest_framework import generics, permissions

from .models import Category, Place, Region
from .serializers import (
    CategorySerializer,
    PlaceDetailSerializer,
    PlaceListSerializer,
    RegionSerializer,
)


class CategoryListView(generics.ListAPIView):
    """Liste des catégories (pour les filtres côté Flutter)."""

    queryset = Category.objects.all()
    serializer_class = CategorySerializer
    permission_classes = [permissions.AllowAny]
    pagination_class = None


class RegionListView(generics.ListAPIView):
    """Liste des régions (pour les filtres côté Flutter)."""

    queryset = Region.objects.all()
    serializer_class = RegionSerializer
    permission_classes = [permissions.AllowAny]
    pagination_class = None


def _place_queryset():
    return Place.objects.select_related("category", "region").annotate(
        average_rating=Avg("reviews__rating"),
        reviews_count=Count("reviews", distinct=True),
    )


class PlaceListView(generics.ListAPIView):
    """Liste des lieux touristiques (carte + liste).

    Filtres disponibles en query params :
        ?category=<slug>   filtre par catégorie
        ?region=<slug>     filtre par région
        ?search=<texte>    recherche sur le nom du lieu
    """

    serializer_class = PlaceListSerializer
    permission_classes = [permissions.AllowAny]

    def get_queryset(self):
        qs = _place_queryset()
        params = self.request.query_params

        category_slug = params.get("category")
        region_slug = params.get("region")
        search = params.get("search")

        if category_slug:
            qs = qs.filter(category__slug=category_slug)
        if region_slug:
            qs = qs.filter(region__slug=region_slug)
        if search:
            qs = qs.filter(name__icontains=search)

        return qs


class PlaceDetailView(generics.RetrieveAPIView):
    """Fiche détaillée d'un lieu touristique."""

    serializer_class = PlaceDetailSerializer
    permission_classes = [permissions.AllowAny]
    queryset = _place_queryset()
