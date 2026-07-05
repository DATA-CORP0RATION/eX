"""
Commande de gestion : injecte des badges et défis touristiques de démo,
alignés sur les catégories déjà présentes via `seed_places` et sur les
exemples de la spécification VVP (sites historiques, plages, cascades,
parc national, festival culturel).

Usage :
    python manage.py seed_places          # d'abord, si pas déjà fait
    python manage.py seed_challenges
    python manage.py seed_challenges --flush   # vide Badge/Challenge avant de réinjecter
"""
from django.core.management.base import BaseCommand
from django.db import transaction

from gamification.models import Badge, Challenge
from tourism.models import Category

# (nom, description, icône, couleur)
BADGES = [
    ("Historien en herbe", "Décerné pour la découverte de sites historiques.", "account_balance", "#8D6E63"),
    ("Enfant du littoral", "Décerné pour l'exploration des plus belles plages.", "beach_access", "#29B6F6"),
    ("Aventurier des cascades", "Décerné pour l'exploration des cascades et sites naturels.", "water", "#26A69A"),
    ("Gardien de la nature", "Décerné pour la visite d'un parc national.", "forest", "#66BB6A"),
    ("Fêtard culturel", "Décerné pour la participation à un festival culturel.", "celebration", "#AB47BC"),
]

# (titre, description, difficulté, xp, catégorie cible, nb cible, badge)
PLACE_CHALLENGES = [
    (
        "Sur les traces de l'histoire",
        "Visiter 3 sites historiques de Côte d'Ivoire.",
        "moyen", 120, "Site historique", 3, "Historien en herbe",
    ),
    (
        "Les plus belles plages du littoral",
        "Découvrir 3 plages parmi les plus belles du littoral ivoirien.",
        "facile", 90, "Plage", 3, "Enfant du littoral",
    ),
    (
        "Explorateur de cascades",
        "Explorer 2 sites naturels (cascades, jardins, réserves).",
        "difficile", 150, "Nature & cascades", 2, "Aventurier des cascades",
    ),
    (
        "Immersion nationale",
        "Visiter un parc national ivoirien.",
        "moyen", 100, "Parc national", 1, "Gardien de la nature",
    ),
]

# (titre, description, difficulté, xp, type d'événement, nb cible, badge)
EVENT_CHALLENGES = [
    (
        "Esprit festif",
        "Participer à un festival culturel en Côte d'Ivoire.",
        "facile", 80, "festival", 1, "Fêtard culturel",
    ),
]


class Command(BaseCommand):
    help = "Injecte des badges et défis touristiques de démonstration."

    def add_arguments(self, parser):
        parser.add_argument(
            "--flush",
            action="store_true",
            help="Vide Badge et Challenge avant de réinjecter les données.",
        )

    @transaction.atomic
    def handle(self, *args, **options):
        if options["flush"]:
            Challenge.objects.all().delete()
            Badge.objects.all().delete()
            self.stdout.write(self.style.WARNING("Badge et Challenge vidés."))

        badges_by_name = {}
        for name, description, icon, color_hex in BADGES:
            badge, created = Badge.objects.get_or_create(
                name=name,
                defaults={"description": description, "icon": icon, "color_hex": color_hex},
            )
            badges_by_name[name] = badge
            if created:
                self.stdout.write(f"  + Badge créé : {name}")

        created_count = 0
        skipped_count = 0

        for title, description, difficulty, xp, category_name, target_count, badge_name in PLACE_CHALLENGES:
            category = Category.objects.filter(name=category_name).first()
            if category is None:
                self.stdout.write(
                    self.style.WARNING(
                        f"  ! Catégorie '{category_name}' introuvable, défi '{title}' ignoré "
                        "(lancez d'abord 'python manage.py seed_places')."
                    )
                )
                skipped_count += 1
                continue

            _, created = Challenge.objects.get_or_create(
                title=title,
                defaults={
                    "description": description,
                    "difficulty": difficulty,
                    "xp_reward": xp,
                    "source_type": "place_category",
                    "target_category": category,
                    "target_count": target_count,
                    "badge": badges_by_name.get(badge_name),
                },
            )
            if created:
                created_count += 1
                self.stdout.write(f"  + Défi créé : {title}")

        for title, description, difficulty, xp, event_type, target_count, badge_name in EVENT_CHALLENGES:
            _, created = Challenge.objects.get_or_create(
                title=title,
                defaults={
                    "description": description,
                    "difficulty": difficulty,
                    "xp_reward": xp,
                    "source_type": "event_type",
                    "target_event_type": event_type,
                    "target_count": target_count,
                    "badge": badges_by_name.get(badge_name),
                },
            )
            if created:
                created_count += 1
                self.stdout.write(f"  + Défi créé : {title}")

        self.stdout.write(
            self.style.SUCCESS(
                f"Terminé : {created_count} défi(s) créé(s), {skipped_count} ignoré(s)."
            )
        )
