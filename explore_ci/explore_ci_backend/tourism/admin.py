from django.contrib import admin

from .models import Category, Place, Region


@admin.register(Category)
class CategoryAdmin(admin.ModelAdmin):
    list_display = ["name", "slug"]
    prepopulated_fields = {"slug": ("name",)}
    search_fields = ["name"]


@admin.register(Region)
class RegionAdmin(admin.ModelAdmin):
    list_display = ["name", "slug"]
    prepopulated_fields = {"slug": ("name",)}
    search_fields = ["name"]


@admin.register(Place)
class PlaceAdmin(admin.ModelAdmin):
    list_display = ["name", "category", "region", "latitude", "longitude", "created_at"]
    list_filter = ["category", "region"]
    search_fields = ["name", "description", "address"]
    autocomplete_fields = ["category", "region"]
