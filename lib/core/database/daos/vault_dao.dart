import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/vaults.dart';

part 'vault_dao.g.dart';

@DriftAccessor(tables: [Vaults])
class VaultDao extends DatabaseAccessor<AppDatabase> with _$VaultDaoMixin {
  VaultDao(super.db);

  Future<Vault> create({required String name, String? description}) {
    final now = DateTime.now();
    return into(vaults).insertReturning(
      VaultsCompanion.insert(
        name: name,
        description: Value(description),
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  Future<Vault?> getFirst() {
    return (select(vaults)..limit(1)).getSingleOrNull();
  }

  Future<List<Vault>> getAll() {
    return select(vaults).get();
  }
}
