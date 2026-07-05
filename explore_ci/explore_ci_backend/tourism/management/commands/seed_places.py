"""
Commande de gestion : injecte les catégories, régions et environ 50 lieux
touristiques ivoiriens réels en base (section 4 de la spécification VVP).

Usage :
    python manage.py seed_places
    python manage.py seed_places --flush   # vide Category/Region/Place avant de réinjecter

Note : les coordonnées GPS ci-dessous sont des approximations raisonnables
(centre-ville / site le plus proche connu), suffisantes pour la démo carte
de la VVP. À affiner si besoin avant une mise en production réelle.
"""
from django.core.management.base import BaseCommand
from django.db import transaction
from django.utils.text import slugify

from tourism.models import Category, Place, Region

CATEGORIES = [
    "Plage",
    "Parc national",
    "Site religieux",
    "Site culturel",
    "Site historique",
    "Nature & cascades",
    "Marché & artisanat",
    "Musée",
    "Montagne",
]

REGIONS = [
    "Abidjan",
    "Yamoussoukro",
    "Grand-Bassam",
    "San-Pédro",
    "Man",
    "Korhogo",
    "Bouaké",
    "Sassandra",
    "Assinie",
    "Bondoukou",
    "Odienné",
    "Daloa",
    "Taï",
    "Comoé",
]

# (nom, catégorie, région, latitude, longitude, description, adresse)
PLACES = [
    # --- Abidjan ---
    ("Cathédrale Saint-Paul d'Abidjan", "Site religieux", "Abidjan", 5.3167, -4.0208,
     "Cathédrale moderne au Plateau, silhouette emblématique du skyline d'Abidjan.",
     "Plateau, Abidjan"),
    ("Musée des Civilisations de Côte d'Ivoire", "Musée", "Abidjan", 5.3200, -4.0233,
     "Musée national consacré aux arts et cultures traditionnelles ivoiriennes.",
     "Plateau, Abidjan"),
    ("Plage de Vridi", "Plage", "Abidjan", 5.2660, -4.0130,
     "Longue plage de sable proche du port, prisée le week-end.",
     "Vridi, Abidjan"),
    ("Parc National du Banco", "Parc national", "Abidjan", 5.3833, -4.0500,
     "Forêt primaire au cœur de l'agglomération, sentiers et rivières.",
     "Attécoubé, Abidjan"),
    ("Zoo national d'Abidjan", "Site culturel", "Abidjan", 5.3608, -4.0086,
     "Parc animalier historique de la ville, en cours de réhabilitation.",
     "Cocody, Abidjan"),
    ("Marché de Cocody", "Marché & artisanat", "Abidjan", 5.3450, -3.9950,
     "Marché de quartier animé, produits frais et artisanat local.",
     "Cocody, Abidjan"),
    ("Marché de Treichville", "Marché & artisanat", "Abidjan", 5.2919, -4.0086,
     "L'un des plus grands marchés populaires d'Abidjan.",
     "Treichville, Abidjan"),
    ("Village Ki-Yi M'Bock", "Site culturel", "Abidjan", 5.3450, -3.9800,
     "Village culturel dédié aux arts de la scène et à l'artisanat panafricain.",
     "Cocody, Abidjan"),
    ("Mosquée du Plateau", "Site religieux", "Abidjan", 5.3220, -4.0210,
     "Grande mosquée du quartier des affaires d'Abidjan.",
     "Plateau, Abidjan"),
    ("Jardin botanique de Bingerville", "Nature & cascades", "Abidjan", 5.3560, -3.8890,
     "Jardin botanique historique fondé à l'époque coloniale, à l'est d'Abidjan.",
     "Bingerville, Abidjan"),
    ("Fondation Donwahi (art contemporain)", "Musée", "Abidjan", 5.3390, -3.9930,
     "Espace dédié à l'art contemporain ivoirien et africain.",
     "Cocody, Abidjan"),
    ("Marché d'Adjamé", "Marché & artisanat", "Abidjan", 5.3550, -4.0270,
     "Immense marché populaire, l'un des plus fréquentés d'Afrique de l'Ouest.",
     "Adjamé, Abidjan"),

    # --- Grand-Bassam ---
    ("Quartier colonial de Grand-Bassam", "Site historique", "Grand-Bassam", 5.2100, -3.7380,
     "Ancienne capitale coloniale classée au patrimoine mondial de l'UNESCO.",
     "Grand-Bassam"),
    ("Musée National du Costume", "Musée", "Grand-Bassam", 5.2090, -3.7390,
     "Musée installé dans l'ancien palais du gouverneur, costumes traditionnels.",
     "Quartier France, Grand-Bassam"),
    ("Plage de Grand-Bassam", "Plage", "Grand-Bassam", 5.1980, -3.7500,
     "Longue plage bordée de cocotiers, très fréquentée le dimanche.",
     "Grand-Bassam"),
    ("Village artisanal N'zima", "Marché & artisanat", "Grand-Bassam", 5.2050, -3.7420,
     "Ateliers d'artisans (bois, tissus, bijoux) en bord de lagune.",
     "Grand-Bassam"),
    ("Ancien Palais de Justice de Grand-Bassam", "Site historique", "Grand-Bassam", 5.2110, -3.7370,
     "Bâtiment colonial emblématique du centre historique de Bassam.",
     "Quartier France, Grand-Bassam"),

    # --- Yamoussoukro ---
    ("Basilique Notre-Dame de la Paix", "Site religieux", "Yamoussoukro", 6.8067, -5.2767,
     "L'une des plus grandes basiliques catholiques au monde.",
     "Yamoussoukro"),
    ("Fondation Félix Houphouët-Boigny", "Site historique", "Yamoussoukro", 6.8100, -5.2800,
     "Fondation dédiée à la mémoire du premier président ivoirien.",
     "Yamoussoukro"),
    ("Lac aux Caïmans", "Nature & cascades", "Yamoussoukro", 6.8200, -5.2900,
     "Bassin sacré près du palais présidentiel, célèbre pour ses caïmans nourris rituellement.",
     "Yamoussoukro"),
    ("Grande Mosquée de Yamoussoukro", "Site religieux", "Yamoussoukro", 6.8150, -5.2830,
     "Principale mosquée de la capitale politique ivoirienne.",
     "Yamoussoukro"),
    ("Réserve d'Abokouamekro", "Parc national", "Yamoussoukro", 7.4500, -5.0500,
     "Réserve de faune abritant éléphants, girafes et antilopes réintroduits.",
     "Toumodi, région de Yamoussoukro"),

    # --- San-Pédro ---
    ("Plage de San-Pédro", "Plage", "San-Pédro", 4.7467, -6.6363,
     "Plage animée proche du deuxième port du pays.",
     "San-Pédro"),
    ("Port autonome de San-Pédro", "Site culturel", "San-Pédro", 4.7350, -6.6400,
     "Port majeur d'exportation du cacao ivoirien, visites organisées possibles.",
     "San-Pédro"),
    ("Mont Korabo", "Montagne", "San-Pédro", 4.8500, -6.5500,
     "Point de vue sur la forêt et le littoral proche de San-Pédro.",
     "Région de San-Pédro"),

    # --- Sassandra ---
    ("Ville coloniale de Sassandra", "Site historique", "Sassandra", 4.9500, -6.0833,
     "Ancien comptoir colonial, architecture coloniale préservée en bord de mer.",
     "Sassandra"),
    ("Plage de Sassandra (Poly-Plage)", "Plage", "Sassandra", 4.9450, -6.0900,
     "Plage réputée pour le surf et ses vagues régulières.",
     "Sassandra"),
    ("Phare de Sassandra", "Site historique", "Sassandra", 4.9480, -6.0870,
     "Ancien phare surplombant l'embouchure du fleuve Sassandra.",
     "Sassandra"),

    # --- Assinie ---
    ("Plage d'Assinie", "Plage", "Assinie", 5.1333, -3.2833,
     "Station balnéaire réputée, sable fin entre lagune et océan.",
     "Assinie-Mafia"),
    ("Lagune Aby", "Nature & cascades", "Assinie", 5.2000, -3.2600,
     "Grande lagune propice aux balades en pirogue et sports nautiques.",
     "Assinie"),
    ("Village d'Assouindé", "Plage", "Assinie", 5.1500, -3.3800,
     "Petit village de pêcheurs entre lagune Ébrié et océan Atlantique.",
     "Assouindé, Assinie"),
    ("Presqu'île d'Etuéboué", "Plage", "Assinie", 5.1200, -3.2500,
     "Bande de sable isolée entre lagune et océan, accessible en pirogue.",
     "Assinie"),

    # --- Man ---
    ("Cascade de Man (la Métisse)", "Nature & cascades", "Man", 7.4000, -7.5500,
     "Chute d'eau au cœur de la forêt tropicale des montagnes de l'Ouest.",
     "Man"),
    ("Mont Tonkoui", "Montagne", "Man", 7.5000, -7.6333,
     "Sommet parmi les plus élevés de Côte d'Ivoire, vue sur plusieurs pays voisins.",
     "Région de Man"),
    ("Dent de Man", "Montagne", "Man", 7.4200, -7.5200,
     "Formation rocheuse emblématique surplombant la ville de Man.",
     "Man"),
    ("Pont de lianes de Man", "Nature & cascades", "Man", 7.4100, -7.5300,
     "Pont suspendu traditionnel en lianes, toujours utilisé par les villageois.",
     "Village proche de Man"),
    ("Marché de Man", "Marché & artisanat", "Man", 7.4125, -7.5540,
     "Marché régional connu pour le masque et l'artisanat Dan/Yacouba.",
     "Man"),

    # --- Korhogo ---
    ("Village de Waraniéné", "Marché & artisanat", "Korhogo", 9.4500, -5.6800,
     "Village de tisserands sénoufo, démonstrations de tissage traditionnel.",
     "Waraniéné, Korhogo"),
    ("Village de Fakaha", "Site culturel", "Korhogo", 9.4000, -5.6000,
     "Village réputé pour la fabrication de masques rituels sénoufo.",
     "Fakaha, Korhogo"),
    ("Grande Mosquée de Korhogo", "Site religieux", "Korhogo", 9.4578, -5.6297,
     "Mosquée principale du nord de la Côte d'Ivoire.",
     "Korhogo"),
    ("Marché central de Korhogo", "Marché & artisanat", "Korhogo", 9.4570, -5.6280,
     "Grand marché du nord, textiles et artisanat sénoufo.",
     "Korhogo"),

    # --- Bouaké ---
    ("Grande Mosquée de Bouaké", "Site religieux", "Bouaké", 7.6900, -5.0300,
     "Principale mosquée de la deuxième ville du pays.",
     "Bouaké"),
    ("Marché de Bouaké (Habitat)", "Marché & artisanat", "Bouaké", 7.6833, -5.0300,
     "Vaste marché central, cœur commercial de Bouaké.",
     "Bouaké"),

    # --- Bondoukou ---
    ("Mosquée de Bondoukou", "Site religieux", "Bondoukou", 8.0400, -2.8000,
     "Mosquée ancienne de style soudanais, ville carrefour historique.",
     "Bondoukou"),
    ("Grottes de Bondoukou", "Site culturel", "Bondoukou", 8.0350, -2.8100,
     "Site naturel et sacré aux abords de la ville de Bondoukou.",
     "Région de Bondoukou"),

    # --- Odienné ---
    ("Mont Nimba", "Montagne", "Odienné", 7.6000, -8.4000,
     "Réserve de biosphère UNESCO à la frontière Guinée/Liberia/Côte d'Ivoire.",
     "Région d'Odienné"),
    ("Chutes du Bafing", "Nature & cascades", "Odienné", 9.5000, -8.0000,
     "Chutes sur le fleuve Bafing, au nord-ouest du pays.",
     "Région d'Odienné"),

    # --- Daloa ---
    ("Cathédrale de Daloa", "Site religieux", "Daloa", 6.8770, -6.4502,
     "Cathédrale catholique, principal lieu de culte de la ville.",
     "Daloa"),

    # --- Parcs nationaux emblématiques ---
    ("Parc National de Taï", "Parc national", "Taï", 5.8500, -7.3500,
     "Dernier grand massif de forêt primaire d'Afrique de l'Ouest, classé UNESCO.",
     "Taï"),
    ("Parc National de la Comoé", "Parc national", "Comoé", 9.0000, -3.7833,
     "L'un des plus grands parcs nationaux d'Afrique de l'Ouest, classé UNESCO.",
     "Comoé"),
]


class Command(BaseCommand):
    help = "Injecte les catégories, régions et ~50 lieux touristiques ivoiriens de démonstration."

    def add_arguments(self, parser):
        parser.add_argument(
            "--flush",
            action="store_true",
            help="Vide d'abord Place/Category/Region avant de réinjecter.",
        )

    @transaction.atomic
    def handle(self, *args, **options):
        if options["flush"]:
            Place.all_objects.all().delete()
            Category.all_objects.all().delete()
            Region.all_objects.all().delete()
            self.stdout.write(self.style.WARNING("Anciennes données (Place/Category/Region) supprimées."))

        categories = {}
        for name in CATEGORIES:
            cat, _ = Category.objects.get_or_create(slug=slugify(name), defaults={"name": name})
            categories[name] = cat

        regions = {}
        for name in REGIONS:
            reg, _ = Region.objects.get_or_create(slug=slugify(name), defaults={"name": name})
            regions[name] = reg

        created = 0
        for name, cat_name, reg_name, lat, lng, description, address in PLACES:
            _, was_created = Place.objects.get_or_create(
                name=name,
                defaults={
                    "category": categories[cat_name],
                    "region": regions[reg_name],
                    "latitude": lat,
                    "longitude": lng,
                    "description": description,
                    "address": address,
                },
            )
            if was_created:
                created += 1

        self.stdout.write(
            self.style.SUCCESS(
                f"{len(categories)} catégories, {len(regions)} régions, {created} nouveaux lieux créés "
                f"(total en base : {Place.objects.count()} lieux)."
            )
        )
