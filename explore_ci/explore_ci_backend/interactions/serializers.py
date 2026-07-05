from rest_framework import serializers

from .models import Favorite, Review


class FavoriteSerializer(serializers.ModelSerializer):
    place_name = serializers.CharField(source="place.name", read_only=True)

    class Meta:
        model = Favorite
        fields = ["id", "place", "place_name", "created_at"]
        read_only_fields = ["id", "created_at"]


class ReviewSerializer(serializers.ModelSerializer):
    user_email = serializers.EmailField(source="user.email", read_only=True)
    user_first_name = serializers.CharField(source="user.first_name", read_only=True)

    class Meta:
        model = Review
        fields = [
            "id",
            "place",
            "user",
            "user_email",
            "user_first_name",
            "rating",
            "comment",
            "created_at",
        ]
        read_only_fields = ["id", "user", "place", "created_at"]
