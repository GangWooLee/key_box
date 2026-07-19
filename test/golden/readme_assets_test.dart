@Tags(['golden'])
library;

import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:key_box/core/database/database.dart';
import 'package:key_box/core/encryption/key_derivation_service.dart';
import 'package:key_box/core/encryption/master_key_service.dart';
import 'package:key_box/core/utils/result.dart';
import 'package:key_box/features/auth/domain/auth_notifier.dart';
import 'package:key_box/features/auth/domain/auth_state.dart';
import 'package:key_box/features/secrets/domain/secrets_providers.dart';
import 'package:key_box/features/secrets/presentation/screens/dashboard_screen.dart';

import '../helpers/widget_test_helpers.dart';
import 'golden_helpers.dart';

/// README asset generator — renders the real [DashboardScreen] against a real
/// in-memory DB seeded with plausible DEMO secrets (values are dummies) and
/// writes the PNGs GitHub's README embeds. Regenerate after UI changes with:
///
///   flutter test --update-goldens --tags golden test/golden/readme_assets_test.dart
///
/// Same rationale as the design goldens: real fonts, real theme tokens, the
/// same Flutter renderer the app ships with — deterministic and reproducible,
/// unlike hand-taken screenshots.
void main() {
  late AppDatabase db;
  late int vaultId;
  late Uint8List mek;
  late int workId;
  late int personalId;

  setUp(() async {
    suppressDriftWarning();
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase.forTesting(NativeDatabase.memory());
    final vault = await db.vaultDao.create(name: 'Demo');
    vaultId = vault.id;
    final kds = KeyDerivationService();
    final mks = MasterKeyService();
    final salt = kds.generateSalt();
    final pdk = kds.deriveKey(password: 'readme-demo-pass', salt: salt);
    mek = mks.generateMasterKey();
    await db.vaultConfigDao.create(
      vaultId: vaultId,
      masterKeySalt: salt,
      encryptedMasterKey: mks.wrap(masterKey: mek, wrappingKey: pdk),
    );
    await db.folderDao.create(vaultId: vaultId, name: 'General');
    final personal = await db.folderDao.create(
      vaultId: vaultId,
      name: 'Personal',
      position: 1,
    );
    final work = await db.folderDao.create(
      vaultId: vaultId,
      name: 'Work',
      position: 2,
    );
    personalId = personal.id;
    workId = work.id;
  });

  tearDown(() async {
    await db.close();
  });

  List<Override> overrides() => [
    databaseProvider.overrideWithValue(db),
    authProvider.overrideWith(
      (ref) => FakeAuthNotifier(
        AuthUnlocked(masterEncryptionKey: mek, vaultId: vaultId),
      ),
    ),
  ];

  /// Seeds one really-encrypted demo secret through the production ops path.
  Future<void> seed(
    String name,
    String value,
    int folderId, {
    String type = 'api_key',
    String? service,
    String? env,
  }) async {
    final container = ProviderContainer(overrides: overrides());
    addTearDown(container.dispose);
    final result = await container
        .read(secretOpsProvider)
        .create(
          name: name,
          value: value,
          folderId: folderId,
          secretType: type,
          serviceName: service,
          environment: env,
        );
    expect(result, isA<Success<Secret>>());
  }

  Future<void> seedDemoVault() async {
    await seed(
      'Stripe Secret Key',
      // Deliberately NOT provider-shaped (sk_live_/ghp_/sk-proj- trip GitHub
      // push protection); these values never render in the goldens anyway.
      'sk_demo_51KeyBox0000000000000000',
      workId,
      service: 'Stripe',
      env: 'production',
    );
    await seed(
      'GitHub Personal Token',
      'gh-demo-token-000000000000000000000000',
      workId,
      type: 'token',
      service: 'GitHub',
    );
    await seed(
      'AWS Access Key',
      'AKIAIOSFODNN7DEMO000',
      workId,
      service: 'AWS',
      env: 'production',
    );
    await seed(
      'Sentry DSN',
      'https://demo0000@o00000.ingest.sentry.io/4500000',
      workId,
      service: 'Sentry',
      env: 'production',
    );
    await seed(
      'OpenAI API Key',
      'sk-demo-0000000000000000000000000000',
      personalId,
      service: 'OpenAI',
      env: 'development',
    );
    await seed(
      'Postgres Password',
      'demo-pg-password-2026',
      personalId,
      type: 'password',
      service: 'Railway',
      env: 'staging',
    );
  }

  /// Unmounts the tree and elapses the fake clock so drift's zero-duration
  /// stream-cleanup timers fire in-zone (else `!timersPending` + db.close hang).
  Future<void> drainDriftTimers(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  }

  testWidgets('hero — dark dashboard with demo secrets', (tester) async {
    await seedDemoVault();
    await pumpGolden(
      tester,
      child: const DashboardScreen(),
      size: GoldenSizes.desktop,
      overrides: overrides(),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 200)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('AWS Access Key'));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(DashboardScreen),
      matchesGoldenFile('../../docs/assets/readme/hero-dark.png'),
    );
    await drainDriftTimers(tester);
  });

  testWidgets('command palette — fuzzy search over the vault', (tester) async {
    await seedDemoVault();
    await pumpGolden(
      tester,
      child: const DashboardScreen(),
      size: GoldenSizes.desktop,
      overrides: overrides(),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 200)),
    );
    await tester.pumpAndSettle();

    // The sidebar search box opens the command palette (⌘ is an icon, so the
    // visible text node is 'K — search…').
    await tester.tap(find.textContaining('search…'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'key');
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 150)),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(DashboardScreen),
      matchesGoldenFile('../../docs/assets/readme/palette-search.png'),
    );
    await drainDriftTimers(tester);
  });

  testWidgets('reveal — decrypted value with clipboard countdown', (
    tester,
  ) async {
    await seedDemoVault();
    await pumpGolden(
      tester,
      child: const DashboardScreen(),
      size: GoldenSizes.desktop,
      overrides: overrides(),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 200)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('AWS Access Key'));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pumpAndSettle();

    // Reveal decrypts under the real MEK; Copy starts the 30s countdown ring.
    await tester.tap(find.text('Reveal'));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 150)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Copy'));
    await tester.pump(const Duration(seconds: 2));

    await expectLater(
      find.byType(DashboardScreen),
      matchesGoldenFile('../../docs/assets/readme/reveal-countdown.png'),
    );
    // The clipboard wipe timer (30s) is still pending — cancel it by
    // unmounting (clipboardServiceProvider disposes the service) then drain.
    await drainDriftTimers(tester);
    await tester.pump(const Duration(seconds: 31));
  });
}
