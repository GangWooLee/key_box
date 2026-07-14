@Tags(['golden'])
library;

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:key_box/core/database/database.dart';
import 'package:key_box/features/auth/domain/auth_notifier.dart';
import 'package:key_box/features/auth/domain/auth_state.dart';
import 'package:key_box/features/secrets/domain/secrets_providers.dart';
import 'package:key_box/features/secrets/presentation/screens/dashboard_screen.dart';

import '../helpers/widget_test_helpers.dart';
import 'golden_helpers.dart';

void main() {
  setUp(() {
    suppressDriftWarning();
    SharedPreferences.setMockInitialValues({});
  });

  // Shared fixture + overrides for both V9 surface variants.
  Future<void> pumpDashboard(
    WidgetTester tester, {
    required GoldenSurface surface,
  }) async {
    final secrets = [
      makeTestSecret(
        id: 1,
        name: 'GitHub API Key',
        secretType: 'api_key',
        serviceName: 'GitHub',
        environment: 'production',
      ),
      makeTestSecret(
        id: 2,
        name: 'AWS Access Token',
        secretType: 'token',
        serviceName: 'AWS',
        environment: 'staging',
      ),
      makeTestSecret(
        id: 3,
        name: 'Database Password',
        secretType: 'password',
        serviceName: 'Postgres',
        environment: 'development',
      ),
      makeTestSecret(
        id: 4,
        name: 'TLS Certificate',
        secretType: 'certificate',
        serviceName: 'Cloudflare',
      ),
    ];
    final folders = [
      makeTestFolder(id: 1, name: 'Personal', secretsCount: 3),
      makeTestFolder(id: 2, name: 'Work', secretsCount: 1),
    ];

    await pumpGolden(
      tester,
      child: const Scaffold(body: DashboardScreen()),
      size: GoldenSizes.desktop,
      surface: surface,
      overrides: [
        authProvider.overrideWith(
          (ref) => FakeAuthNotifier(
            AuthUnlocked(masterEncryptionKey: Uint8List(32), vaultId: 1),
          ),
        ),
        showCommandPaletteProvider.overrideWith((ref) => false),
        // Empty detail panel — avoids the DB-backed secretDetailProvider fetch.
        selectedSecretIdProvider.overrideWith((ref) => null),
        selectedCategoryProvider.overrideWith((ref) => SecretCategory.all),
        selectedFolderIdProvider.overrideWith((ref) => null),
        filteredSecretsProvider.overrideWith((ref) => secrets),
        categoryCountsProvider.overrideWith(
          (ref) => const {
            SecretCategory.all: 4,
            SecretCategory.apiKey: 1,
            SecretCategory.token: 1,
            SecretCategory.password: 1,
            SecretCategory.certificate: 1,
          },
        ),
        rootFoldersProvider.overrideWith((ref) => Stream.value(folders)),
        // Each folder node watches folderChildrenProvider, which normally hits
        // a drift stream. Override with plain (leaf) streams so no drift stream
        // cleanup Timer lingers into teardown (`A Timer is still pending`).
        folderChildrenProvider(
          1,
        ).overrideWith((ref) => Stream.value(const <Folder>[])),
        folderChildrenProvider(
          2,
        ).overrideWith((ref) => Stream.value(const <Folder>[])),
        clipboardServiceProvider.overrideWithValue(MockClipboardService()),
        sidebarCollapsedProvider.overrideWith((ref) => false),
      ],
    );
    // Drain microtasks (Stream.value emission) + settle any brief transitions.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
  }

  testWidgets('dashboard_screen — V9 Terminal (dark)', (tester) async {
    await pumpDashboard(tester, surface: GoldenSurface.terminal);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/dashboard_screen.png'),
    );
  });

  testWidgets('dashboard_screen — V9 Bench (light)', (tester) async {
    await pumpDashboard(tester, surface: GoldenSurface.bench);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/dashboard_screen_bench.png'),
    );
  });
}
