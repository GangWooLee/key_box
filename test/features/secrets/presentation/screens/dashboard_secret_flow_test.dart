import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:key_box/core/database/database.dart';
import 'package:key_box/core/encryption/key_derivation_service.dart';
import 'package:key_box/core/encryption/master_key_service.dart';
import 'package:key_box/core/theme/app_theme.dart';
import 'package:key_box/core/utils/result.dart';
import 'package:key_box/features/auth/domain/auth_notifier.dart';
import 'package:key_box/features/auth/domain/auth_state.dart';
import 'package:key_box/features/secrets/domain/secrets_providers.dart';
import 'package:key_box/features/secrets/presentation/screens/dashboard_screen.dart';

import '../../../../helpers/widget_test_helpers.dart';

/// Real-seam regression guard for "add key inside a folder lands in general".
///
/// The sibling `sheet_modal_test.dart` has a green test named "create lands the
/// secret in the SELECTED folder (Work), not general" — but it *hardcodes*
/// `selectedFolderIdProvider.overrideWith((ref) => workId)` and pumps only the
/// modal behind a bare button. It therefore validates the modal in isolation and
/// skips the one seam where the real bug lived: the user taps a folder row
/// (`FolderTree._onSelect` sets the provider) and the modal, opened across the
/// `showGeneralDialog` navigator boundary, must read that same value.
///
/// This test pumps the whole [DashboardScreen] against a real in-memory DB and
/// drives the actual loop — tap the real 'Work' row → Add Secret → Save — then
/// asserts placement (Work, not general) and that the sidebar count's source of
/// truth (`folderSecretCountsProvider` → `watchCountsByFolder`) follows. It is
/// the guard the folder-selection fix (`2317cd7`) never had.
void main() {
  // Dashboard needs a wider surface (200 sidebar + 340 detail + table).
  const testSurfaceSize = Size(1440, 900);

  late AppDatabase db;
  late int vaultId;
  late int generalId;
  late int workId;
  late Uint8List mek;

  setUp(() async {
    suppressDriftWarning();
    // autoLockProvider / theme toggle read SharedPreferences on mount.
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase.forTesting(NativeDatabase.memory());
    final vault = await db.vaultDao.create(name: 'Test');
    vaultId = vault.id;
    final kds = KeyDerivationService();
    final mks = MasterKeyService();
    final salt = kds.generateSalt();
    final pdk = kds.deriveKey(password: 'testpassword12', salt: salt);
    mek = mks.generateMasterKey();
    await db.vaultConfigDao.create(
      vaultId: vaultId,
      masterKeySalt: salt,
      encryptedMasterKey: mks.wrap(masterKey: mek, wrappingKey: pdk),
    );
    // general is position 0 (folders.first — the fallback bucket); Work is later.
    final general = await db.folderDao.create(
      vaultId: vaultId,
      name: 'General',
    );
    final work = await db.folderDao.create(
      vaultId: vaultId,
      name: 'Work',
      position: 1,
    );
    generalId = general.id;
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
    // Avoid the real clipboard plugin (MissingPluginException in tests).
    clipboardServiceProvider.overrideWithValue(MockClipboardService()),
  ];

  /// Seeds a real encrypted secret into [folderId] via ops (real link + count).
  Future<Secret> seedSecret(String name, String value, int folderId) async {
    final container = ProviderContainer(overrides: overrides());
    addTearDown(container.dispose);
    final result = await container
        .read(secretOpsProvider)
        .create(name: name, value: value, folderId: folderId);
    return (result as Success<Secret>).data;
  }

  testWidgets(
    'tap Work folder → Add Secret lands in Work (not general) and the count follows',
    (tester) async {
      // A pre-existing General member proves its count is untouched by the add.
      await seedSecret('Existing', 'v0', generalId);

      await tester.binding.setSurfaceSize(testSurfaceSize);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ProviderScope(
          overrides: overrides(),
          child: MaterialApp(
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: ThemeMode.dark,
            home: const Scaffold(body: DashboardScreen()),
          ),
        ),
      );

      // Let the drift streams (rootFolders / counts / filtered) emit into the UI.
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 200));
      });
      await tester.pumpAndSettle();

      // The real sidebar folder tree shows both folders.
      expect(find.text('Work'), findsOneWidget);
      expect(find.text('General'), findsOneWidget);

      // THE SEAM: tap the real 'Work' row → FolderTree._onSelect sets
      // selectedFolderIdProvider = workId. No override — unlike the modal test.
      await tester.tap(find.text('Work'));
      await tester.pump();

      // Open the add-key modal via the always-present bottom-bar button.
      await tester.tap(find.text('Add Secret'));
      await tester.pumpAndSettle(); // finite scale/fade dialog transition

      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), 'GitHub Token'); // Title
      await tester.enterText(fields.at(1), 'ghp_realvalue'); // Value
      await tester.pump();
      await tester.tap(find.text('Save'));
      await tester.pump(); // Save spinner appears — never pumpAndSettle here.

      // Drain the real create+link on the event loop and read the source of truth.
      List<Secret> inWork = const [];
      List<Secret> inGeneral = const [];
      Map<int, int> counts = const {};
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 300));
        inWork = await db.folderSecretsDao.watchSecretsByFolderId(workId).first;
        inGeneral = await db.folderSecretsDao
            .watchSecretsByFolderId(generalId)
            .first;
        counts = await db.folderSecretsDao.watchCountsByFolder().first;
      });

      // (1) Placement — the new secret is a Work member, NOT general.
      expect(
        inWork.map((s) => s.name),
        contains('GitHub Token'),
        reason: 'new secret must land in the selected folder (Work)',
      );
      expect(
        inGeneral.map((s) => s.name),
        isNot(contains('GitHub Token')),
        reason: 'must not fall back to general',
      );

      // (2) Count — the sidebar "집계" source: Work +1, General held at its
      // pre-existing 1 (no cross-contamination).
      expect(counts[workId], 1, reason: 'Work count reflects the new member');
      expect(
        counts[generalId],
        1,
        reason: 'General count unaffected by adding to Work',
      );

      // Teardown hygiene: unmount the tree INSIDE the test body. Disposing
      // ProviderScope cancels the real drift watch-streams, and drift's
      // StreamQueryStore.markAsClosed schedules zero-duration cleanup timers —
      // if the framework's post-test unmount creates them instead, they trip
      // `!timersPending` and leave db.close() hanging. The pump needs an
      // explicit duration: a duration-less pump() does NOT advance the fake
      // clock, so Timer.run(zero) would stay pending forever.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 1));
    },
  );
}
