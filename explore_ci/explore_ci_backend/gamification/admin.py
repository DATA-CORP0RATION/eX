from django.contrib import admin

from .models import Badge, Challenge, UserBadge, UserChallengeProgress, Visit


@admin.register(Badge)
class BadgeAdmin(admin.ModelAdmin):
    list_display = ["name", "icon", "color_hex"]
    search_fields = ["name", "description"]


@admin.register(Challenge)
class ChallengeAdmin(admin.ModelAdmin):
    list_display = [
        "title",
        "difficulty",
        "xp_reward",
        "source_type",
        "target_category",
        "target_event_type",
        "target_count",
        "badge",
        "is_active",
    ]
    list_filter = ["difficulty", "source_type", "is_active"]
    search_fields = ["title", "description"]
    autocomplete_fields = ["target_category", "badge"]


@admin.register(UserChallengeProgress)
class UserChallengeProgressAdmin(admin.ModelAdmin):
    list_display = ["user", "challenge", "current_count", "completed", "completed_at"]
    list_filter = ["completed"]
    search_fields = ["user__email", "challenge__title"]
    autocomplete_fields = ["user", "challenge"]


@admin.register(UserBadge)
class UserBadgeAdmin(admin.ModelAdmin):
    list_display = ["user", "badge", "created_at"]
    search_fields = ["user__email", "badge__name"]
    autocomplete_fields = ["user", "badge"]


@admin.register(Visit)
class VisitAdmin(admin.ModelAdmin):
    list_display = ["user", "place", "created_at"]
    search_fields = ["user__email", "place__name"]
    autocomplete_fields = ["user", "place"]
