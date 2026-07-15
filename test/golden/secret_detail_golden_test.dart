@Tags(['golden'])
library;

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:key_box/features/auth/domain/auth_notifier.dart';
import 'package:key_box/features/auth/domain/auth_state.dart';
import 'package:key_box/features/secrets/domain/secrets_providers.dart';
import 'package:key_box/features/secrets/presentation/widgets/secret_detail.dart';

import '../helpers/widget_test_helpers.dart';
import 'golden_helpers.dart';

void main() {
  setUp(() {
    suppressDriftWarning();
    // reveal-by-default reads SharedPreferences; keep it off (masked).
    SharedPreferences.setMockInitialValues({});
  });

  // Masked (not-yet-revealed) state. secretDetailProvider is overridden with a
  // fixed-timestamp fabricated secret so the "updated N ago" header and the
  // masked value are deterministic without touching the encrypted DB.
  testWidgets('secret_detail — V9 masked (terminal)', (tester) async {
    final secret = makeTestSecret(
      id: 1,
      name: 'Stripe Secret Key',
      secretType: 'api_key',
      serviceName: 'Stripe',
      environment: 'production',
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 1),
    );

    await pumpGolden(
      tester,
      child: const Scaffold(body: SecretDetail()),
      size: GoldenSizes.detailPanel,
      overrides: [
        authProvider.overrideWith(
          (ref) => FakeAuthNotifier(
            AuthUnlocked(masterEncryptionKey: Uint8List(32), vaultId: 1),
          ),
        ),
        selectedSecretIdProvider.overrideWith((ref) => 1),
        secretDetailProvider(1).overrideWith((ref) => secret),
      ],
    );
    // Resolves the (overridden) future + AnimatedSwitcher; the loading spinner
    // is transient so settling terminates.
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/secret_detail.png'),
    );
  });

  // Details expanded — the #3 spacing fix (header→child breathing room via
  // _CollapsibleSection) is only visible when a section is open, so capture it.
  testWidgets('secret_detail — Details expanded spacing (terminal)', (
    tester,
  ) async {
    final secret = makeTestSecret(
      id: 1,
      name: 'Stripe Secret Key',
      secretType: 'api_key',
      serviceName: 'Stripe',
      environment: 'production',
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 1),
    );

    await pumpGolden(
      tester,
      child: const Scaffold(body: SecretDetail()),
      size: GoldenSizes.detailPanel,
      overrides: [
        authProvider.overrideWith(
          (ref) => FakeAuthNotifier(
            AuthUnlocked(masterEncryptionKey: Uint8List(32), vaultId: 1),
          ),
        ),
        selectedSecretIdProvider.overrideWith((ref) => 1),
        secretDetailProvider(1).overrideWith((ref) => secret),
      ],
    );
    await tester.pumpAndSettle();
    // Expand the Details section to show the header→child spacing.
    await tester.tap(find.text('Details'));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/secret_detail_expanded.png'),
    );
  });
}
