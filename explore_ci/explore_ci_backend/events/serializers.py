from rest_framework import serializers

from tourism.serializers import RegionSerializer

from .models import Event, EventParticipation


class EventListSerializer(serializers.ModelSerializer):
    """Utilisé pour la liste du calendrier (léger)."""

    region = RegionSerializer(read_only=True)
    participants_count = serializers.SerializerMethodField()
    is_participating = serializers.SerializerMethodField()
    is_free = serializers.BooleanField(read_only=True)

    class Meta:
        model = Event
        fields = [
            "id",
            "title",
            "event_type",
            "region",
            "location_name",
            "start_datetime",
            "end_datetime",
            "price",
            "is_free",
            "cover_image_url",
            "participants_count",
            "is_participating",
        ]

    def get_participants_count(self, obj):
        return getattr(obj, "participants_count", None) or obj.participants.count()

    def get_is_participating(self, obj):
        request = self.context.get("request")
        user = getattr(request, "user", None)
        if not user or not user.is_authenticated:
            return False
        return obj.participants.filter(user=user).exists()


class EventDetailSerializer(EventListSerializer):
    """Fiche détaillée d'un événement (ajoute description, lieu, réservation)."""

    class Meta(EventListSerializer.Meta):
        fields = EventListSerializer.Meta.fields + [
            "description",
            "place",
            "booking_url",
            "created_at",
        ]


class EventParticipationSerializer(serializers.ModelSerializer):
    event_title = serializers.CharField(source="event.title", read_only=True)

    class Meta:
        model = EventParticipation
        fields = ["id", "event", "event_title", "created_at"]
        read_only_fields = ["id", "created_at"]
