import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'cipher_params.dart';
import 'vault_paths.dart';
import 'tables/vaults.dart';
import 'tables/vault_configs.dart';
import 'tables/folders.dart';
import 'tables/secrets.dart';
import 'tables/folder_secrets.dart';
import 'tables/audit_events.dart';
import 'daos/vault_dao.dart';
import 'daos/vault_config_dao.dart';
import 'daos/folder_dao.dart';
import 'daos/secret_dao.dart';
import 'daos/folder_secrets_dao.dart';
import 'daos/audit_event_dao.dart';

part 'database.g.dart';

@DriftDatabase(
  tables: [Vaults, VaultConfigs, Folders, Secrets, FolderSecrets, AuditEvents],
  daos: [
    VaultDao,
    VaultConfigDao,
    FolderDao,
    SecretDao,
    FolderSecretsDao,
    AuditEventDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  /// Opens the vault database.
  ///
  /// With [dbKey] (32 bytes, HKDF-derived — see KeyHierarchyService) the file
  /// is opened through SQLCipher in raw-key mode. Without it the legacy
  /// plaintext open is used — still the production path until B4 flips it,
  /// and the read side of the plaintext→encrypted migration.
  AppDatabase({Uint8List? dbKey}) : super(_openConnection(dbKey));

  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          // Add parentId column to folders
          await m.addColumn(folders, folders.parentId);
          // Create M:N join table
          await m.createTable(folderSecrets);
          // Migrate existing 1:N data into join table
          await customStatement(
            'INSERT INTO folder_secrets (folder_id, secret_id, created_at) '
            'SELECT folder_id, id, created_at FROM secrets',
          );
        }
        if (from < 3) {
          // AAD rollback defense: per-record version (existing rows → 1)
          await m.addColumn(secrets, secrets.recordVersion);
          // Drop dead master_password_digest column (password verification
          // happens via MEK unwrap) — drift rewrites the table.
          // TableMigration is drift's official column-drop path; it is only
          // flagged experimental upstream (covered by migration_v3_test).
          // ignore: experimental_member_use
          await m.alterTable(TableMigration(vaultConfigs));
        }
      },
    );
  }

  /// DEV ONLY: Delete all data and return to first-run state.
  Future<void> resetVault() async {
    await transaction(() async {
      await delete(auditEvents).go();
      await delete(folderSecrets).go();
      await delete(secrets).go();
      await delete(folders).go();
      await delete(vaultConfigs).go();
      await delete(vaults).go();
    });
  }
}

LazyDatabase _openConnection(Uint8List? dbKey) {
  return LazyDatabase(() async {
    final file = await VaultPaths.dbFile();
    if (dbKey == null) {
      return NativeDatabase.createInBackground(file);
    }

    // TODO(PR-B/F5): the hex key lives in an immutable Dart String for the
    // lifetime of the setup closure and cannot be zeroed out like the
    // Uint8List key material — accepted memory-hygiene gap, tracked with the
    // F5 series.
    final hexKey = sqlcipherRawKeyHex(dbKey);
    return NativeDatabase.createInBackground(
      file,
      setup: (db) {
        // Raw key mode (x'<hex64>'): the 32-byte key is used as the page key
        // directly, bypassing SQLCipher's internal KDF — correct here because
        // the key already went through PBKDF2+HKDF. Must be the first
        // statement on the connection. The hard-pin set (cipher_params.dart)
        // follows immediately — one-way-door defense.
        db.execute('PRAGMA key = "x\'$hexKey\'";');
        for (final pragma in cipherHardPinPragmas()) {
          db.execute(pragma);
        }
      },
    );
  });
}
