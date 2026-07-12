import 'package:drift/drift.dart';
import 'vaults.dart';

/// Stores the wrapped MEK and salt for vault unlock.
/// Password verification happens via MEK unwrap (GCM auth), so no separate
/// password digest is stored (the legacy column was dropped in schema v3).
class VaultConfigs extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get vaultId => integer().unique().references(Vaults, #id)();
  BlobColumn get masterKeySalt => blob()(); // 32 bytes
  BlobColumn get encryptedMasterKey =>
      blob()(); // 60 bytes (IV + AuthTag + Ciphertext)
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}
