import uuid

import django.db.models.deletion
from django.conf import settings
from django.db import migrations, models


class Migration(migrations.Migration):

    initial = True

    dependencies = [
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
        ("tourism", "0001_initial"),
    ]

    operations = [
        migrations.CreateModel(
            name="Favorite",
            fields=[
                ("id", models.UUIDField(default=uuid.uuid4, editable=False, primary_key=True, serialize=False)),
                ("created_at", models.DateTimeField(auto_now_add=True)),
                ("updated_at", models.DateTimeField(auto_now=True)),
                ("is_deleted", models.BooleanField(default=False)),
                ("deleted_at", models.DateTimeField(blank=True, null=True)),
                ("place", models.ForeignKey(
                    on_delete=django.db.models.deletion.CASCADE,
                    related_name="favorited_by",
                    to="tourism.place",
                )),
                ("user", models.ForeignKey(
                    on_delete=django.db.models.deletion.CASCADE,
                    related_name="favorites",
                    to=settings.AUTH_USER_MODEL,
                )),
            ],
            options={
                "ordering": ["-created_at"],
                "abstract": False,
            },
        ),
        migrations.CreateModel(
            name="Review",
            fields=[
                ("id", models.UUIDField(default=uuid.uuid4, editable=False, primary_key=True, serialize=False)),
                ("created_at", models.DateTimeField(auto_now_add=True)),
                ("updated_at", models.DateTimeField(auto_now=True)),
                ("is_deleted", models.BooleanField(default=False)),
                ("deleted_at", models.DateTimeField(blank=True, null=True)),
                ("rating", models.PositiveSmallIntegerField(
                    choices=[(1, "1"), (2, "2"), (3, "3"), (4, "4"), (5, "5")]
                )),
                ("comment", models.TextField(blank=True)),
                ("place", models.ForeignKey(
                    on_delete=django.db.models.deletion.CASCADE,
                    related_name="reviews",
                    to="tourism.place",
                )),
                ("user", models.ForeignKey(
                    on_delete=django.db.models.deletion.CASCADE,
                    related_name="reviews",
                    to=settings.AUTH_USER_MODEL,
                )),
            ],
            options={
                "ordering": ["-created_at"],
                "abstract": False,
            },
        ),
        migrations.AddConstraint(
            model_name="favorite",
            constraint=models.UniqueConstraint(fields=("user", "place"), name="unique_favorite_user_place"),
        ),
        migrations.AddConstraint(
            model_name="review",
            constraint=models.UniqueConstraint(fields=("user", "place"), name="unique_review_user_place"),
        ),
    ]
