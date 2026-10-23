import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bashir_agro_app_2/main.dart';

void main() {
  testWidgets('App smoke test - renders login screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: BashirAgroApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Verify brand title is shown
    expect(find.text('আমাদের খামার'), findsOneWidget);
    expect(find.text('লগইন'), findsOneWidget);
  });
}
