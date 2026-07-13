@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:key_box/features/auth/domain/auth_notifier.dart';
import 'package:key_box/features/auth/domain/auth_state.dart';
import 'package:key_box/features/onboarding/presentation/screens/onboarding_screen.dart';

import '../helpers/widget_test_helpers.dart';
import 'golden_helpers.dart';

void main() {
  setUp(suppressDriftWarning);

  // Step 1 (welcome). The card renders identically regardless of auth state;
  // AuthLocked makes `_loadDefaultFolder` short-circuit so no DB is touched.
  testWidgets('onboarding_screen — step 1, dark (V8 baseline)', (tester) async {
    await pumpGolden(
      tester,
      child: const OnboardingScreen(),
      size: const Size(520, 640),
      overrides: [
        authProvider.overrideWith(
          (ref) => FakeAuthNotifier(const AuthLocked()),
        ),
      ],
    );
    await tester.pump(const Duration(milliseconds: 300));

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/onboarding_screen.png'),
    );
  });
}
