import uuid

import django.db.models.deletion
from django.db import migrations, models


class Migration(migrations.Migration):

    initial = True

    dependencies = []

    operations = [
        migrations.CreateModel(
            name="Category",
            fields=[
                ("id", models.UUIDField(default=uuid.uuid4, editable=False, primary_key=True, serialize=False)),
                ("created_at", models.DateTimeField(auto_now_add=True)),
                ("updated_at", models.DateTimeField(auto_now=True)),
                ("is_deleted", models.BooleanField(default=False)),
                ("deleted_at", models.DateTimeField(blank=True, null=True)),
                ("name", models.CharField(max_length=100, unique=True)),
                ("slug", models.SlugField(max_length=100, unique=True)),
                ("icon", models.CharField(
                    blank=True,
                    help_text="Nom d'icône Flutter (ex: 'beach_access'), utilisé côté mobile.",
                    max_length=50,
                )),
            ],
            options={
                "verbose_name_plural": "Categories",
                "ordering": ["name"],
                "abstract": False,
            },
        ),
        migrations.CreateModel(
            name="Region",
            fields=[
                ("id", models.UUIDField(default=uuid.uuid4, editable=False, primary_key=True, serialize=False)),
                ("created_at", models.DateTimeField(auto_now_add=True)),
                ("updated_at", models.DateTimeField(auto_now=True)),
                ("is_deleted", models.BooleanField(default=False)),
                ("deleted_at", models.DateTimeField(blank=True, null=True)),
                ("name", models.CharField(max_length=100, unique=True)),
                ("slug", models.SlugField(max_length=100, unique=True)),
            ],
            options={
                "ordering": ["name"],
                "abstract": False,
            },
        ),
        migrations.CreateModel(
            name="Place",
            fields=[
                ("id", models.UUIDField(default=uuid.uuid4, editable=False, primary_key=True, serialize=False)),
                ("created_at", models.DateTimeField(auto_now_add=True)),
                ("updated_at", models.DateTimeField(auto_now=True)),
                ("is_deleted", models.BooleanField(default=False)),
                ("deleted_at", models.DateTimeField(blank=True, null=True)),
                ("name", models.CharField(max_length=200)),
                ("description", models.TextField()),
                ("address", models.CharField(blank=True, max_length=255)),
                ("latitude", models.DecimalField(decimal_places=6, max_digits=9)),
                ("longitude", models.DecimalField(decimal_places=6, max_digits=9)),
                ("cover_image_url", models.URLField(blank=True)),
                ("category", models.ForeignKey(
                    on_delete=django.db.models.deletion.PROTECT,
                    related_name="places",
                    to="tourism.category",
                )),
                ("region", models.ForeignKey(
                    on_delete=django.db.models.deletion.PROTECT,
                    related_name="places",
                    to="tourism.region",
                )),
            ],
            options={
                "ordering": ["name"],
                "abstract": False,
            },
        ),
        migrations.AddIndex(
            model_name="place",
            index=models.Index(fields=["category"], name="tourism_place_category_idx"),
        ),
        migrations.AddIndex(
            model_name="place",
            index=models.Index(fields=["region"], name="tourism_place_region_idx"),
        ),
    ]
