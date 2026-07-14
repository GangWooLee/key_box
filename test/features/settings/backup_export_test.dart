import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:key_box/core/backup/last_backup_store.dart';
import 'package:key_box/core/backup/vault_recovery_service.dart';
import 'package:key_box/core/database/database.dart';
import 'package:key_box/core/encryption/key_derivation_service.dart';
import 'package:key_box/core/encryption/key_hierarchy_service.dart';
import 'package:key_box/core/encryption/master_key_service.dart';
import 'package:key_box/core/encryption/secret_encryption_service.dart';
import 'package:key_box/features/auth/domain/auth_notifier.dart';
import 'package:key_box/features/settings/domain/backup_export.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LastBackupStore', () {
    test('reads null when the vault has never been exported', () async {
      SharedPreferences.setMockInitialValues({});
      final store = LastBackupStore(await SharedPreferences.getInstance());
      expect(store.read(), isNull);
    });

    test('records and reads back the last backup instant', () async {
      SharedPreferences.setMockInitialValues({});
      final store = LastBackupStore(await SharedPreferences.getInstance());
      final at = DateTime.fromMillisecondsSinceEpoch(1720000000000);
      await store.record(at);
      expect(store.read(), at);
    });
  });

  group('vaultArchiveBuilder (export gather)', () {
    final enc = SecretEncryptionService();
    final kdf = KeyDerivationService();
    final kh = KeyHierarchyService();
    final mks = MasterKeyService();
    final recovery = VaultRecoveryService();

    // A source archive to seed a real vault via restoreFromBackup.
    String seedArchive(String password) {
      final salt = kdf.generateSalt();
      final pdk = kdf.deriveKey(password: password, salt: salt);
      final kek = kh.deriveKek(pdk);
      final mek = mks.generateMasterKey();
      final wrappedMek = mks.wrap(masterKey: mek, wrappingKey: kek);
      Secret stored(int id, String name, String value) {
        final e = enc.encrypt(
          value: value,
          key: mek,
          aad: secretAad(secretId: id, recordVersion: 1),
        );
        final now = DateTime.utc(2026, 1, 1);
        return Secret(
          id: id,
          vaultId: 1,
          folderId: 1,
          name: name,
          encryptedValue: e.encryptedValue,
          encryptedValueIv: e.iv,
          encryptedValueAuthTag: e.authTag,
          secretType: 'api_key',
          serviceName: null,
          environment: null,
          notes: null,
          tags: null,
          recordVersion: 1,
          accessCount: 0,
          lastAccessedAt: null,
          createdAt: now,
          updatedAt: now,
        );
      }

      return recovery.buildArchive(
        salt: salt,
        wrappedMek: wrappedMek,
        secrets: [stored(1, 'GitHub', 'ghp_1'), stored(2, 'AWS', 'aws_2')],
        mek: mek,
      )!;
    }

    test(
      'exports the live vault to an archive that restores identically',
      () async {
        const password = 'vault-password-123';
        final db = AppDatabase.forTesting(NativeDatabase.memory());
        addTearDown(db.close);
        final notifier = AuthNotifier(db);

        // Seed a real vault with two secrets, unlocked.
        await notifier.restoreFromBackup(
          archive: seedArchive(password),
          password: password,
        );

        final container = ProviderContainer(
          overrides: [
            authProvider.overrideWith((ref) => notifier),
            databaseHolderProvider.overrideWith((ref) => db),
          ],
        );
        addTearDown(container.dispose);

        // Export the live vault.
        final archive = await container.read(vaultArchiveBuilderProvider)();
        expect(archive, isNotNull);

        // The exported archive restores to the same two secrets under the same
        // password (full export ↔ restore loop through the real DB).
        final dest = mks.generateMasterKey();
        final restored = recovery.restore(
          archive: archive!,
          password: password,
          destinationMek: dest,
        );
        expect(restored, isNotNull);
        expect(restored!.map((r) => r.name).toSet(), {'GitHub', 'AWS'});
        expect(restored.firstWhere((r) => r.name == 'GitHub').value, 'ghp_1');
        expect(restored.firstWhere((r) => r.name == 'AWS').value, 'aws_2');
      },
    );

    test('returns null when the vault is locked', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final notifier = AuthNotifier(db); // never unlocked → AuthInitial

      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith((ref) => notifier),
          databaseHolderProvider.overrideWith((ref) => db),
        ],
      );
      addTearDown(container.dispose);

      expect(await container.read(vaultArchiveBuilderProvider)(), isNull);
    });
  });
}
