from django.conf import settings
from django.db import models

from core.models import BaseModel
from tourism.models import Place


class Favorite(BaseModel):
    """Un utilisateur ajoute un lieu à ses favoris."""

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="favorites"
    )
    place = models.ForeignKey(Place, on_delete=models.CASCADE, related_name="favorited_by")

    class Meta:
        ordering = ["-created_at"]
        constraints = [
            models.UniqueConstraint(fields=["user", "place"], name="unique_favorite_user_place"),
        ]

    def __str__(self):
        return f"{self.user} \u2665 {self.place}"


class Review(BaseModel):
    """Avis simplifié (note + commentaire) déposé sur un lieu, sans file de modération."""

    RATING_CHOICES = [(i, str(i)) for i in range(1, 6)]

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="reviews"
    )
    place = models.ForeignKey(Place, on_delete=models.CASCADE, related_name="reviews")
    rating = models.PositiveSmallIntegerField(choices=RATING_CHOICES)
    comment = models.TextField(blank=True)

    class Meta:
        ordering = ["-created_at"]
        constraints = [
            models.UniqueConstraint(fields=["user", "place"], name="unique_review_user_place"),
        ]

    def __str__(self):
        return f"{self.user} - {self.place} ({self.rating}/5)"
