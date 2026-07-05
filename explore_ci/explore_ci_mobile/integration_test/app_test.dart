// Test bout-en-bout ExploreCI — dev C, semaine 2.
//
// Parcours couvert (conforme section 5 de la spec) :
//   inscription -> carte -> ajout favori -> dépôt d'avis, sans crash.
//
// PRÉ-REQUIS pour exécuter ce test :
//   1. Le backend Django doit tourner en local : `python manage.py runserver`
//   2. `python manage.py seed_places` doit avoir été exécuté (lieux en base).
//   3. Lancer sur un émulateur Android (10.0.2.2 pointe vers localhost).
//
// Exécution :
//   flutter test integration_test/app_test.dart
//
// Ce test crée un nouvel utilisateur à chaque exécution (email horodaté)
// pour éviter les conflits avec la contrainte d'unicité sur `email`.

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:explore_ci_mobile/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Parcours complet : inscription -> carte -> favori -> avis', (tester) async {
    final uniqueEmail = 'e2e_${DateTime.now().millisecondsSinceEpoch}@exploreci.test';

    await tester.pumpWidget(const ExploreCIApp());
    await tester.pumpAndSettle();

    // --- 1. Aller vers l'écran d'inscription ---
    expect(find.text('Pas encore de compte ? Créer un compte'), findsOneWidget);
    await tester.tap(find.text('Pas encore de compte ? Créer un compte'));
    await tester.pumpAndSettle();

    // --- 2. Remplir le formulaire d'inscription ---
    await tester.enterText(find.widgetWithText(TextFormField, 'Prénom'), 'Test');
    await tester.enterText(find.widgetWithText(TextFormField, 'Nom'), 'E2E');
    await tester.enterText(find.widgetWithText(TextFormField, 'Email'), uniqueEmail);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Mot de passe (8 caractères min.)'),
      'MotDePasse123',
    );
    await tester.tap(find.text('Créer mon compte'));

    // Laisse le temps aux appels réseau (register + login) de répondre.
    await tester.pumpAndSettle(const Duration(seconds: 5));

    // --- 3. Vérifie l'arrivée sur l'écran d'accueil (onglet Carte) ---
    expect(find.byIcon(Icons.map), findsWidgets);

    // --- 4. Ouvrir la liste des lieux (plus simple à cibler qu'un marqueur GPS) ---
    await tester.tap(find.text('Liste'));
    await tester.pumpAndSettle(const Duration(seconds: 3));

    final firstPlaceTile = find.byType(ListTile).first;
    expect(firstPlaceTile, findsOneWidget);
    await tester.tap(firstPlaceTile);
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // --- 5. Ajouter le lieu en favori ---
    final favoriteButton = find.byIcon(Icons.favorite_border);
    expect(favoriteButton, findsOneWidget);
    await tester.tap(favoriteButton);
    await tester.pumpAndSettle(const Duration(seconds: 2));
    expect(find.byIcon(Icons.favorite), findsWidgets);

    // --- 6. Déposer un avis ---
    await tester.tap(find.text('Laisser un avis'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Superbe endroit, test automatisé E2E.');
    await tester.tap(find.text('Envoyer'));
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // --- 7. Vérifie qu'aucune exception n'a été levée pendant tout le parcours ---
    expect(tester.takeException(), isNull);
  });
}
