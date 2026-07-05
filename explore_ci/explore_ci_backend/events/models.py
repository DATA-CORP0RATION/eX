from django.conf import settings
from django.db import models

from core.models import BaseModel
from tourism.models import Place, Region


class Event(BaseModel):
    """Un événement du calendrier (festival, concert, fête culturelle, sport, foire...)."""

    EVENT_TYPE_CHOICES = [
        ("festival", "Festival"),
        ("concert", "Concert"),
        ("culturel", "Fête culturelle"),
        ("sport", "Sport"),
        ("foire", "Foire"),
        ("autre", "Autre"),
    ]

    title = models.CharField(max_length=200)
    description = models.TextField(blank=True)
    event_type = models.CharField(max_length=20, choices=EVENT_TYPE_CHOICES, default="autre")

    region = models.ForeignKey(
        Region,
        on_delete=models.PROTECT,
        related_name="events",
        null=True,
        blank=True,
        help_text="Ville/région de l'événement, utilisée pour le filtre 'autour de lui'.",
    )
    place = models.ForeignKey(
        Place,
        on_delete=models.SET_NULL,
        related_name="events",
        null=True,
        blank=True,
        help_text="Lieu touristique associé (optionnel).",
    )
    location_name = models.CharField(
        max_length=255,
        blank=True,
        help_text="Lieu en texte libre si aucun Place n'est associé (ex: 'Palais de la Culture, Abidjan').",
    )

    start_datetime = models.DateTimeField()
    end_datetime = models.DateTimeField(null=True, blank=True)

    price = models.DecimalField(
        max_digits=10,
        decimal_places=0,
        null=True,
        blank=True,
        help_text="Prix en FCFA. Laisser vide si gratuit.",
    )
    booking_url = models.URLField(blank=True, help_text="Lien de réservation/billetterie (optionnel).")
    cover_image_url = models.URLField(blank=True)

    class Meta:
        ordering = ["start_datetime"]
        indexes = [
            models.Index(fields=["start_datetime"], name="events_event_start_idx"),
            models.Index(fields=["region"], name="events_event_region_idx"),
        ]

    def __str__(self):
        return f"{self.title} ({self.start_datetime:%d/%m/%Y})"

    @property
    def is_free(self):
        return not self.price


class EventParticipation(BaseModel):
    """Un utilisateur indique qu'il participe à un événement."""

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="event_participations"
    )
    event = models.ForeignKey(Event, on_delete=models.CASCADE, related_name="participants")

    class Meta:
        ordering = ["-created_at"]
        constraints = [
            models.UniqueConstraint(fields=["user", "event"], name="unique_participation_user_event"),
        ]

    def __str__(self):
        return f"{self.user} participe à {self.event}"
