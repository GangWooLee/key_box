import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:key_box/core/database/vault_paths.dart';
import 'package:key_box/core/encryption/master_key_service.dart';
import 'package:key_box/core/encryption/secret_encryption_service.dart';
import 'package:key_box/core/vault/vault_migrator.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

void main() {
  late Directory tmp;
  late VaultMigrator migrator;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('vault_migrator_test_');
    migrator = VaultMigrator(baseDir: () async => tmp);
  });

  tearDown(() {
    if (tmp.existsSync()) tmp.deleteSync(recursive: true);
  });

  String path(String name) => '${tmp.path}/$name';
  File mainFile() => File(path(VaultPaths.dbFileName));
  File preFile() => File(path(VaultPaths.dbPreEncryptionFileName));
  File migratingFile() => File(path(VaultPaths.dbMigratingFileName));

  /// Creates a real plaintext SQLite file at [filePath].
  void createPlaintextDb(String filePath) {
    final db = sqlite.sqlite3.open(filePath);
    db.execute('CREATE TABLE marker (v TEXT);');
    db.dispose();
  }

  group('VaultMigrator.isPlaintextDb', () {
    test('returns true for a plaintext SQLite file', () async {
      createPlaintextDb(path('plain.db'));
      expect(await VaultMigrator.isPlaintextDb(File(path('plain.db'))), isTrue);
    });

    test('returns false for a file without the SQLite header', () async {
      final f = File(path('random.db'))
        ..writeAsBytesSync(List.generate(64, (i) => (i * 37) & 0xFF));
      expect(await VaultMigrator.isPlaintextDb(f), isFalse);
    });

    test('returns false for a missing file', () async {
      expect(
        await VaultMigrator.isPlaintextDb(File(path('missing.db'))),
        isFalse,
      );
    });

    test('returns false for a file shorter than the 16-byte header', () async {
      final f = File(path('short.db'))..writeAsBytesSync([0x53, 0x51, 0x4C]);
      expect(await VaultMigrator.isPlaintextDb(f), isFalse);
    });
  });

  group('VaultMigrator.recoverInterrupted', () {
    test('rolls back .pre-encryption to main when main is missing', () async {
      preFile().writeAsBytesSync([1, 2, 3, 4]);

      await migrator.recoverInterrupted();

      expect(mainFile().existsSync(), isTrue);
      expect(mainFile().readAsBytesSync(), [1, 2, 3, 4]);
      expect(preFile().existsSync(), isFalse);
    });

    test('deletes leftover .migrating debris (with WAL/SHM)', () async {
      mainFile().writeAsBytesSync([9, 9, 9]);
      migratingFile().writeAsBytesSync([1]);
      File('${migratingFile().path}-wal').writeAsBytesSync([2]);
      File('${migratingFile().path}-shm').writeAsBytesSync([3]);

      await migrator.recoverInterrupted();

      expect(migratingFile().existsSync(), isFalse);
      expect(File('${migratingFile().path}-wal').existsSync(), isFalse);
      expect(File('${migratingFile().path}-shm').existsSync(), isFalse);
      expect(mainFile().readAsBytesSync(), [9, 9, 9]);
    });

    test('is a no-op on a healthy layout (idempotent)', () async {
      mainFile().writeAsBytesSync([7, 7]);

      await migrator.recoverInterrupted();
      await migrator.recoverInterrupted();

      expect(mainFile().readAsBytesSync(), [7, 7]);
      expect(preFile().existsSync(), isFalse);
      expect(migratingFile().existsSync(), isFalse);
    });
  });

  group('VaultMigrator.classifyRecordCipher (mixed-AAD rule)', () {
    final enc = SecretEncryptionService();
    final mek = Uint8List(32)..fillRange(0, 32, 7);

    test('recognizes an AAD-bound record and returns its plaintext', () {
      final bound = enc.encrypt(
        value: 'bound-value',
        key: mek,
        aad: secretAad(secretId: 5, recordVersion: 2),
      );

      final result = migrator.classifyRecordCipher(
        encryptedValue: bound.encryptedValue,
        iv: bound.iv,
        authTag: bound.authTag,
        mek: mek,
        secretId: 5,
        recordVersion: 2,
      );

      expect(result.binding, RecordCipherBinding.aadBound);
      expect(result.plaintext, 'bound-value');
    });

    test('falls back to empty AAD for a legacy record', () {
      final legacy = enc.encrypt(value: 'legacy-value', key: mek);

      final result = migrator.classifyRecordCipher(
        encryptedValue: legacy.encryptedValue,
        iv: legacy.iv,
        authTag: legacy.authTag,
        mek: mek,
        secretId: 5,
        recordVersion: 1,
      );

      expect(result.binding, RecordCipherBinding.legacyUnbound);
      expect(result.plaintext, 'legacy-value');
    });

    test('reports unreadable when both AAD forms fail (corrupted tag)', () {
      final good = enc.encrypt(value: 'v', key: mek);
      final badTag = Uint8List.fromList(good.authTag);
      badTag[0] ^= 0xFF;

      final result = migrator.classifyRecordCipher(
        encryptedValue: good.encryptedValue,
        iv: good.iv,
        authTag: badTag,
        mek: mek,
        secretId: 1,
        recordVersion: 1,
      );

      expect(result.binding, RecordCipherBinding.unreadable);
      expect(result.plaintext, isNull);
    });

    test('reports unreadable for a record bound to a different identity', () {
      final bound = enc.encrypt(
        value: 'v',
        key: mek,
        aad: secretAad(secretId: 1, recordVersion: 1),
      );

      final result = migrator.classifyRecordCipher(
        encryptedValue: bound.encryptedValue,
        iv: bound.iv,
        authTag: bound.authTag,
        mek: mek,
        secretId: 2, // substituted row identity
        recordVersion: 1,
      );

      expect(result.binding, RecordCipherBinding.unreadable);
      expect(result.plaintext, isNull);
    });
  });

  group('VaultMigrator.parseDfAvailableKb', () {
    test('parses the Available column of macOS df -k output', () {
      const output =
          'Filesystem 1024-blocks      Used Available Capacity  '
          'iused      ifree %iused  Mounted on\n'
          '/dev/disk3s5  971350180 250000000 700000000    27% 1000000 '
          '4290000000    0%   /System/Volumes/Data\n';
      expect(VaultMigrator.parseDfAvailableKb(output), 700000000);
    });

    test('returns null on unparseable output', () {
      expect(VaultMigrator.parseDfAvailableKb('garbage'), isNull);
      expect(VaultMigrator.parseDfAvailableKb(''), isNull);
    });
  });

  group('VaultMigrator.migrate — cipher-free early aborts', () {
    final mks = MasterKeyService();
    final anyKey = Uint8List(32)..fillRange(0, 32, 0xC1);

    /// Builds a plaintext vault fixture whose MEK is wrapped under
    /// [correctPdk] with legacy raw-PDK semantics.
    void createVaultFixture(Uint8List correctPdk) {
      final db = sqlite.sqlite3.open(mainFile().path);
      db.execute('''
        CREATE TABLE vault_configs (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          vault_id INTEGER NOT NULL,
          master_key_salt BLOB NOT NULL,
          encrypted_master_key BLOB NOT NULL,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL
        );
      ''');
      final mek = Uint8List(32)..fillRange(0, 32, 0x5E);
      final wrapped = mks.wrap(masterKey: mek, wrappingKey: correctPdk);
      db.execute(
        'INSERT INTO vault_configs (vault_id, master_key_salt, '
        'encrypted_master_key, created_at, updated_at) '
        'VALUES (1, ?, ?, 100, 100);',
        [Uint8List(32)..fillRange(0, 32, 3), wrapped],
      );
      db.dispose();
    }

    test('wrong password aborts before any irreversible work', () async {
      final correctPdk = Uint8List(32)..fillRange(0, 32, 0xAA);
      createVaultFixture(correctPdk);
      final before = mainFile().readAsBytesSync();

      final wrongPdk = Uint8List(32)..fillRange(0, 32, 0xBB);
      final result = await migrator.migrate(
        legacyPdk: wrongPdk,
        dbKey: anyKey,
        kek: anyKey,
      );

      expect(result, isA<MigrationFailure>());
      expect(
        (result as MigrationFailure).reason,
        MigrationFailureReason.wrongPassword,
      );
      // Source untouched; no migration artifacts.
      expect(mainFile().readAsBytesSync(), before);
      expect(preFile().existsSync(), isFalse);
      expect(migratingFile().existsSync(), isFalse);
      final backups = tmp.listSync().where(
        (e) => e.path.endsWith(VaultPaths.backupFileSuffix),
      );
      expect(backups, isEmpty);
    });

    test(
      'a vault without a config row aborts with integrityCheckFailed',
      () async {
        final db = sqlite.sqlite3.open(mainFile().path);
        db.execute(
          'CREATE TABLE vault_configs (id INTEGER PRIMARY KEY, '
          'master_key_salt BLOB, encrypted_master_key BLOB);',
        );
        db.dispose();

        final result = await migrator.migrate(
          legacyPdk: anyKey,
          dbKey: anyKey,
          kek: anyKey,
        );

        expect(result, isA<MigrationFailure>());
        expect(
          (result as MigrationFailure).reason,
          MigrationFailureReason.integrityCheckFailed,
        );
      },
    );

    test(
      'a non-plaintext main file aborts with integrityCheckFailed',
      () async {
        mainFile().writeAsBytesSync(List.generate(64, (i) => (i * 31) & 0xFF));

        final result = await migrator.migrate(
          legacyPdk: anyKey,
          dbKey: anyKey,
          kek: anyKey,
        );

        expect(result, isA<MigrationFailure>());
        expect(
          (result as MigrationFailure).reason,
          MigrationFailureReason.integrityCheckFailed,
        );
      },
    );
  });
}
