from rest_framework import serializers

from .models import Post, PostComment, PostImage


class PostImageSerializer(serializers.ModelSerializer):
    class Meta:
        model = PostImage
        fields = ["id", "image_url", "position"]


class PostCommentSerializer(serializers.ModelSerializer):
    user_first_name = serializers.CharField(source="user.first_name", read_only=True)

    class Meta:
        model = PostComment
        fields = ["id", "post", "user", "user_first_name", "content", "created_at"]
        read_only_fields = ["id", "user", "post", "created_at"]


class PostListSerializer(serializers.ModelSerializer):
    """Utilisé pour le fil communauté (léger)."""

    user_first_name = serializers.CharField(source="user.first_name", read_only=True)
    place_name = serializers.CharField(source="place.name", read_only=True, default=None)
    images = PostImageSerializer(many=True, read_only=True)
    likes_count = serializers.SerializerMethodField()
    comments_count = serializers.SerializerMethodField()
    is_liked = serializers.SerializerMethodField()

    class Meta:
        model = Post
        fields = [
            "id",
            "user",
            "user_first_name",
            "place",
            "place_name",
            "content",
            "images",
            "likes_count",
            "comments_count",
            "is_liked",
            "created_at",
        ]
        read_only_fields = ["id", "user", "created_at"]

    def get_likes_count(self, obj):
        return getattr(obj, "likes_count", None) or obj.likes.count()

    def get_comments_count(self, obj):
        return getattr(obj, "comments_count", None) or obj.comments.count()

    def get_is_liked(self, obj):
        request = self.context.get("request")
        user = getattr(request, "user", None)
        if not user or not user.is_authenticated:
            return False
        return obj.likes.filter(user=user).exists()


class PostCreateSerializer(serializers.ModelSerializer):
    """Création d'une publication : accepte une liste d'URLs de photos."""

    image_urls = serializers.ListField(
        child=serializers.URLField(), write_only=True, required=False, default=list
    )

    class Meta:
        model = Post
        fields = ["id", "place", "content", "image_urls", "created_at"]
        read_only_fields = ["id", "created_at"]

    def create(self, validated_data):
        image_urls = validated_data.pop("image_urls", [])
        request = self.context["request"]
        post = Post.objects.create(user=request.user, **validated_data)
        PostImage.objects.bulk_create(
            [PostImage(post=post, image_url=url, position=i) for i, url in enumerate(image_urls)]
        )
        return post

    def to_representation(self, instance):
        # Après création, on renvoie la représentation complète (images, compteurs...)
        return PostListSerializer(instance, context=self.context).data
