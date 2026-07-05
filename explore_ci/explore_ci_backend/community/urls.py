from django.urls import path

from .views import (
    PostCommentListCreateView,
    PostDetailView,
    PostLikeToggleView,
    PostListCreateView,
)

urlpatterns = [
    path("posts/", PostListCreateView.as_view(), name="post-list-create"),
    path("posts/<uuid:pk>/", PostDetailView.as_view(), name="post-detail"),
    path("posts/<uuid:pk>/like/", PostLikeToggleView.as_view(), name="post-like-toggle"),
    path("posts/<uuid:pk>/comments/", PostCommentListCreateView.as_view(), name="post-comments"),
]
