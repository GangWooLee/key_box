import 'package:drift/drift.dart';
import 'vaults.dart';
import 'folders.dart';

/// Maps to Rails `secrets` table.
/// Binary columns store AES-256-GCM encrypted data.
class Secrets extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get vaultId => integer().references(Vaults, #id)();
  IntColumn get folderId => integer().references(Folders, #id)();
  TextColumn get name => text().withLength(max: 200)();
  BlobColumn get encryptedValue => blob()();
  BlobColumn get encryptedValueIv => blob()();
  BlobColumn get encryptedValueAuthTag => blob()();
  TextColumn get secretType => text().withDefault(const Constant('api_key'))();
  TextColumn get serviceName => text().withLength(max: 100).nullable()();
  TextColumn get environment => text().withLength(max: 50).nullable()();
  TextColumn get notes => text().withLength(max: 2000).nullable()();
  TextColumn get tags => text().withLength(max: 500).nullable()();

  /// Monotonic per-record version, incremented on every value rotation.
  /// Bound into the AAD (`keybox/v1/secret:<id>:<version>`) so a restored
  /// older ciphertext fails GCM authentication (rollback defense).
  IntColumn get recordVersion => integer().withDefault(const Constant(1))();
  IntColumn get accessCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastAccessedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}
