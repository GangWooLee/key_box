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
    required String masterPasswordDigest,
  }) {
    final now = DateTime.now();
    return into(vaultConfigs).insertReturning(VaultConfigsCompanion.insert(
      vaultId: vaultId,
      masterKeySalt: masterKeySalt,
      encryptedMasterKey: encryptedMasterKey,
      masterPasswordDigest: masterPasswordDigest,
      createdAt: now,
      updatedAt: now,
    ));
  }

  Future<VaultConfig?> getByVaultId(int vaultId) {
    return (select(vaultConfigs)..where((t) => t.vaultId.equals(vaultId)))
        .getSingleOrNull();
  }

  Future<bool> exists() async {
    final count = await (selectOnly(vaultConfigs)
          ..addColumns([vaultConfigs.id.count()]))
        .map((row) => row.read(vaultConfigs.id.count()))
        .getSingle();
    return (count ?? 0) > 0;
  }
}
