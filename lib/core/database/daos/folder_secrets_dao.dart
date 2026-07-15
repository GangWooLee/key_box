import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/folder_secrets.dart';
import '../tables/secrets.dart';

part 'folder_secrets_dao.g.dart';

@DriftAccessor(tables: [FolderSecrets, Secrets])
class FolderSecretsDao extends DatabaseAccessor<AppDatabase>
    with _$FolderSecretsDaoMixin {
  FolderSecretsDao(super.db);

  /// Link a secret to a folder (M:N).
  Future<void> link(int folderId, int secretId) {
    return into(folderSecrets).insert(
      FolderSecretsCompanion.insert(
        folderId: folderId,
        secretId: secretId,
        createdAt: DateTime.now(),
      ),
      mode: InsertMode.insertOrIgnore,
    );
  }

  /// Remove a secret-folder link.
  Future<int> unlink(int folderId, int secretId) {
    return (delete(folderSecrets)..where(
          (t) => t.folderId.equals(folderId) & t.secretId.equals(secretId),
        ))
        .go();
  }

  /// Watch all secrets linked to a folder.
  Stream<List<Secret>> watchSecretsByFolderId(int folderId) {
    final query =
        select(secrets).join([
            innerJoin(
              folderSecrets,
              folderSecrets.secretId.equalsExp(secrets.id),
            ),
          ])
          ..where(folderSecrets.folderId.equals(folderId))
          ..orderBy([OrderingTerm.desc(secrets.updatedAt)]);

    return query.watch().map(
      (rows) => rows.map((row) => row.readTable(secrets)).toList(),
    );
  }

  /// Watch live member counts per folder, derived straight from the M:N join
  /// table — the single source of truth for folder counts. Folders with no
  /// links are absent from the map (callers use `?? 0`). Replaces the
  /// drift-prone `folders.secretsCount` cache column, whose write paths
  /// (migration, link/unlink, delete) diverged from the join table.
  Stream<Map<int, int>> watchCountsByFolder() {
    final countExpr = folderSecrets.secretId.count();
    final query = selectOnly(folderSecrets)
      ..addColumns([folderSecrets.folderId, countExpr])
      ..groupBy([folderSecrets.folderId]);
    return query.watch().map(
      (rows) => {
        for (final row in rows)
          row.read(folderSecrets.folderId)!: row.read(countExpr)!,
      },
    );
  }

  /// Get all folder IDs a secret belongs to.
  Future<List<int>> getFolderIdsBySecretId(int secretId) {
    final query = select(folderSecrets)
      ..where((t) => t.secretId.equals(secretId));
    return query.map((row) => row.folderId).get();
  }

  /// Check if a secret is linked to a folder.
  Future<bool> isLinked(int folderId, int secretId) async {
    final query = select(folderSecrets)
      ..where((t) => t.folderId.equals(folderId) & t.secretId.equals(secretId));
    final result = await query.getSingleOrNull();
    return result != null;
  }

  /// Remove all links for a secret (used on secret deletion).
  Future<int> unlinkAllForSecret(int secretId) {
    return (delete(
      folderSecrets,
    )..where((t) => t.secretId.equals(secretId))).go();
  }

  /// Remove all links for a folder (used on folder deletion).
  Future<int> unlinkAllForFolder(int folderId) {
    return (delete(
      folderSecrets,
    )..where((t) => t.folderId.equals(folderId))).go();
  }
}
