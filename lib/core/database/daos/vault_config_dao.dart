import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/vault_configs.dart';

part 'vault_config_dao.g.dart';

@DriftAccessor(tables: [VaultConfigs])
class VaultConfigDao extends DatabaseAccessor<AppDatabase>
    with _$VaultConfigDaoMixin {
  VaultConfigDao(super.db);

  Future<VaultConfig> create({
    required int vaultId,
    required Uint8List masterKeySalt,
    required Uint8List encryptedMasterKey,
  }) {
    final now = DateTime.now();
    return into(vaultConfigs).insertReturning(
      VaultConfigsCompanion.insert(
        vaultId: vaultId,
        masterKeySalt: masterKeySalt,
        encryptedMasterKey: encryptedMasterKey,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  /// Commits a key rotation: the KEK-wrapped MEK and the salt it derives
  /// from change together — they are one logical unit (see changePassword).
  Future<bool> updateKeyMaterial({
    required int vaultId,
    required Uint8List masterKeySalt,
    required Uint8List encryptedMasterKey,
  }) {
    return (update(vaultConfigs)..where((t) => t.vaultId.equals(vaultId)))
        .write(
          VaultConfigsCompanion(
            masterKeySalt: Value(masterKeySalt),
            encryptedMasterKey: Value(encryptedMasterKey),
            updatedAt: Value(DateTime.now()),
          ),
        )
        .then((rows) => rows > 0);
  }

  Future<VaultConfig?> getByVaultId(int vaultId) {
    return (select(
      vaultConfigs,
    )..where((t) => t.vaultId.equals(vaultId))).getSingleOrNull();
  }

  Future<bool> exists() async {
    final count =
        await (selectOnly(vaultConfigs)..addColumns([vaultConfigs.id.count()]))
            .map((row) => row.read(vaultConfigs.id.count()))
            .getSingle();
    return (count ?? 0) > 0;
  }
}
