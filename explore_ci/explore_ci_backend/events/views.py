from django.db.models import Count
from django.shortcuts import get_object_or_404
from django.utils import timezone
from rest_framework import generics, permissions, status
from rest_framework.response import Response
from rest_framework.views import APIView

from gamification.services import apply_event_participation_progress

from .models import Event, EventParticipation
from .serializers import (
    EventDetailSerializer,
    EventListSerializer,
    EventParticipationSerializer,
)


def _event_queryset():
    return Event.objects.select_related("region", "place").annotate(
        participants_count=Count("participants", distinct=True),
    )


class EventListView(generics.ListAPIView):
    """Liste des événements du calendrier.

    Filtres disponibles en query params :
        ?region=<slug>       filtre par ville/région
        ?event_type=<type>   filtre par type (festival, concert, culturel, sport, foire, autre)
        ?upcoming=false       inclut aussi les événements passés (par défaut : à venir uniquement)
        ?search=<texte>      recherche sur le titre
    """

    serializer_class = EventListSerializer
    permission_classes = [permissions.AllowAny]

    def get_queryset(self):
        qs = _event_queryset()
        params = self.request.query_params

        region_slug = params.get("region")
        event_type = params.get("event_type")
        search = params.get("search")
        upcoming = params.get("upcoming", "true")

        if region_slug:
            qs = qs.filter(region__slug=region_slug)
        if event_type:
            qs = qs.filter(event_type=event_type)
        if search:
            qs = qs.filter(title__icontains=search)
        if upcoming.lower() != "false":
            qs = qs.filter(start_datetime__gte=timezone.now())

        return qs


class EventDetailView(generics.RetrieveAPIView):
    """Fiche détaillée d'un événement."""

    serializer_class = EventDetailSerializer
    permission_classes = [permissions.AllowAny]
    queryset = _event_queryset()


class EventParticipationToggleView(APIView):
    """POST /events/<id>/participate/ : bascule participation à l'événement."""

    permission_classes = [permissions.IsAuthenticated]

    def post(self, request, pk):
        event = get_object_or_404(Event, pk=pk)
        existing = EventParticipation.objects.filter(user=request.user, event=event).first()

        if existing:
            existing.delete()
            return Response({"participating": False}, status=status.HTTP_200_OK)

        EventParticipation.objects.create(user=request.user, event=event)
        apply_event_participation_progress(request.user, event.event_type)
        return Response({"participating": True}, status=status.HTTP_201_CREATED)


class MyParticipationListView(generics.ListAPIView):
    """Liste des événements auxquels l'utilisateur connecté participe."""

    serializer_class = EventParticipationSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return EventParticipation.objects.filter(user=self.request.user).select_related("event")
