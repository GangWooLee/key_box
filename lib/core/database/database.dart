import 'package:drift/drift.dart';
import 'package:drift/native.dart';
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
  AppDatabase() : super(_openConnection());

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

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final file = await VaultPaths.dbFile();
    return NativeDatabase.createInBackground(file);
  });
}
