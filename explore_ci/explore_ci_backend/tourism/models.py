from django.db import models

from core.models import BaseModel


class Category(BaseModel):
    """Catégorie d'un lieu touristique (ex: Plage, Parc national, Musée...)."""

    name = models.CharField(max_length=100, unique=True)
    slug = models.SlugField(max_length=100, unique=True)
    icon = models.CharField(
        max_length=50,
        blank=True,
        help_text="Nom d'icône Flutter (ex: 'beach_access'), utilisé côté mobile.",
    )

    class Meta:
        ordering = ["name"]
        verbose_name_plural = "Categories"

    def __str__(self):
        return self.name


class Region(BaseModel):
    """Région / zone géographique de Côte d'Ivoire (ex: Abidjan, Yamoussoukro...)."""

    name = models.CharField(max_length=100, unique=True)
    slug = models.SlugField(max_length=100, unique=True)

    class Meta:
        ordering = ["name"]

    def __str__(self):
        return self.name


class Place(BaseModel):
    """Un lieu touristique : le cœur métier de la VVP."""

    name = models.CharField(max_length=200)
    description = models.TextField()
    category = models.ForeignKey(Category, on_delete=models.PROTECT, related_name="places")
    region = models.ForeignKey(Region, on_delete=models.PROTECT, related_name="places")
    address = models.CharField(max_length=255, blank=True)
    latitude = models.DecimalField(max_digits=9, decimal_places=6)
    longitude = models.DecimalField(max_digits=9, decimal_places=6)
    cover_image_url = models.URLField(blank=True)

    class Meta:
        ordering = ["name"]
        indexes = [
            models.Index(fields=["category"], name="tourism_place_category_idx"),
            models.Index(fields=["region"], name="tourism_place_region_idx"),
        ]

    def __str__(self):
        return self.name
