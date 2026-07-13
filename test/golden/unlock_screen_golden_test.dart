@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:key_box/features/auth/domain/auth_notifier.dart';
import 'package:key_box/features/auth/domain/auth_state.dart';
import 'package:key_box/features/auth/presentation/screens/unlock_screen.dart';

import '../helpers/widget_test_helpers.dart';
import 'golden_helpers.dart';

void main() {
  testWidgets('unlock_screen — V9 Slab (sealed surface)', (tester) async {
    await pumpGolden(
      tester,
      child: const UnlockScreen(),
      size: GoldenSizes.authCard,
      surface: GoldenSurface.sealed,
      overrides: [
        authProvider.overrideWith(
          (ref) => FakeAuthNotifier(const AuthLocked()),
        ),
      ],
    );
    // Idle screen — no infinite animation. Advance a couple frames so the
    // autofocused field and any entrance transitions settle.
    await tester.pump(const Duration(milliseconds: 300));

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/unlock_screen.png'),
    );
  });
}
