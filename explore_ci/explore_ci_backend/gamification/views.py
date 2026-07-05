from django.db.models import Prefetch
from django.shortcuts import get_object_or_404
from rest_framework import generics, permissions, status
from rest_framework.response import Response
from rest_framework.views import APIView

from tourism.models import Place

from .models import Challenge, UserBadge, UserChallengeProgress, Visit
from .serializers import (
    BadgeSerializer,
    ChallengeSerializer,
    ProfileStatsSerializer,
    UserBadgeSerializer,
    VisitSerializer,
)
from .services import apply_visit_progress, get_profile_stats


class ChallengeListView(generics.ListAPIView):
    """Liste des défis actifs, avec la progression de l'utilisateur connecté
    (0/objectif et non complété si non connecté)."""

    serializer_class = ChallengeSerializer
    permission_classes = [permissions.AllowAny]

    def get_queryset(self):
        qs = Challenge.objects.filter(is_active=True).select_related("target_category", "badge")
        user = self.request.user
        if user.is_authenticated:
            qs = qs.prefetch_related(
                Prefetch(
                    "progresses",
                    queryset=UserChallengeProgress.objects.filter(user=user),
                    to_attr="_user_progress",
                )
            )
        return qs


class VisitToggleView(APIView):
    """POST /gamification/places/<id>/visit/ : bascule visité/non visité.

    Marquer un lieu visité met à jour la progression des défis concernés ;
    retirer une visite ne fait jamais perdre un défi/badge déjà validé.
    """

    permission_classes = [permissions.IsAuthenticated]

    def post(self, request, pk):
        place = get_object_or_404(Place, pk=pk)
        existing = Visit.objects.filter(user=request.user, place=place).first()

        if existing:
            existing.delete()
            return Response({"visited": False}, status=status.HTTP_200_OK)

        Visit.objects.create(user=request.user, place=place)
        apply_visit_progress(request.user, place)
        return Response({"visited": True}, status=status.HTTP_201_CREATED)


class MyVisitsListView(generics.ListAPIView):
    """Liste des lieux visités par l'utilisateur connecté."""

    serializer_class = VisitSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return Visit.objects.filter(user=self.request.user).select_related("place")


class MyBadgesListView(generics.ListAPIView):
    """Badges débloqués par l'utilisateur connecté."""

    serializer_class = UserBadgeSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return UserBadge.objects.filter(user=self.request.user).select_related("badge")


class AllBadgesListView(generics.ListAPIView):
    """Catalogue de tous les badges existants (pour montrer aussi ceux à débloquer)."""

    serializer_class = BadgeSerializer
    permission_classes = [permissions.AllowAny]

    def get_queryset(self):
        return Badge.objects.all()


class ProfileStatsView(APIView):
    """GET /gamification/profile/ : XP, niveau, badges, visites, progression."""

    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        stats = get_profile_stats(request.user)
        serializer = ProfileStatsSerializer(stats)
        return Response(serializer.data)
