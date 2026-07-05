from django.contrib import admin

from .models import Favorite, Review


@admin.register(Favorite)
class FavoriteAdmin(admin.ModelAdmin):
    list_display = ["user", "place", "created_at"]
    search_fields = ["user__email", "place__name"]
    autocomplete_fields = ["user", "place"]


@admin.register(Review)
class ReviewAdmin(admin.ModelAdmin):
    list_display = ["user", "place", "rating", "created_at"]
    list_filter = ["rating"]
    search_fields = ["user__email", "place__name", "comment"]
    autocomplete_fields = ["user", "place"]
