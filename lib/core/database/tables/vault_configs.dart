import 'package:drift/drift.dart';
import 'vaults.dart';

/// Maps to Rails `vault_configs` table.
/// Stores the wrapped MEK, salt, and password hash for vault unlock.
class VaultConfigs extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get vaultId => integer().unique().references(Vaults, #id)();
  BlobColumn get masterKeySalt => blob()(); // 32 bytes
  BlobColumn get encryptedMasterKey => blob()(); // 60 bytes (IV + AuthTag + Ciphertext)
  TextColumn get masterPasswordDigest => text()(); // BCrypt hash
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}
