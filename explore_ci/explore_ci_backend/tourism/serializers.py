from rest_framework import serializers

from .models import Category, Place, Region


class CategorySerializer(serializers.ModelSerializer):
    class Meta:
        model = Category
        fields = ["id", "name", "slug", "icon"]


class RegionSerializer(serializers.ModelSerializer):
    class Meta:
        model = Region
        fields = ["id", "name", "slug"]


class PlaceListSerializer(serializers.ModelSerializer):
    """Utilisé pour la liste des lieux et l'affichage carte (léger)."""

    category = CategorySerializer(read_only=True)
    region = RegionSerializer(read_only=True)
    average_rating = serializers.SerializerMethodField()
    reviews_count = serializers.SerializerMethodField()
    is_favorited = serializers.SerializerMethodField()

    class Meta:
        model = Place
        fields = [
            "id",
            "name",
            "category",
            "region",
            "latitude",
            "longitude",
            "cover_image_url",
            "average_rating",
            "reviews_count",
            "is_favorited",
        ]

    def get_average_rating(self, obj):
        value = getattr(obj, "average_rating", None)
        return round(value, 1) if value is not None else None

    def get_reviews_count(self, obj):
        return getattr(obj, "reviews_count", 0) or 0

    def get_is_favorited(self, obj):
        request = self.context.get("request")
        user = getattr(request, "user", None)
        if not user or not user.is_authenticated:
            return False
        return obj.favorited_by.filter(user=user).exists()


class PlaceDetailSerializer(PlaceListSerializer):
    """Utilisé pour la fiche détaillée d'un lieu (ajoute description/adresse)."""

    class Meta(PlaceListSerializer.Meta):
        fields = PlaceListSerializer.Meta.fields + ["description", "address", "created_at"]
