import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'vault_paths.dart';
import 'tables/vaults.dart';
import 'tables/vault_configs.dart';
import 'tables/folders.dart';
import 'tables/secrets.dart';
import 'tables/audit_events.dart';
import 'daos/vault_dao.dart';
import 'daos/vault_config_dao.dart';
import 'daos/folder_dao.dart';
import 'daos/secret_dao.dart';
import 'daos/audit_event_dao.dart';

part 'database.g.dart';

@DriftDatabase(
  tables: [Vaults, VaultConfigs, Folders, Secrets, AuditEvents],
  daos: [VaultDao, VaultConfigDao, FolderDao, SecretDao, AuditEventDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final file = await VaultPaths.dbFile();
    return NativeDatabase.createInBackground(file);
  });
}
