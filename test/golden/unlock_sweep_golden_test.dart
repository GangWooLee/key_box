@Tags(['golden'])
library;

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:key_box/core/database/database.dart';
import 'package:key_box/core/theme/app_theme.dart';
import 'package:key_box/features/auth/domain/auth_notifier.dart';
import 'package:key_box/features/auth/domain/auth_state.dart';
import 'package:key_box/features/auth/presentation/widgets/unlock_sweep.dart';
import 'package:key_box/features/secrets/domain/secrets_providers.dart';
import 'package:key_box/features/secrets/presentation/screens/dashboard_screen.dart';

import '../helpers/widget_test_helpers.dart';
import 'golden_helpers.dart';

/// The signature "lights come on" sweep, mid-flight over the Bench dashboard
/// (DESIGN.md §Motion). Captured at a deterministic frame: the diagonal light
/// front has washed most of the slab away, revealing the workbench beneath
/// with the bottom-right corner still sealed. First-run hero lands on Bench,
/// so this renders the dramatic dark→light reveal.
void main() {
  setUp(() {
    suppressDriftWarning();
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('unlock_sweep — mid-sweep over Bench dashboard', (tester) async {
    await loadTestFonts();
    tester.view.devicePixelRatio = 1.0;
    await tester.binding.setSurfaceSize(GoldenSizes.desktop);
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
      tester.view.resetDevicePixelRatio();
    });

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

    // Start sealed so the transition below fires the sweep like production.
    final fake = FakeAuthNotifier(const AuthLocked());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith((ref) => fake),
          showCommandPaletteProvider.overrideWith((ref) => false),
          selectedSecretIdProvider.overrideWith((ref) => null),
          selectedCategoryProvider.overrideWith((ref) => SecretCategory.all),
          selectedFolderIdProvider.overrideWith((ref) => null),
          // Folder counts are now derived — feed the sidebar the fake folders'
          // advertised numbers (Personal 3, Work 1).
          folderSecretCountsProvider.overrideWith(
            (ref) => Stream.value(const {1: 3, 2: 1}),
          ),
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
          folderChildrenProvider(
            1,
          ).overrideWith((ref) => Stream.value(const <Folder>[])),
          folderChildrenProvider(
            2,
          ).overrideWith((ref) => Stream.value(const <Folder>[])),
          clipboardServiceProvider.overrideWithValue(MockClipboardService()),
          sidebarCollapsedProvider.overrideWith((ref) => false),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          // First-run hero lands on the Bench (light) — the reveal target.
          theme: AppTheme.bench(),
          home: const Scaffold(body: DashboardScreen()),
          builder: (context, child) =>
              UnlockSweep(child: child ?? const SizedBox.shrink()),
        ),
      ),
    );

    // Open: the dashboard renders on the Bench and the slab cover drops on top.
    fake.setAuthState(
      AuthUnlocked(masterEncryptionKey: Uint8List(32), vaultId: 1),
    );
    await tester.pump(); // dashboard builds + folder streams emit; cover mounts
    // First tick sets the ticker epoch (cover fully opaque), then advance to a
    // deterministic mid-sweep frame (~46% through easeOutExpo → front ~2/3).
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pump(const Duration(milliseconds: 48));

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/unlock_sweep_mid.png'),
    );
  });
}
