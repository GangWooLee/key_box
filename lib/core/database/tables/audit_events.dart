import 'package:drift/drift.dart';
import 'vaults.dart';
import 'secrets.dart';

/// Maps to Rails `audit_events` table (simplified for desktop).
/// Removed: ip_address, user_agent, user_id (no multi-user, no web).
class AuditEvents extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get vaultId => integer().references(Vaults, #id)();
  IntColumn get secretId => integer().nullable().references(Secrets, #id)();
  TextColumn get action => text().withLength(max: 50)();
  TextColumn get metadata => text().nullable()(); // JSON string
  DateTimeColumn get createdAt => dateTime()();
}
