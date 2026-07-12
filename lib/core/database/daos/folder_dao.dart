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
    int? parentId,
    String icon = 'folder',
    int position = 0,
  }) {
    final now = DateTime.now();
    return into(folders).insertReturning(
      FoldersCompanion.insert(
        vaultId: vaultId,
        name: name,
        parentId: Value(parentId),
        icon: Value(icon),
        position: Value(position),
        createdAt: now,
        updatedAt: now,
      ),
    );
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

  Future<bool> updateFolder(
    int id, {
    String? name,
    String? icon,
    int? position,
  }) {
    return (update(folders)..where((t) => t.id.equals(id)))
        .write(
          FoldersCompanion(
            name: name != null ? Value(name) : const Value.absent(),
            icon: icon != null ? Value(icon) : const Value.absent(),
            position: position != null ? Value(position) : const Value.absent(),
            updatedAt: Value(DateTime.now()),
          ),
        )
        .then((rows) => rows > 0);
  }

  Future<int> deleteFolder(int id) {
    return (delete(folders)..where((t) => t.id.equals(id))).go();
  }

  // ─── Tree query methods ───

  /// Watch root folders (parentId == null) for a vault.
  Stream<List<Folder>> watchRootFolders(int vaultId) {
    return (select(folders)
          ..where((t) => t.vaultId.equals(vaultId) & t.parentId.isNull())
          ..orderBy([(t) => OrderingTerm(expression: t.position)]))
        .watch();
  }

  /// Watch direct children of a folder.
  Stream<List<Folder>> watchChildren(int parentId) {
    return (select(folders)
          ..where((t) => t.parentId.equals(parentId))
          ..orderBy([(t) => OrderingTerm(expression: t.position)]))
        .watch();
  }

  /// Get all descendant folder IDs using a recursive CTE.
  Future<List<int>> getDescendantIds(int folderId) async {
    final result = await customSelect(
      'WITH RECURSIVE descendants(id) AS ('
      '  SELECT id FROM folders WHERE parent_id = ? '
      '  UNION ALL '
      '  SELECT f.id FROM folders f '
      '  INNER JOIN descendants d ON f.parent_id = d.id'
      ') SELECT id FROM descendants',
      variables: [Variable.withInt(folderId)],
    ).get();
    return result.map((row) => row.read<int>('id')).toList();
  }

  /// Move a folder to a new parent (or to root if newParentId is null).
  Future<bool> moveFolder(int id, int? newParentId) {
    return (update(folders)..where((t) => t.id.equals(id)))
        .write(
          FoldersCompanion(
            parentId: Value(newParentId),
            updatedAt: Value(DateTime.now()),
          ),
        )
        .then((rows) => rows > 0);
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
