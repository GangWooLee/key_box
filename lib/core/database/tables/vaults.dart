import 'package:drift/drift.dart';

/// Maps to Rails `vaults` table (minus vault_type — always personal for desktop).
class Vaults extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(max: 100)();
  TextColumn get description => text().withLength(max: 500).nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}
