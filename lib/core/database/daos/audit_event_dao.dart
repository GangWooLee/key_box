import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/audit_events.dart';
import '../../constants/app_constants.dart';

part 'audit_event_dao.g.dart';

@DriftAccessor(tables: [AuditEvents])
class AuditEventDao extends DatabaseAccessor<AppDatabase>
    with _$AuditEventDaoMixin {
  AuditEventDao(super.db);

  Future<AuditEvent> create({
    required int vaultId,
    required String action,
    int? secretId,
    String? metadata,
  }) {
    return into(auditEvents).insertReturning(
      AuditEventsCompanion.insert(
        vaultId: vaultId,
        action: action,
        secretId: Value(secretId),
        metadata: Value(metadata),
        createdAt: DateTime.now(),
      ),
    );
  }

  Future<List<AuditEvent>> getPage(int vaultId, {int page = 0, int? limit}) {
    final pageSize = limit ?? AppConstants.auditPageSize;
    return (select(auditEvents)
          ..where((t) => t.vaultId.equals(vaultId))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
          ..limit(pageSize, offset: page * pageSize))
        .get();
  }

  Stream<List<AuditEvent>> watchRecent(int vaultId, {int limit = 20}) {
    return (select(auditEvents)
          ..where((t) => t.vaultId.equals(vaultId))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
          ..limit(limit))
        .watch();
  }
}
