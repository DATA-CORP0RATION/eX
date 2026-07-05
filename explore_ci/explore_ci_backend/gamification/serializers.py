from rest_framework import serializers

from tourism.serializers import CategorySerializer

from .models import Badge, Challenge, UserBadge, Visit


class BadgeSerializer(serializers.ModelSerializer):
    class Meta:
        model = Badge
        fields = ["id", "name", "description", "icon", "color_hex"]


class UserBadgeSerializer(serializers.ModelSerializer):
    badge = BadgeSerializer(read_only=True)

    class Meta:
        model = UserBadge
        fields = ["id", "badge", "created_at"]


class ChallengeSerializer(serializers.ModelSerializer):
    """Défi + progression de l'utilisateur connecté (0 si non connecté / pas commencé)."""

    target_category = CategorySerializer(read_only=True)
    badge = BadgeSerializer(read_only=True)
    current_count = serializers.SerializerMethodField()
    completed = serializers.SerializerMethodField()
    progress_percent = serializers.SerializerMethodField()

    class Meta:
        model = Challenge
        fields = [
            "id",
            "title",
            "description",
            "difficulty",
            "xp_reward",
            "source_type",
            "target_category",
            "target_event_type",
            "target_count",
            "badge",
            "current_count",
            "completed",
            "progress_percent",
        ]

    def _get_progress(self, obj):
        request = self.context.get("request")
        user = getattr(request, "user", None)
        if not user or not user.is_authenticated:
            return None
        # Préchargé en vue via Prefetch(..., to_attr='_user_progress') pour
        # éviter une requête par défi (renvoie une liste de 0 ou 1 élément).
        cached = getattr(obj, "_user_progress", None)
        if cached is not None:
            return cached[0] if cached else None
        return obj.progresses.filter(user=user).first()

    def get_current_count(self, obj):
        progress = self._get_progress(obj)
        return progress.current_count if progress else 0

    def get_completed(self, obj):
        progress = self._get_progress(obj)
        return bool(progress and progress.completed)

    def get_progress_percent(self, obj):
        progress = self._get_progress(obj)
        current = progress.current_count if progress else 0
        if obj.target_count <= 0:
            return 0.0
        return round(min(current / obj.target_count, 1.0) * 100, 1)


class VisitSerializer(serializers.ModelSerializer):
    place_name = serializers.CharField(source="place.name", read_only=True)

    class Meta:
        model = Visit
        fields = ["id", "place", "place_name", "created_at"]
        read_only_fields = ["id", "created_at"]


class ProfileStatsSerializer(serializers.Serializer):
    """Sérialise le dict retourné par gamification.services.get_profile_stats.
    Pas de modèle direct : juste une agrégation calculée à la volée."""

    total_xp = serializers.IntegerField()
    level = serializers.IntegerField()
    xp_into_level = serializers.IntegerField()
    xp_to_next_level = serializers.IntegerField()
    level_progress_percent = serializers.FloatField()
    visits_count = serializers.IntegerField()
    badges_count = serializers.IntegerField()
    challenges_completed_count = serializers.IntegerField()
    total_places = serializers.IntegerField()
    exploration_percent = serializers.FloatField()
