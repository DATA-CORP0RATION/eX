from django.conf import settings
from django.db import models

from core.models import BaseModel
from tourism.models import Place


class Post(BaseModel):
    """Publication d'un voyageur : récit, conseil pratique ou photos, liée ou non à un lieu."""

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="posts"
    )
    place = models.ForeignKey(
        Place,
        on_delete=models.SET_NULL,
        related_name="posts",
        null=True,
        blank=True,
        help_text="Lieu visité associé à la publication (optionnel).",
    )
    content = models.TextField()

    class Meta:
        ordering = ["-created_at"]

    def __str__(self):
        return f"{self.user} - {self.content[:40]}"


class PostImage(BaseModel):
    """Photo attachée à une publication (URL externe, cohérent avec cover_image_url de Place)."""

    post = models.ForeignKey(Post, on_delete=models.CASCADE, related_name="images")
    image_url = models.URLField()
    position = models.PositiveSmallIntegerField(default=0)

    class Meta:
        ordering = ["position", "created_at"]

    def __str__(self):
        return f"Photo de {self.post_id}"


class PostLike(BaseModel):
    """Un utilisateur aime une publication."""

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="post_likes"
    )
    post = models.ForeignKey(Post, on_delete=models.CASCADE, related_name="likes")

    class Meta:
        ordering = ["-created_at"]
        constraints = [
            models.UniqueConstraint(fields=["user", "post"], name="unique_like_user_post"),
        ]

    def __str__(self):
        return f"{self.user} aime {self.post_id}"


class PostComment(BaseModel):
    """Commentaire / conseil pratique en réponse à une publication."""

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="post_comments"
    )
    post = models.ForeignKey(Post, on_delete=models.CASCADE, related_name="comments")
    content = models.TextField()

    class Meta:
        ordering = ["created_at"]

    def __str__(self):
        return f"{self.user} sur {self.post_id}"
