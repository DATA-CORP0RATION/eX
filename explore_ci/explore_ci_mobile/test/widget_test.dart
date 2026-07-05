import 'package:flutter_test/flutter_test.dart';
import 'package:explore_ci_mobile/main.dart';

void main() {
  testWidgets('L\'app démarre et affiche l\'écran de démarrage sans crash', (tester) async {
    await tester.pumpWidget(const ExploreCIApp());

    // Le splash screen doit s'afficher immédiatement (avant redirection réseau).
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
