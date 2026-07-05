"""Logique de gamification : mise à jour de la progression des défis,
calcul du niveau/XP, et agrégation des statistiques de profil.

Isolée ici pour pouvoir être appelée aussi bien depuis l'app gamification
(quand un lieu est marqué visité) que depuis l'app events (quand un
utilisateur indique participer à un événement) sans dépendance circulaire :
events -> gamification.services, jamais l'inverse.
"""
from django.db.models import Sum
from django.utils import timezone

from .models import Challenge, UserBadge, UserChallengeProgress, Visit

# Un niveau tous les 200 XP. Simple et lisible pour un MVP.
XP_PER_LEVEL = 200


def _mark_progress(user, challenge, current_count):
    """Crée/actualise la progression d'un utilisateur sur un défi, et débloque
    le badge associé si la cible est atteinte (une fois débloqué, un défi/badge
    n'est jamais 'redégradé' même si l'utilisateur retire une visite ensuite)."""

    progress, _ = UserChallengeProgress.objects.get_or_create(user=user, challenge=challenge)

    if progress.completed:
        return progress

    progress.current_count = current_count
    if current_count >= challenge.target_count:
        progress.completed = True
        progress.completed_at = timezone.now()
        if challenge.badge_id:
            UserBadge.objects.get_or_create(user=user, badge_id=challenge.badge_id)

    progress.save(update_fields=["current_count", "completed", "completed_at", "updated_at"])
    return progress


def apply_visit_progress(user, place):
    """À appeler après la création d'un Visit : recalcule la progression de
    tous les défis 'place_category' concernant la catégorie de ce lieu."""

    challenges = Challenge.objects.filter(
        is_active=True, source_type="place_category", target_category=place.category
    )
    for challenge in challenges:
        count = Visit.objects.filter(user=user, place__category=challenge.target_category).count()
        _mark_progress(user, challenge, count)


def apply_event_participation_progress(user, event_type):
    """À appeler après la création d'une EventParticipation : recalcule la
    progression de tous les défis 'event_type' concernant ce type d'événement.

    Import différé de events.models pour éviter tout risque de dépendance
    circulaire au chargement de l'app registry.
    """
    from events.models import EventParticipation

    challenges = Challenge.objects.filter(
        is_active=True, source_type="event_type", target_event_type=event_type
    )
    for challenge in challenges:
        count = EventParticipation.objects.filter(
            user=user, event__event_type=event_type
        ).count()
        _mark_progress(user, challenge, count)


def get_profile_stats(user):
    """Agrège les statistiques affichées sur l'écran de profil :
    XP total, niveau, progression vers le niveau suivant, visites, badges,
    et progression d'exploration du pays (lieux visités / total des lieux)."""

    from tourism.models import Place

    total_xp = (
        UserChallengeProgress.objects.filter(user=user, completed=True)
        .aggregate(total=Sum("challenge__xp_reward"))["total"]
        or 0
    )

    level = total_xp // XP_PER_LEVEL + 1
    xp_into_level = total_xp % XP_PER_LEVEL
    xp_to_next_level = XP_PER_LEVEL - xp_into_level
    level_progress_percent = round((xp_into_level / XP_PER_LEVEL) * 100, 1)

    visits_count = Visit.objects.filter(user=user).count()
    badges_count = UserBadge.objects.filter(user=user).count()
    challenges_completed_count = UserChallengeProgress.objects.filter(user=user, completed=True).count()

    total_places = Place.objects.count()
    exploration_percent = round((visits_count / total_places) * 100, 1) if total_places else 0.0

    return {
        "total_xp": total_xp,
        "level": level,
        "xp_into_level": xp_into_level,
        "xp_to_next_level": xp_to_next_level,
        "level_progress_percent": level_progress_percent,
        "visits_count": visits_count,
        "badges_count": badges_count,
        "challenges_completed_count": challenges_completed_count,
        "total_places": total_places,
        "exploration_percent": exploration_percent,
    }
