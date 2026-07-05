import uuid

from django.db import models
from django.utils import timezone


class ActiveManager(models.Manager):
    """Manager par défaut qui exclut les objets soft-deleted."""

    def get_queryset(self):
        return super().get_queryset().filter(is_deleted=False)


class BaseModel(models.Model):
    """Modèle abstrait de base : UUID PK + soft delete + timestamps.

    Toutes les apps métier (tourism, community, gamification, events, ...)
    doivent en hériter pour respecter les règles métier verrouillées du projet.
    """

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    is_deleted = models.BooleanField(default=False)
    deleted_at = models.DateTimeField(null=True, blank=True)

    objects = ActiveManager()
    all_objects = models.Manager()

    class Meta:
        abstract = True

    def soft_delete(self):
        self.is_deleted = True
        self.deleted_at = timezone.now()
        self.save(update_fields=["is_deleted", "deleted_at"])
