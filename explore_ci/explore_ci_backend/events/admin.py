from django.contrib import admin

from .models import Event, EventParticipation


@admin.register(Event)
class EventAdmin(admin.ModelAdmin):
    list_display = ["title", "event_type", "region", "start_datetime", "price"]
    list_filter = ["event_type", "region"]
    search_fields = ["title", "description", "location_name"]
    autocomplete_fields = ["region", "place"]


@admin.register(EventParticipation)
class EventParticipationAdmin(admin.ModelAdmin):
    list_display = ["user", "event", "created_at"]
    search_fields = ["user__email", "event__title"]
    autocomplete_fields = ["user", "event"]
