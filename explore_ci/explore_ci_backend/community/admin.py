from django.contrib import admin

from .models import Post, PostComment, PostImage, PostLike


class PostImageInline(admin.TabularInline):
    model = PostImage
    extra = 1


@admin.register(Post)
class PostAdmin(admin.ModelAdmin):
    list_display = ["user", "place", "created_at"]
    search_fields = ["user__email", "content"]
    autocomplete_fields = ["user", "place"]
    inlines = [PostImageInline]


@admin.register(PostLike)
class PostLikeAdmin(admin.ModelAdmin):
    list_display = ["user", "post", "created_at"]
    autocomplete_fields = ["user", "post"]


@admin.register(PostComment)
class PostCommentAdmin(admin.ModelAdmin):
    list_display = ["user", "post", "created_at"]
    search_fields = ["user__email", "content"]
    autocomplete_fields = ["user", "post"]
