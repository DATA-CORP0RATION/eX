from django.shortcuts import get_object_or_404
from rest_framework import generics, permissions, status
from rest_framework.exceptions import ValidationError
from rest_framework.response import Response
from rest_framework.views import APIView

from tourism.models import Place

from .models import Favorite, Review
from .serializers import FavoriteSerializer, ReviewSerializer


class FavoriteListView(generics.ListAPIView):
    """Liste des favoris de l'utilisateur connecté."""

    serializer_class = FavoriteSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return Favorite.objects.filter(user=self.request.user).select_related("place")


class FavoriteToggleView(APIView):
    """POST /places/<id>/favorite/ : ajoute le lieu aux favoris s'il n'y est pas, le retire sinon."""

    permission_classes = [permissions.IsAuthenticated]

    def post(self, request, pk):
        place = get_object_or_404(Place, pk=pk)
        existing = Favorite.objects.filter(user=request.user, place=place).first()

        if existing:
            existing.delete()
            return Response({"favorited": False}, status=status.HTTP_200_OK)

        Favorite.objects.create(user=request.user, place=place)
        return Response({"favorited": True}, status=status.HTTP_201_CREATED)


class ReviewListCreateView(generics.ListCreateAPIView):
    """GET : avis d'un lieu (public) — POST : déposer un avis (connecté, un seul par lieu)."""

    serializer_class = ReviewSerializer

    def get_permissions(self):
        if self.request.method == "POST":
            return [permissions.IsAuthenticated()]
        return [permissions.AllowAny()]

    def get_queryset(self):
        return Review.objects.filter(place_id=self.kwargs["pk"]).select_related("user")

    def perform_create(self, serializer):
        place = get_object_or_404(Place, pk=self.kwargs["pk"])
        if Review.objects.filter(user=self.request.user, place=place).exists():
            raise ValidationError(
                "Vous avez déjà déposé un avis pour ce lieu. "
                "Modifiez-le via PATCH sur /reviews/me/."
            )
        serializer.save(user=self.request.user, place=place)


class MyReviewDetailView(generics.RetrieveUpdateDestroyAPIView):
    """Permet à l'utilisateur connecté de consulter/modifier/supprimer SON avis sur un lieu."""

    serializer_class = ReviewSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_object(self):
        return get_object_or_404(Review, place_id=self.kwargs["pk"], user=self.request.user)
