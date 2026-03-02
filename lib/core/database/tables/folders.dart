import 'package:drift/drift.dart';
import 'vaults.dart';

/// Maps to Rails `folders` table.
class Folders extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get vaultId => integer().references(Vaults, #id)();
  TextColumn get name => text().withLength(max: 100)();
  TextColumn get icon => text().withLength(max: 50).withDefault(const Constant('folder'))();
  IntColumn get position => integer().withDefault(const Constant(0))();
  IntColumn get secretsCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  List<Set<Column>> get uniqueKeys => [
        {vaultId, name},
      ];
}
