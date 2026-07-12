import 'package:drift/drift.dart';
import 'folders.dart';
import 'secrets.dart';

/// M:N join table linking secrets to folders.
/// A secret can belong to multiple folders simultaneously.
class FolderSecrets extends Table {
  IntColumn get folderId => integer().references(Folders, #id)();
  IntColumn get secretId => integer().references(Secrets, #id)();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {folderId, secretId};
}
