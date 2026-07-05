import 'package:flutter/material.dart';

import '../../models/gamification.dart';
import '../../services/gamification_service.dart';

class ChallengesScreen extends StatefulWidget {
  const ChallengesScreen({super.key});

  @override
  State<ChallengesScreen> createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends State<ChallengesScreen> {
  final _gamificationService = GamificationService.instance;

  List<Challenge> _challenges = [];
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
      final challenges = await _gamificationService.getChallenges();
      if (!mounted) return;
      setState(() {
        _challenges = challenges;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Impossible de charger les défis.';
        _isLoading = false;
      });
    }
  }

  Color _difficultyColor(String difficulty) {
    switch (difficulty) {
      case 'facile':
        return Colors.green;
      case 'difficile':
        return Colors.redAccent;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Défis touristiques')),
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
    if (_challenges.isEmpty) {
      return const Center(child: Text('Aucun défi disponible pour le moment.'));
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: _challenges.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) => _buildChallengeCard(_challenges[index]),
      ),
    );
  }

  Widget _buildChallengeCard(Challenge challenge) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  challenge.completed ? Icons.check_circle : Icons.flag_outlined,
                  color: challenge.completed ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    challenge.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Chip(
                  label: Text(challenge.difficultyLabel, style: const TextStyle(fontSize: 11, color: Colors.white)),
                  backgroundColor: _difficultyColor(challenge.difficulty),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ),
            if (challenge.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(challenge.description, style: const TextStyle(color: Colors.grey)),
            ],
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: challenge.progressPercent / 100,
                minHeight: 8,
                backgroundColor: Colors.grey.shade200,
                color: challenge.completed ? Colors.green : Colors.teal,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${challenge.currentCount}/${challenge.targetCount}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                Row(
                  children: [
                    const Icon(Icons.bolt, size: 14, color: Colors.amber),
                    Text(' +${challenge.xpReward} XP', style: const TextStyle(fontSize: 12)),
                    if (challenge.badge != null) ...[
                      const SizedBox(width: 10),
                      const Icon(Icons.emoji_events_outlined, size: 14, color: Colors.deepPurple),
                      const SizedBox(width: 2),
                      Text(challenge.badge!.name, style: const TextStyle(fontSize: 12)),
                    ],
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
