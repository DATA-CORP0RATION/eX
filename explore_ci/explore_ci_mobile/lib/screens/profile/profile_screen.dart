import 'package:flutter/material.dart' hide Badge;
import 'package:flutter/material.dart' as material show Badge;

import '../../models/gamification.dart';
import '../../models/user.dart';
import '../../services/auth_service.dart';
import '../../services/gamification_service.dart';
import '../auth/login_screen.dart';
import '../gamification/badges_screen.dart';
import '../gamification/challenges_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _authService = AuthService.instance;
  final _gamificationService = GamificationService.instance;

  AppUser? _user;
  ProfileStats? _stats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final user = await _authService.fetchCurrentUser();
      if (!mounted) return;
      setState(() => _user = user);

      // Les stats de gamification exigent d'être connecté ; on les charge
      // séparément pour ne pas bloquer l'affichage du profil de base si elles échouent.
      try {
        final stats = await _gamificationService.getProfileStats();
        if (!mounted) return;
        setState(() => _stats = stats);
      } catch (_) {
        // Pas grave : on affiche simplement le profil sans la section stats.
      }
    } catch (_) {
      // Utilisateur non connecté ou erreur réseau : on garde _user à null.
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    await _authService.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mon profil')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  const SizedBox(height: 16),
                  const CircleAvatar(radius: 40, child: Icon(Icons.person, size: 40)),
                  const SizedBox(height: 16),
                  Text(
                    _user?.fullName.isNotEmpty == true ? _user!.fullName : 'Utilisateur ExploreCI',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _user?.email ?? '',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  if (_stats != null) _buildStatsSection(_stats!) else _buildLoginPrompt(),
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout, color: Colors.red),
                    label: const Text('Se déconnecter', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildLoginPrompt() {
    if (_user != null) {
      // Connecté mais les stats n'ont pas pu charger (backend indisponible,
      // migrations manquantes...) : on l'indique clairement, et on garde
      // quand même l'accès aux défis/badges (ces écrans gèrent leurs propres erreurs).
      return Column(
        children: [
          Card(
            color: Colors.orange.shade50,
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Impossible de charger votre progression pour le moment. '
                'Vérifiez que le serveur est bien à jour (migrations events/community/gamification).',
                style: TextStyle(color: Colors.orange),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildQuickAccessButtons(),
        ],
      );
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text('Connectez-vous pour voir votre progression, vos badges et vos défis.'),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              ),
              child: const Text('Se connecter'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAccessButtons({int? badgesCount}) {
    final badgesIcon = badgesCount != null
        ? material.Badge(
            label: Text('$badgesCount'),
            child: const Icon(Icons.emoji_events_outlined),
          )
        : const Icon(Icons.emoji_events_outlined);

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ChallengesScreen()),
            ),
            icon: const Icon(Icons.flag_outlined),
            label: const Text('Voir les défis'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const BadgesScreen()),
            ),
            icon: badgesIcon,
            label: const Text('Mes badges'),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsSection(ProfileStats stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.military_tech, color: Colors.amber),
                        const SizedBox(width: 8),
                        Text('Niveau ${stats.level}', style: Theme.of(context).textTheme.titleMedium),
                      ],
                    ),
                    Text('${stats.totalXp} XP', style: const TextStyle(color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: stats.levelProgressPercent / 100,
                    minHeight: 8,
                    backgroundColor: Colors.grey.shade200,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${stats.xpToNextLevel} XP avant le niveau ${stats.level + 1}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatTile(
                icon: Icons.place_outlined,
                label: 'Lieux visités',
                value: '${stats.visitsCount}',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatTile(
                icon: Icons.flag_outlined,
                label: 'Défis relevés',
                value: '${stats.challengesCompletedCount}',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Exploration de la Côte d\'Ivoire', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: stats.explorationPercent / 100,
                    minHeight: 8,
                    backgroundColor: Colors.grey.shade200,
                    color: Colors.teal,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${stats.explorationPercent.toStringAsFixed(0)}% (${stats.visitsCount}/${stats.totalPlaces} lieux)',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        _buildQuickAccessButtons(badgesCount: stats.badgesCount),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatTile({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        child: Column(
          children: [
            Icon(icon, color: Colors.teal),
            const SizedBox(height: 6),
            Text(value, style: Theme.of(context).textTheme.titleLarge),
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
