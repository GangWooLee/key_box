import 'dart:typed_data';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:key_box/core/database/database.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3_pkg;

/// Builds a raw in-memory database carrying the exact v2 schema
/// (secrets without record_version, vault_configs with
/// master_password_digest) plus one row per table, stamped user_version = 2.
sqlite3_pkg.Database _buildV2Database() {
  final raw = sqlite3_pkg.sqlite3.openInMemory();
  raw.execute('''
    CREATE TABLE vaults (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      description TEXT,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL
    );
    CREATE TABLE vault_configs (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      vault_id INTEGER NOT NULL UNIQUE REFERENCES vaults (id),
      master_key_salt BLOB NOT NULL,
      encrypted_master_key BLOB NOT NULL,
      master_password_digest TEXT NOT NULL,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL
    );
    CREATE TABLE folders (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      vault_id INTEGER NOT NULL REFERENCES vaults (id),
      parent_id INTEGER REFERENCES folders (id),
      name TEXT NOT NULL,
      icon TEXT NOT NULL DEFAULT 'folder',
      position INTEGER NOT NULL DEFAULT 0,
      secrets_count INTEGER NOT NULL DEFAULT 0,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL,
      UNIQUE (vault_id, name)
    );
    CREATE TABLE secrets (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      vault_id INTEGER NOT NULL REFERENCES vaults (id),
      folder_id INTEGER NOT NULL REFERENCES folders (id),
      name TEXT NOT NULL,
      encrypted_value BLOB NOT NULL,
      encrypted_value_iv BLOB NOT NULL,
      encrypted_value_auth_tag BLOB NOT NULL,
      secret_type TEXT NOT NULL DEFAULT 'api_key',
      service_name TEXT,
      environment TEXT,
      notes TEXT,
      tags TEXT,
      access_count INTEGER NOT NULL DEFAULT 0,
      last_accessed_at INTEGER,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL
    );
    CREATE TABLE folder_secrets (
      folder_id INTEGER NOT NULL REFERENCES folders (id),
      secret_id INTEGER NOT NULL REFERENCES secrets (id),
      created_at INTEGER NOT NULL,
      PRIMARY KEY (folder_id, secret_id)
    );
    CREATE TABLE audit_events (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      vault_id INTEGER NOT NULL REFERENCES vaults (id),
      secret_id INTEGER REFERENCES secrets (id),
      action TEXT NOT NULL,
      metadata TEXT,
      created_at INTEGER NOT NULL
    );
  ''');

  raw.execute(
    "INSERT INTO vaults (id, name, created_at, updated_at) "
    "VALUES (1, 'Personal', 100, 100)",
  );
  raw.execute(
    'INSERT INTO vault_configs (id, vault_id, master_key_salt, '
    'encrypted_master_key, master_password_digest, created_at, updated_at) '
    "VALUES (1, 1, ?, ?, 'legacy-bcrypt-digest', 100, 100)",
    [
      Uint8List.fromList(List.filled(32, 0xAA)),
      Uint8List.fromList(List.filled(60, 0xBB)),
    ],
  );
  raw.execute(
    "INSERT INTO folders (id, vault_id, name, created_at, updated_at) "
    "VALUES (1, 1, 'General', 100, 100)",
  );
  raw.execute(
    'INSERT INTO secrets (id, vault_id, folder_id, name, encrypted_value, '
    'encrypted_value_iv, encrypted_value_auth_tag, created_at, updated_at) '
    "VALUES (1, 1, 1, 'Legacy Key', ?, ?, ?, 100, 100)",
    [
      Uint8List.fromList([1, 2, 3]),
      Uint8List.fromList([4, 5, 6]),
      Uint8List.fromList([7, 8, 9]),
    ],
  );
  raw.execute(
    'INSERT INTO folder_secrets (folder_id, secret_id, created_at) '
    'VALUES (1, 1, 100)',
  );

  raw.execute('PRAGMA user_version = 2');
  return raw;
}

Future<List<String>> _columnNames(AppDatabase db, String table) async {
  final rows = await db.customSelect('PRAGMA table_info($table)').get();
  return rows.map((r) => r.data['name'] as String).toList();
}

void main() {
  group('Schema v3 — upgrade from v2', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.opened(_buildV2Database()));
    });

    tearDown(() async {
      await db.close();
    });

    test('bumps user_version to 3', () async {
      final row = await db.customSelect('PRAGMA user_version').getSingle();
      expect(row.data['user_version'], equals(3));
    });

    test(
      'adds record_version to secrets with default 1 for existing rows',
      () async {
        final secret = await db.secretDao.getById(1);
        expect(secret, isNotNull);
        expect(secret!.recordVersion, equals(1));
      },
    );

    test('drops master_password_digest from vault_configs', () async {
      final columns = await _columnNames(db, 'vault_configs');
      expect(columns, isNot(contains('master_password_digest')));
      // The surviving columns are intact.
      expect(
        columns,
        containsAll([
          'id',
          'vault_id',
          'master_key_salt',
          'encrypted_master_key',
          'created_at',
          'updated_at',
        ]),
      );
    });

    test('preserves existing data across the upgrade', () async {
      final vault = await db.vaultDao.getFirst();
      expect(vault?.name, equals('Personal'));

      final config = await db.vaultConfigDao.getByVaultId(1);
      expect(config, isNotNull);
      expect(config!.masterKeySalt, equals(List.filled(32, 0xAA)));
      expect(config.encryptedMasterKey, equals(List.filled(60, 0xBB)));

      final secret = await db.secretDao.getById(1);
      expect(secret!.name, equals('Legacy Key'));
      expect(secret.encryptedValue, equals([1, 2, 3]));
      expect(secret.encryptedValueIv, equals([4, 5, 6]));
      expect(secret.encryptedValueAuthTag, equals([7, 8, 9]));

      final linked = await db.folderSecretsDao.isLinked(1, 1);
      expect(linked, isTrue);
    });
  });

  group('Schema v3 — fresh database', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    test('new secrets default to recordVersion 1', () async {
      final vault = await db.vaultDao.create(name: 'Test');
      final folder = await db.folderDao.create(
        vaultId: vault.id,
        name: 'General',
      );
      final secret = await db.secretDao.create(
        vaultId: vault.id,
        folderId: folder.id,
        name: 'API Key',
        encryptedValue: Uint8List.fromList([1]),
        encryptedValueIv: Uint8List.fromList([2]),
        encryptedValueAuthTag: Uint8List.fromList([3]),
      );
      expect(secret.recordVersion, equals(1));
    });

    test('vault_configs has no master_password_digest column', () async {
      final vault = await db.vaultDao.create(name: 'Test');
      await db.vaultConfigDao.create(
        vaultId: vault.id,
        masterKeySalt: Uint8List.fromList(List.filled(32, 1)),
        encryptedMasterKey: Uint8List.fromList(List.filled(60, 2)),
      );

      final columns = await _columnNames(db, 'vault_configs');
      expect(columns, isNot(contains('master_password_digest')));

      final config = await db.vaultConfigDao.getByVaultId(vault.id);
      expect(config, isNotNull);
    });

    test('secretDao.updateSecret can bump recordVersion', () async {
      final vault = await db.vaultDao.create(name: 'Test');
      final folder = await db.folderDao.create(
        vaultId: vault.id,
        name: 'General',
      );
      final secret = await db.secretDao.create(
        vaultId: vault.id,
        folderId: folder.id,
        name: 'Rotating Key',
        encryptedValue: Uint8List.fromList([1]),
        encryptedValueIv: Uint8List.fromList([2]),
        encryptedValueAuthTag: Uint8List.fromList([3]),
      );

      await db.secretDao.updateSecret(
        secret.id,
        encryptedValue: Uint8List.fromList([9]),
        encryptedValueIv: Uint8List.fromList([8]),
        encryptedValueAuthTag: Uint8List.fromList([7]),
        recordVersion: 2,
      );

      final updated = await db.secretDao.getById(secret.id);
      expect(updated!.recordVersion, equals(2));
    });
  });
}
