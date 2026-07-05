from django.db.models import Count
from django.shortcuts import get_object_or_404
from rest_framework import generics, permissions, status
from rest_framework.exceptions import PermissionDenied
from rest_framework.response import Response
from rest_framework.views import APIView

from .models import Post, PostComment, PostLike
from .serializers import PostCommentSerializer, PostCreateSerializer, PostListSerializer


def _post_queryset():
    return (
        Post.objects.select_related("user", "place")
        .prefetch_related("images")
        .annotate(
            likes_count=Count("likes", distinct=True),
            comments_count=Count("comments", distinct=True),
        )
    )


class PostListCreateView(generics.ListCreateAPIView):
    """GET : fil communauté (public) — POST : publier (connecté).

    Filtre optionnel : ?place=<uuid> pour ne voir que les publications d'un lieu précis.
    """

    def get_serializer_class(self):
        return PostCreateSerializer if self.request.method == "POST" else PostListSerializer

    def get_permissions(self):
        if self.request.method == "POST":
            return [permissions.IsAuthenticated()]
        return [permissions.AllowAny()]

    def get_queryset(self):
        qs = _post_queryset()
        place_id = self.request.query_params.get("place")
        if place_id:
            qs = qs.filter(place_id=place_id)
        return qs


class PostDetailView(generics.RetrieveDestroyAPIView):
    """Consulter une publication, ou la supprimer si on en est l'auteur."""

    serializer_class = PostListSerializer
    queryset = _post_queryset()

    def get_permissions(self):
        if self.request.method == "DELETE":
            return [permissions.IsAuthenticated()]
        return [permissions.AllowAny()]

    def perform_destroy(self, instance):
        if instance.user_id != self.request.user.id:
            raise PermissionDenied("Vous ne pouvez supprimer que vos propres publications.")
        instance.delete()


class PostLikeToggleView(APIView):
    """POST /posts/<id>/like/ : bascule j'aime/je n'aime plus."""

    permission_classes = [permissions.IsAuthenticated]

    def post(self, request, pk):
        post = get_object_or_404(Post, pk=pk)
        existing = PostLike.objects.filter(user=request.user, post=post).first()

        if existing:
            existing.delete()
            return Response({"liked": False}, status=status.HTTP_200_OK)

        PostLike.objects.create(user=request.user, post=post)
        return Response({"liked": True}, status=status.HTTP_201_CREATED)


class PostCommentListCreateView(generics.ListCreateAPIView):
    """GET : commentaires/conseils d'une publication (public) — POST : commenter (connecté)."""

    serializer_class = PostCommentSerializer

    def get_permissions(self):
        if self.request.method == "POST":
            return [permissions.IsAuthenticated()]
        return [permissions.AllowAny()]

    def get_queryset(self):
        return PostComment.objects.filter(post_id=self.kwargs["pk"]).select_related("user")

    def perform_create(self, serializer):
        post = get_object_or_404(Post, pk=self.kwargs["pk"])
        serializer.save(user=self.request.user, post=post)
