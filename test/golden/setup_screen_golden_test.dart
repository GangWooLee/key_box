@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:key_box/features/auth/domain/auth_notifier.dart';
import 'package:key_box/features/auth/domain/auth_state.dart';
import 'package:key_box/features/auth/presentation/screens/setup_screen.dart';

import '../helpers/widget_test_helpers.dart';
import 'golden_helpers.dart';

void main() {
  testWidgets('setup_screen — dark (V8 baseline)', (tester) async {
    await pumpGolden(
      tester,
      child: const SetupScreen(),
      size: GoldenSizes.authCard,
      overrides: [
        authProvider.overrideWith(
          (ref) => FakeAuthNotifier(const AuthFirstRun()),
        ),
      ],
    );
    await tester.pump(const Duration(milliseconds: 300));

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/setup_screen.png'),
    );
  });
}
