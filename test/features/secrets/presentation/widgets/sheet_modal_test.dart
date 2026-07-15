import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:key_box/core/database/database.dart';
import 'package:key_box/core/encryption/key_derivation_service.dart';
import 'package:key_box/core/encryption/master_key_service.dart';
import 'package:key_box/core/theme/app_theme.dart';
import 'package:key_box/core/utils/result.dart';
import 'package:key_box/features/auth/domain/auth_notifier.dart';
import 'package:key_box/features/auth/domain/auth_state.dart';
import 'package:key_box/features/secrets/domain/secrets_providers.dart';
import 'package:key_box/features/secrets/presentation/widgets/sheet_modal.dart';

import '../../../../helpers/widget_test_helpers.dart';

void main() {
  late AppDatabase db;
  late int vaultId;
  late int generalId;
  late int workId;
  late Uint8List mek;

  setUp(() async {
    suppressDriftWarning();
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
    // general is position 0 (folders.first); Work is a later folder.
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

  Future<void> pumpModal(
    WidgetTester tester, {
    int? selectedFolderId,
    Secret? secret,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          authProvider.overrideWith(
            (ref) => FakeAuthNotifier(
              AuthUnlocked(masterEncryptionKey: mek, vaultId: vaultId),
            ),
          ),
          selectedFolderIdProvider.overrideWith((ref) => selectedFolderId),
        ],
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: Consumer(
            builder: (context, ref, _) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => showSecretSheetModal(
                    context: context,
                    ref: ref,
                    secret: secret,
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  /// Creates a real encrypted secret (via ops) so edit-mode tests have a row
  /// whose value the modal must decrypt + pre-fill.
  Future<Secret> seedSecret(String name, String value, int folderId) async {
    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        authProvider.overrideWith(
          (ref) => FakeAuthNotifier(
            AuthUnlocked(masterEncryptionKey: mek, vaultId: vaultId),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    final result = await container
        .read(secretOpsProvider)
        .create(name: name, value: value, folderId: folderId);
    return (result as Success<Secret>).data;
  }

  group('edit value pre-fill (#4)', () {
    testWidgets('edit pre-fills the decrypted value, masked by default', (
      tester,
    ) async {
      final secret = await seedSecret('GH', 'ghp_original', workId);
      final current = (await db.secretDao.getById(secret.id))!;

      await pumpModal(tester, secret: current);
      await tester.pumpAndSettle(); // post-frame decrypt + setState

      final valueField = tester.widget<TextField>(find.byType(TextField).at(1));
      expect(valueField.controller!.text, 'ghp_original');
      expect(
        valueField.obscureText,
        isTrue,
        reason: 'masked by default (reveal parity)',
      );
    });

    testWidgets('saving without changing the value does NOT rotate', (
      tester,
    ) async {
      final secret = await seedSecret('GH', 'ghp_original', workId);
      final current = (await db.secretDao.getById(secret.id))!;
      expect(current.recordVersion, 1);

      await pumpModal(tester, secret: current);
      await tester.pumpAndSettle();
      // Change only the Title, leave the pre-filled value untouched.
      await tester.enterText(find.byType(TextField).at(0), 'GH renamed');
      await tester.pump();
      await tester.tap(find.text('Save'));
      await tester.pump();

      Secret? after;
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 300));
        after = await db.secretDao.getById(secret.id);
      });
      expect(after!.name, 'GH renamed');
      expect(
        after!.recordVersion,
        1,
        reason: 'unchanged value must not bump recordVersion',
      );
    });

    testWidgets('changing the value rotates (recordVersion + 1)', (
      tester,
    ) async {
      final secret = await seedSecret('GH', 'ghp_original', workId);
      final current = (await db.secretDao.getById(secret.id))!;

      await pumpModal(tester, secret: current);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).at(1), 'ghp_rotated');
      await tester.pump();
      await tester.tap(find.text('Save'));
      await tester.pump();

      Secret? after;
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 300));
        after = await db.secretDao.getById(secret.id);
      });
      expect(after!.recordVersion, 2, reason: 'changed value rotates');
    });
  });

  testWidgets(
    'create lands the secret in the SELECTED folder (Work), not general',
    (tester) async {
      await pumpModal(tester, selectedFolderId: workId);

      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), 'GitHub Token'); // Title
      await tester.enterText(fields.at(1), 'ghp_realvalue'); // Value
      await tester.pump();
      // Save shows a CircularProgressIndicator while _saving — pumpAndSettle
      // would hang on it (무한 애니메이션 함정). Tap, then drain the real async
      // create+link on the real event loop via runAsync, and read the DB there.
      await tester.tap(find.text('Save'));
      await tester.pump();

      List<Secret> inWork = const [];
      List<Secret> inGeneral = const [];
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 300));
        inWork = await db.folderSecretsDao.watchSecretsByFolderId(workId).first;
        inGeneral = await db.folderSecretsDao
            .watchSecretsByFolderId(generalId)
            .first;
      });
      expect(inWork.map((s) => s.name), ['GitHub Token']);
      expect(inGeneral, isEmpty, reason: 'must not fall back to general');
    },
  );

  testWidgets(
    'create falls back to general when no folder is selected (category view)',
    (tester) async {
      await pumpModal(tester, selectedFolderId: null);

      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), 'Loose Key');
      await tester.enterText(fields.at(1), 'sk_loose');
      await tester.pump();
      await tester.tap(find.text('Save'));
      await tester.pump();

      List<Secret> inGeneral = const [];
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 300));
        inGeneral = await db.folderSecretsDao
            .watchSecretsByFolderId(generalId)
            .first;
      });
      expect(inGeneral.map((s) => s.name), ['Loose Key']);
    },
  );
}
