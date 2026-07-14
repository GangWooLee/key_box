import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:key_box/core/backup/vault_recovery_service.dart';
import 'package:key_box/core/database/database.dart';
import 'package:key_box/core/encryption/key_derivation_service.dart';
import 'package:key_box/core/encryption/key_hierarchy_service.dart';
import 'package:key_box/core/encryption/master_key_service.dart';
import 'package:key_box/core/encryption/secret_encryption_service.dart';
import 'package:key_box/features/auth/domain/auth_notifier.dart';
import 'package:key_box/features/auth/domain/auth_state.dart';

/// End-to-end restore through the auth + DB layer (in-memory DB — the keyed
/// SQLCipher open is integration_test territory, but every other step runs
/// here): a source vault's archive → [AuthNotifier.restoreFromBackup] → rows
/// AAD-bound under the NEW vault's MEK, decryptable and unlocked.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final enc = SecretEncryptionService();
  final kdf = KeyDerivationService();
  final kh = KeyHierarchyService();
  final mks = MasterKeyService();
  final recovery = VaultRecoveryService();

  ({Uint8List salt, Uint8List wrappedMek, Uint8List mek}) makeVault(String pw) {
    final salt = kdf.generateSalt();
    final pdk = kdf.deriveKey(password: pw, salt: salt);
    final kek = kh.deriveKek(pdk);
    final mek = mks.generateMasterKey();
    return (
      salt: salt,
      wrappedMek: mks.wrap(masterKey: mek, wrappingKey: kek),
      mek: mek,
    );
  }

  Secret storedSecret({
    required int id,
    required String name,
    required String value,
    required Uint8List mek,
    String secretType = 'api_key',
    String? serviceName,
    String? environment,
  }) {
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
      secretType: secretType,
      serviceName: serviceName,
      environment: environment,
      notes: null,
      tags: null,
      recordVersion: 1,
      accessCount: 0,
      lastAccessedAt: null,
      createdAt: now,
      updatedAt: now,
    );
  }

  String backupArchive(String password) {
    final v = makeVault(password);
    final secrets = [
      storedSecret(
        id: 1,
        name: 'GitHub PAT',
        value: 'ghp_secret_value_1',
        mek: v.mek,
        serviceName: 'GitHub',
        environment: 'production',
      ),
      storedSecret(
        id: 2,
        name: 'AWS Token',
        value: 'aws_secret_value_2',
        mek: v.mek,
        secretType: 'token',
      ),
    ];
    return recovery.buildArchive(
      salt: v.salt,
      wrappedMek: v.wrappedMek,
      secrets: secrets,
      mek: v.mek,
    )!;
  }

  late AppDatabase db;
  late AuthNotifier notifier;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    notifier = AuthNotifier(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('restores every secret into a fresh vault and unlocks', () async {
    const password = 'backup-master-password';
    final outcome = await notifier.restoreFromBackup(
      archive: backupArchive(password),
      password: password,
    );

    expect(outcome, isA<RestoreSuccess>());
    expect(notifier.state, isA<AuthUnlocked>());
    final unlocked = notifier.state as AuthUnlocked;

    final stored = await db.secretDao.getByVaultId(unlocked.vaultId);
    expect(stored.length, 2);

    // Each row is AAD-bound under the NEW vault's MEK and decrypts to the
    // original plaintext — proving the restore re-bound identity correctly.
    for (final s in stored) {
      final plaintext = enc.decrypt(
        encryptedValue: s.encryptedValue,
        iv: s.encryptedValueIv,
        authTag: s.encryptedValueAuthTag,
        key: unlocked.masterEncryptionKey,
        aad: secretAad(secretId: s.id, recordVersion: s.recordVersion),
      );
      expect(plaintext, isNotNull);
    }

    final github = stored.firstWhere((s) => s.name == 'GitHub PAT');
    expect(
      enc.decrypt(
        encryptedValue: github.encryptedValue,
        iv: github.encryptedValueIv,
        authTag: github.encryptedValueAuthTag,
        key: unlocked.masterEncryptionKey,
        aad: secretAad(
          secretId: github.id,
          recordVersion: github.recordVersion,
        ),
      ),
      'ghp_secret_value_1',
    );
    expect(github.serviceName, 'GitHub');
    expect(github.environment, 'production');
  });

  test('wrong password returns 오답 and creates no vault', () async {
    final outcome = await notifier.restoreFromBackup(
      archive: backupArchive('the-backup-password'),
      password: 'WRONG-password',
    );

    expect(outcome, isA<RestoreWrongPassword>());
    expect(notifier.state, isNot(isA<AuthUnlocked>()));
    expect(await db.vaultConfigDao.exists(), isFalse);
  });

  test('corrupt archive returns 손상 and creates no vault', () async {
    final outcome = await notifier.restoreFromBackup(
      archive: '{"format":"not-a-keybox-archive"}',
      password: 'whatever-password',
    );

    expect(outcome, isA<RestoreCorrupt>());
    expect(notifier.state, isNot(isA<AuthUnlocked>()));
    expect(await db.vaultConfigDao.exists(), isFalse);
  });

  test('restores an empty backup to an empty, unlocked vault', () async {
    const password = 'empty-backup-pw';
    final v = makeVault(password);
    final archive = recovery.buildArchive(
      salt: v.salt,
      wrappedMek: v.wrappedMek,
      secrets: const [],
      mek: v.mek,
    )!;

    final outcome = await notifier.restoreFromBackup(
      archive: archive,
      password: password,
    );

    expect(outcome, isA<RestoreSuccess>());
    expect(notifier.state, isA<AuthUnlocked>());
    final unlocked = notifier.state as AuthUnlocked;
    expect(await db.secretDao.getByVaultId(unlocked.vaultId), isEmpty);
  });
}
