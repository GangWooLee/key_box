import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/secrets.dart';
import '../../constants/app_constants.dart';

part 'secret_dao.g.dart';

@DriftAccessor(tables: [Secrets])
class SecretDao extends DatabaseAccessor<AppDatabase> with _$SecretDaoMixin {
  SecretDao(super.db);

  Future<Secret> create({
    required int vaultId,
    required int folderId,
    required String name,
    required Uint8List encryptedValue,
    required Uint8List encryptedValueIv,
    required Uint8List encryptedValueAuthTag,
    String secretType = 'api_key',
    String? serviceName,
    String? environment,
    String? notes,
    String? tags,
  }) {
    final now = DateTime.now();
    return into(secrets).insertReturning(
      SecretsCompanion.insert(
        vaultId: vaultId,
        folderId: folderId,
        name: name,
        encryptedValue: encryptedValue,
        encryptedValueIv: encryptedValueIv,
        encryptedValueAuthTag: encryptedValueAuthTag,
        secretType: Value(secretType),
        serviceName: Value(serviceName),
        environment: Value(environment),
        notes: Value(notes),
        tags: Value(tags),
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  Future<Secret?> getById(int id) {
    return (select(secrets)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<List<Secret>> getByFolderId(int folderId) {
    return (select(secrets)
          ..where((t) => t.folderId.equals(folderId))
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .get();
  }

  Stream<List<Secret>> watchByFolderId(int folderId) {
    return (select(secrets)
          ..where((t) => t.folderId.equals(folderId))
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .watch();
  }

  Future<List<Secret>> getByVaultId(int vaultId) {
    return (select(secrets)
          ..where((t) => t.vaultId.equals(vaultId))
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .get();
  }

  Stream<List<Secret>> watchByVaultId(int vaultId) {
    return (select(secrets)
          ..where((t) => t.vaultId.equals(vaultId))
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .watch();
  }

  Future<List<Secret>> search(int vaultId, String query) {
    final pattern = '%$query%';
    return (select(secrets)
          ..where(
            (t) =>
                t.vaultId.equals(vaultId) &
                (t.name.like(pattern) |
                    t.serviceName.like(pattern) |
                    t.tags.like(pattern) |
                    t.notes.like(pattern)),
          )
          ..limit(AppConstants.searchResultLimit))
        .get();
  }

  Future<bool> updateSecret(
    int id, {
    String? name,
    Uint8List? encryptedValue,
    Uint8List? encryptedValueIv,
    Uint8List? encryptedValueAuthTag,
    String? secretType,
    String? serviceName,
    String? environment,
    String? notes,
    String? tags,
    int? folderId,
    int? recordVersion,
  }) {
    return (update(secrets)..where((t) => t.id.equals(id)))
        .write(
          SecretsCompanion(
            name: name != null ? Value(name) : const Value.absent(),
            encryptedValue: encryptedValue != null
                ? Value(encryptedValue)
                : const Value.absent(),
            encryptedValueIv: encryptedValueIv != null
                ? Value(encryptedValueIv)
                : const Value.absent(),
            encryptedValueAuthTag: encryptedValueAuthTag != null
                ? Value(encryptedValueAuthTag)
                : const Value.absent(),
            secretType: secretType != null
                ? Value(secretType)
                : const Value.absent(),
            serviceName: serviceName != null
                ? Value(serviceName)
                : const Value.absent(),
            environment: environment != null
                ? Value(environment)
                : const Value.absent(),
            notes: notes != null ? Value(notes) : const Value.absent(),
            tags: tags != null ? Value(tags) : const Value.absent(),
            folderId: folderId != null ? Value(folderId) : const Value.absent(),
            recordVersion: recordVersion != null
                ? Value(recordVersion)
                : const Value.absent(),
            updatedAt: Value(DateTime.now()),
          ),
        )
        .then((rows) => rows > 0);
  }

  Future<void> recordAccess(int id) {
    return customStatement(
      'UPDATE secrets SET access_count = access_count + 1, last_accessed_at = ? WHERE id = ?',
      [DateTime.now().millisecondsSinceEpoch ~/ 1000, id],
    );
  }

  Future<int> deleteSecret(int id) {
    return (delete(secrets)..where((t) => t.id.equals(id))).go();
  }
}
