import 'package:flutter/material.dart';

import '../../models/gamification.dart';
import '../../services/gamification_service.dart';

class BadgesScreen extends StatefulWidget {
  const BadgesScreen({super.key});

  @override
  State<BadgesScreen> createState() => _BadgesScreenState();
}

class _BadgesScreenState extends State<BadgesScreen> {
  final _gamificationService = GamificationService.instance;

  List<AppBadge> _allBadges = [];
  Set<String> _earnedBadgeIds = {};
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final results = await Future.wait([
        _gamificationService.getAllBadges(),
        _gamificationService.getMyBadges(),
      ]);
      if (!mounted) return;
      final allBadges = results[0] as List<AppBadge>;
      final myBadges = results[1] as List<UserBadge>;
      setState(() {
        _allBadges = allBadges;
        _earnedBadgeIds = myBadges.map((b) => b.badge.id).toSet();
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Impossible de charger les badges.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mes badges')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)));
    }
    if (_allBadges.isEmpty) {
      return const Center(child: Text('Aucun badge disponible pour le moment.'));
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.8,
        ),
        itemCount: _allBadges.length,
        itemBuilder: (context, index) {
          final badge = _allBadges[index];
          final earned = _earnedBadgeIds.contains(badge.id);
          return _buildBadgeTile(badge, earned);
        },
      ),
    );
  }

  Widget _buildBadgeTile(AppBadge badge, bool earned) {
    return Opacity(
      opacity: earned ? 1 : 0.35,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: earned ? Colors.amber.shade100 : Colors.grey.shade200,
            child: Icon(
              earned ? Icons.emoji_events : Icons.lock_outline,
              color: earned ? Colors.amber.shade800 : Colors.grey,
              size: 26,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            badge.name,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
