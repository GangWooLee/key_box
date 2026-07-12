// PR-B (B4b): end-to-end plaintext→SQLCipher vault migration through the
// REAL providers and the REAL cipher — the canonical gate for the flip.
//
// Must run in the real macOS app (plain `flutter test` loads Apple's
// restricted libsqlite3 which silently ignores PRAGMA key):
//   flutter test integration_test/vault_migration_e2e_test.dart -d macos
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:key_box/core/database/database.dart';
import 'package:key_box/core/database/vault_paths.dart';
import 'package:key_box/core/encryption/key_derivation_service.dart';
import 'package:key_box/core/encryption/master_key_service.dart';
import 'package:key_box/core/encryption/secret_encryption_service.dart';
import 'package:key_box/core/utils/result.dart';
import 'package:key_box/core/vault/sidecar_store.dart';
import 'package:key_box/core/vault/vault_migrator.dart';
import 'package:key_box/features/auth/domain/auth_notifier.dart';
import 'package:key_box/features/auth/domain/auth_state.dart';
import 'package:key_box/features/secrets/domain/secrets_providers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

const _password = 'e2e-Passw0rd!42';
const _plain1 = 'sk-legacy-alpha-11111';
const _plain2 = 'pg-legacy-beta-22222';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late Directory tmp;
  late Future<Directory> Function() previousSupportDir;

  setUp(() async {
    final base = await getApplicationSupportDirectory();
    tmp = Directory(
      '${base.path}/b4b_e2e_${DateTime.now().microsecondsSinceEpoch}',
    )..createSync(recursive: true);
    previousSupportDir = VaultPaths.supportDir;
    VaultPaths.supportDir = () async => tmp;
  });

  tearDown(() {
    VaultPaths.supportDir = previousSupportDir;
    if (tmp.existsSync()) tmp.deleteSync(recursive: true);
  });

  Future<String> dbHeader() async {
    final bytes = (await VaultPaths.dbFile()).readAsBytesSync();
    return String.fromCharCodes(bytes.take(15));
  }

  Future<void> expectEncryptedOnDisk() async {
    expect(await dbHeader(), isNot('SQLite format 3'));
    Object? keylessError;
    try {
      final raw = sqlite3.open((await VaultPaths.dbFile()).path);
      try {
        raw.select('SELECT * FROM vaults;');
      } finally {
        raw.dispose();
      }
    } catch (e) {
      keylessError = e;
    }
    expect(
      keylessError,
      isA<SqliteException>(),
      reason: 'a keyless read of the vault file must fail',
    );
  }

  /// Builds a pre-flip vault: plaintext DB, MEK wrapped under the RAW PDK,
  /// two secrets with legacy empty-AAD ciphertext, salt in the sidecar.
  Future<void> buildLegacyFixture() async {
    final kds = KeyDerivationService();
    final mks = MasterKeyService();
    final enc = SecretEncryptionService();
    final salt = kds.generateSalt();
    final pdk = kds.deriveKey(password: _password, salt: salt);
    final mek = mks.generateMasterKey();

    final db = AppDatabase(); // plaintext open — legacy era
    final vault = await db.vaultDao.create(name: 'Personal');
    await db.vaultConfigDao.create(
      vaultId: vault.id,
      masterKeySalt: salt,
      encryptedMasterKey: mks.wrap(masterKey: mek, wrappingKey: pdk),
    );
    final folder = await db.folderDao.create(
      vaultId: vault.id,
      name: 'General',
    );
    var index = 0;
    for (final value in [_plain1, _plain2]) {
      final encrypted = enc.encrypt(value: value, key: mek); // empty AAD
      await db.secretDao.create(
        vaultId: vault.id,
        folderId: folder.id,
        name: 'Legacy ${index++}',
        encryptedValue: encrypted.encryptedValue,
        encryptedValueIv: encrypted.iv,
        encryptedValueAuthTag: encrypted.authTag,
      );
    }
    await db.close();
    await FileSidecarStore().write(salt);
  }

  testWidgets(
    'legacy plaintext vault: unlock migrates to SQLCipher, round-trips, '
    'and rejects a wrong password',
    (tester) async {
      await buildLegacyFixture();
      expect(
        await VaultMigrator.isPlaintextDb(await VaultPaths.dbFile()),
        isTrue,
        reason: 'fixture sanity: starts plaintext',
      );

      // ② Real providers, fresh container (fresh app boot).
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final auth = container.read(authProvider.notifier);

      await auth.initialize();
      expect(container.read(authProvider), isA<AuthLocked>());

      final error = await auth.unlock(password: _password);
      expect(error, isNull);
      expect(container.read(authProvider), isA<AuthUnlocked>());

      // ③ Really encrypted on disk.
      await expectEncryptedOnDisk();

      // Secrets survived, AAD-bound, recordVersion preserved.
      final state = container.read(authProvider) as AuthUnlocked;
      final db = container.read(databaseProvider);
      final secrets = await db.secretDao.getByVaultId(state.vaultId);
      expect(secrets, hasLength(2));
      final enc = SecretEncryptionService();
      final values = <String>{};
      for (final secret in secrets) {
        expect(secret.recordVersion, 1, reason: 'binding is not a rotation');
        final value = enc.decrypt(
          encryptedValue: Uint8List.fromList(secret.encryptedValue),
          iv: Uint8List.fromList(secret.encryptedValueIv),
          authTag: Uint8List.fromList(secret.encryptedValueAuthTag),
          key: state.masterEncryptionKey,
          aad: secretAad(
            secretId: secret.id,
            recordVersion: secret.recordVersion,
          ),
        );
        expect(value, isNotNull, reason: 'migrated record must be AAD-bound');
        values.add(value!);
      }
      expect(values, {_plain1, _plain2});

      // No plaintext remnants or migration debris.
      expect(
        File('${tmp.path}/${VaultPaths.dbPreEncryptionFileName}').existsSync(),
        isFalse,
      );
      expect(
        File('${tmp.path}/${VaultPaths.dbMigratingFileName}').existsSync(),
        isFalse,
      );
      expect(
        tmp.listSync().where(
          (e) => e.path.endsWith(VaultPaths.backupFileSuffix),
        ),
        isEmpty,
        reason: 'the auto-backup archive is deleted after a verified success',
      );

      // ④ lock → ⑤ wrong password → correct password round-trip.
      await auth.lock();
      expect(container.read(authProvider), isA<AuthLocked>());

      final wrongError = await auth.unlock(password: 'wrong-password-99');
      expect(wrongError, 'Incorrect password');
      expect(container.read(authProvider), isA<AuthLocked>());
      await expectEncryptedOnDisk();

      final retryError = await auth.unlock(password: _password);
      expect(retryError, isNull);
      expect(container.read(authProvider), isA<AuthUnlocked>());
      await auth.lock();
    },
  );

  testWidgets('new vault: setup is encrypted from birth and round-trips', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final auth = container.read(authProvider.notifier);

    await auth.initialize();
    expect(container.read(authProvider), isA<AuthFirstRun>());

    final error = await auth.setup(
      password: _password,
      confirmation: _password,
    );
    expect(error, isNull);
    expect(container.read(authProvider), isA<AuthUnlocked>());

    // Store one secret through the real operations path.
    final state = container.read(authProvider) as AuthUnlocked;
    final db = container.read(databaseProvider);
    final folder = (await db.folderDao.getByVaultId(state.vaultId)).single;
    final created = await container
        .read(secretOpsProvider)
        .create(name: 'Fresh', value: 'fresh-value-42', folderId: folder.id);
    expect(created, isA<Success<Secret>>());

    await auth.lock();
    await expectEncryptedOnDisk();

    final unlockError = await auth.unlock(password: _password);
    expect(unlockError, isNull);
    expect(container.read(authProvider), isA<AuthUnlocked>());

    final reopened = container.read(databaseProvider);
    final secrets = await reopened.secretDao.getByVaultId(
      (container.read(authProvider) as AuthUnlocked).vaultId,
    );
    final value = await container
        .read(secretOpsProvider)
        .decrypt(secrets.single);
    expect(value, 'fresh-value-42');
    await auth.lock();
  });
}
