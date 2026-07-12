import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:key_box/app.dart';

void main() {
  testWidgets('KeyBoxApp renders without error', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: KeyBoxApp()));
    // Just pump once — don't settle because auth init might not complete in test
    await tester.pump();

    // App should render something
    expect(find.byType(KeyBoxApp), findsOneWidget);
  });
}
