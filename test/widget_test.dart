import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:key_box/app.dart';

void main() {
  testWidgets('KeyBoxApp renders without error', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: KeyBoxApp()),
    );
    await tester.pumpAndSettle();

    // Verify the app renders (placeholder dashboard screen)
    expect(find.text('Dashboard'), findsOneWidget);
  });
}
