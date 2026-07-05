import 'category.dart';

class AppBadge {
  final String id;
  final String name;
  final String description;
  final String icon;
  final String colorHex;

  AppBadge({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.colorHex,
  });

  factory AppBadge.fromJson(Map<String, dynamic> json) {
    return AppBadge(
      id: json['id'].toString(),
      name: json['name'] as String,
      description: (json['description'] as String?) ?? '',
      icon: (json['icon'] as String?) ?? '',
      colorHex: (json['color_hex'] as String?) ?? '',
    );
  }
}

class UserBadge {
  final String id;
  final AppBadge badge;
  final DateTime earnedAt;

  UserBadge({required this.id, required this.badge, required this.earnedAt});

  factory UserBadge.fromJson(Map<String, dynamic> json) {
    return UserBadge(
      id: json['id'].toString(),
      badge: AppBadge.fromJson(json['badge'] as Map<String, dynamic>),
      earnedAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class Challenge {
  final String id;
  final String title;
  final String description;
  final String difficulty;
  final int xpReward;
  final String sourceType;
  final Category? targetCategory;
  final String targetEventType;
  final int targetCount;
  final AppBadge? badge;
  final int currentCount;
  final bool completed;
  final double progressPercent;

  Challenge({
    required this.id,
    required this.title,
    required this.description,
    required this.difficulty,
    required this.xpReward,
    required this.sourceType,
    required this.targetCategory,
    required this.targetEventType,
    required this.targetCount,
    required this.badge,
    required this.currentCount,
    required this.completed,
    required this.progressPercent,
  });

  factory Challenge.fromJson(Map<String, dynamic> json) {
    return Challenge(
      id: json['id'] as String,
      title: json['title'] as String,
      description: (json['description'] as String?) ?? '',
      difficulty: (json['difficulty'] as String?) ?? 'moyen',
      xpReward: (json['xp_reward'] as int?) ?? 0,
      sourceType: json['source_type'] as String,
      targetCategory: json['target_category'] == null
          ? null
          : Category.fromJson(json['target_category'] as Map<String, dynamic>),
      targetEventType: (json['target_event_type'] as String?) ?? '',
      targetCount: (json['target_count'] as int?) ?? 1,
      badge: json['badge'] == null ? null : AppBadge.fromJson(json['badge'] as Map<String, dynamic>),
      currentCount: (json['current_count'] as int?) ?? 0,
      completed: (json['completed'] as bool?) ?? false,
      progressPercent: double.parse((json['progress_percent'] ?? 0).toString()),
    );
  }

  static const Map<String, String> difficultyLabels = {
    'facile': 'Facile',
    'moyen': 'Moyen',
    'difficile': 'Difficile',
  };

  String get difficultyLabel => difficultyLabels[difficulty] ?? difficulty;
}

class Visit {
  final String id;
  final String placeId;
  final String placeName;
  final DateTime createdAt;

  Visit({
    required this.id,
    required this.placeId,
    required this.placeName,
    required this.createdAt,
  });

  factory Visit.fromJson(Map<String, dynamic> json) {
    return Visit(
      id: json['id'].toString(),
      placeId: json['place'].toString(),
      placeName: (json['place_name'] as String?) ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class ProfileStats {
  final int totalXp;
  final int level;
  final int xpIntoLevel;
  final int xpToNextLevel;
  final double levelProgressPercent;
  final int visitsCount;
  final int badgesCount;
  final int challengesCompletedCount;
  final int totalPlaces;
  final double explorationPercent;

  ProfileStats({
    required this.totalXp,
    required this.level,
    required this.xpIntoLevel,
    required this.xpToNextLevel,
    required this.levelProgressPercent,
    required this.visitsCount,
    required this.badgesCount,
    required this.challengesCompletedCount,
    required this.totalPlaces,
    required this.explorationPercent,
  });

  factory ProfileStats.fromJson(Map<String, dynamic> json) {
    return ProfileStats(
      totalXp: json['total_xp'] as int,
      level: json['level'] as int,
      xpIntoLevel: json['xp_into_level'] as int,
      xpToNextLevel: json['xp_to_next_level'] as int,
      levelProgressPercent: double.parse(json['level_progress_percent'].toString()),
      visitsCount: json['visits_count'] as int,
      badgesCount: json['badges_count'] as int,
      challengesCompletedCount: json['challenges_completed_count'] as int,
      totalPlaces: json['total_places'] as int,
      explorationPercent: double.parse(json['exploration_percent'].toString()),
    );
  }
}
