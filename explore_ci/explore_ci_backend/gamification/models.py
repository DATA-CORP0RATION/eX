from django.conf import settings
from django.db import models

from core.models import BaseModel
from tourism.models import Category, Place

# Dupliqué volontairement depuis events.models.Event.EVENT_TYPE_CHOICES pour éviter
# une dépendance gamification -> events (c'est events qui appelle gamification, pas l'inverse).
EVENT_TYPE_CHOICES = [
    ("festival", "Festival"),
    ("concert", "Concert"),
    ("culturel", "Fête culturelle"),
    ("sport", "Sport"),
    ("foire", "Foire"),
    ("autre", "Autre"),
]


class Badge(BaseModel):
    """Une récompense visuelle débloquée en complétant un défi."""

    name = models.CharField(max_length=100, unique=True)
    description = models.TextField(blank=True)
    icon = models.CharField(
        max_length=50,
        blank=True,
        help_text="Nom d'icône Flutter (ex: 'military_tech'), utilisé côté mobile.",
    )
    color_hex = models.CharField(
        max_length=7, blank=True, help_text="Couleur d'accent, ex: '#FFB300' (optionnel)."
    )

    class Meta:
        ordering = ["name"]

    def __str__(self):
        return self.name


class Challenge(BaseModel):
    """Un défi touristique/gamifié : visiter des lieux d'une catégorie, ou participer
    à des événements d'un type donné, un certain nombre de fois."""

    DIFFICULTY_CHOICES = [
        ("facile", "Facile"),
        ("moyen", "Moyen"),
        ("difficile", "Difficile"),
    ]

    SOURCE_TYPE_CHOICES = [
        ("place_category", "Visites de lieux d'une catégorie"),
        ("event_type", "Participations à des événements d'un type"),
    ]

    title = models.CharField(max_length=200)
    description = models.TextField(blank=True)
    difficulty = models.CharField(max_length=10, choices=DIFFICULTY_CHOICES, default="moyen")
    xp_reward = models.PositiveIntegerField(default=50, help_text="Points d'expérience gagnés une fois complété.")

    source_type = models.CharField(max_length=20, choices=SOURCE_TYPE_CHOICES, default="place_category")
    target_category = models.ForeignKey(
        Category,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="challenges",
        help_text="Requis si source = 'Visites de lieux d'une catégorie'.",
    )
    target_event_type = models.CharField(
        max_length=20,
        choices=EVENT_TYPE_CHOICES,
        blank=True,
        help_text="Requis si source = 'Participations à des événements d'un type'.",
    )
    target_count = models.PositiveSmallIntegerField(default=1, help_text="Nombre à atteindre pour valider le défi.")

    badge = models.ForeignKey(
        Badge,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="unlocked_by_challenges",
        help_text="Badge débloqué à la complétion du défi (optionnel).",
    )
    is_active = models.BooleanField(default=True)

    class Meta:
        ordering = ["difficulty", "title"]

    def __str__(self):
        return self.title


class UserChallengeProgress(BaseModel):
    """Progression d'un utilisateur sur un défi donné."""

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="challenge_progresses"
    )
    challenge = models.ForeignKey(Challenge, on_delete=models.CASCADE, related_name="progresses")
    current_count = models.PositiveSmallIntegerField(default=0)
    completed = models.BooleanField(default=False)
    completed_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        ordering = ["-updated_at"]
        constraints = [
            models.UniqueConstraint(fields=["user", "challenge"], name="unique_progress_user_challenge"),
        ]

    def __str__(self):
        state = "complété" if self.completed else f"{self.current_count}/{self.challenge.target_count}"
        return f"{self.user} - {self.challenge} ({state})"


class UserBadge(BaseModel):
    """Un badge effectivement débloqué par un utilisateur."""

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="badges"
    )
    badge = models.ForeignKey(Badge, on_delete=models.CASCADE, related_name="earned_by")

    class Meta:
        ordering = ["-created_at"]
        constraints = [
            models.UniqueConstraint(fields=["user", "badge"], name="unique_userbadge_user_badge"),
        ]

    def __str__(self):
        return f"{self.user} a débloqué {self.badge}"


class Visit(BaseModel):
    """Un utilisateur marque un lieu touristique comme visité ('check-in').

    Alimente à la fois le profil (nombre de visites, progression d'exploration)
    et la progression des défis de type 'place_category'.
    """

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="visits"
    )
    place = models.ForeignKey(Place, on_delete=models.CASCADE, related_name="visited_by")

    class Meta:
        ordering = ["-created_at"]
        constraints = [
            models.UniqueConstraint(fields=["user", "place"], name="unique_visit_user_place"),
        ]

    def __str__(self):
        return f"{self.user} a visité {self.place}"
