import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/database/database.dart';
import '../../auth/domain/auth_notifier.dart';
import '../../auth/domain/auth_state.dart';

final auditPageProvider = StateProvider<int>((ref) => 0);

// autoDispose so leaving and re-entering the audit screen re-fetches: a plain
// one-shot FutureProvider caches the first page forever, hiding events logged
// after the first view until an app restart.
final auditEventsProvider = FutureProvider.autoDispose<List<AuditEvent>>((
  ref,
) async {
  final auth = ref.watch(authProvider);
  if (auth is! AuthUnlocked) return [];
  final db = ref.read(databaseProvider);
  final page = ref.watch(auditPageProvider);

  // Single query with limit=(page+1)*pageSize from offset 0,
  // instead of O(n²) loop re-querying all previous pages.
  return db.auditEventDao.getPage(
    auth.vaultId,
    limit: (page + 1) * AppConstants.auditPageSize,
  );
});
