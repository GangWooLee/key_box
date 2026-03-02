import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/folders.dart';

part 'folder_dao.g.dart';

@DriftAccessor(tables: [Folders])
class FolderDao extends DatabaseAccessor<AppDatabase> with _$FolderDaoMixin {
  FolderDao(super.db);

  Future<Folder> create({
    required int vaultId,
    required String name,
    String icon = 'folder',
    int position = 0,
  }) {
    final now = DateTime.now();
    return into(folders).insertReturning(FoldersCompanion.insert(
      vaultId: vaultId,
      name: name,
      icon: Value(icon),
      position: Value(position),
      createdAt: now,
      updatedAt: now,
    ));
  }

  Future<List<Folder>> getByVaultId(int vaultId) {
    return (select(folders)
          ..where((t) => t.vaultId.equals(vaultId))
          ..orderBy([(t) => OrderingTerm(expression: t.position)]))
        .get();
  }

  Stream<List<Folder>> watchByVaultId(int vaultId) {
    return (select(folders)
          ..where((t) => t.vaultId.equals(vaultId))
          ..orderBy([(t) => OrderingTerm(expression: t.position)]))
        .watch();
  }

  Future<bool> updateFolder(int id, {String? name, String? icon, int? position}) {
    return (update(folders)..where((t) => t.id.equals(id))).write(
      FoldersCompanion(
        name: name != null ? Value(name) : const Value.absent(),
        icon: icon != null ? Value(icon) : const Value.absent(),
        position: position != null ? Value(position) : const Value.absent(),
        updatedAt: Value(DateTime.now()),
      ),
    ).then((rows) => rows > 0);
  }

  Future<int> deleteFolder(int id) {
    return (delete(folders)..where((t) => t.id.equals(id))).go();
  }

  Future<void> incrementSecretsCount(int folderId) {
    return customStatement(
      'UPDATE folders SET secrets_count = secrets_count + 1 WHERE id = ?',
      [folderId],
    );
  }

  Future<void> decrementSecretsCount(int folderId) {
    return customStatement(
      'UPDATE folders SET secrets_count = CASE WHEN secrets_count > 0 THEN secrets_count - 1 ELSE 0 END WHERE id = ?',
      [folderId],
    );
  }
}
