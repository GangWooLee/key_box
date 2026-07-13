@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:key_box/features/auth/domain/auth_notifier.dart';
import 'package:key_box/features/auth/domain/auth_state.dart';
import 'package:key_box/features/auth/presentation/screens/vault_error_screen.dart';

import '../helpers/widget_test_helpers.dart';
import 'golden_helpers.dart';

void main() {
  setUp(suppressDriftWarning);

  // One representative reason — sidecarCorrupted (the data-recovery framing).
  testWidgets('vault_error_screen — sidecarCorrupted, V9 Slab (sealed)', (
    tester,
  ) async {
    await pumpGolden(
      tester,
      child: const VaultErrorScreen(),
      size: GoldenSizes.authCard,
      surface: GoldenSurface.sealed,
      overrides: [
        authProvider.overrideWith(
          (ref) => FakeAuthNotifier(
            const AuthVaultError(reason: VaultErrorReason.sidecarCorrupted),
          ),
        ),
      ],
    );
    await tester.pump(const Duration(milliseconds: 300));

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/vault_error_screen.png'),
    );
  });
}
