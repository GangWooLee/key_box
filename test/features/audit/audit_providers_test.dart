import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:key_box/core/database/database.dart';
import 'package:key_box/features/auth/domain/auth_notifier.dart';
import 'package:key_box/features/auth/domain/auth_state.dart';
import 'package:key_box/features/audit/domain/audit_providers.dart';

void main() {
  group('AuditProviders', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    test('returns empty list when not authenticated', () async {
      final container = ProviderContainer(
        overrides: [databaseProvider.overrideWithValue(db)],
      );
      addTearDown(container.dispose);

      final events = await container.read(auditEventsProvider.future);
      expect(events, isEmpty);
    });

    test('returns events when authenticated', () async {
      // Setup vault
      final notifier = AuthNotifier(db);
      await notifier.setup(
        password: 'testpassword123',
        confirmation: 'testpassword123',
      );
      final auth = notifier.state as AuthUnlocked;

      // Create some audit events
      await db.auditEventDao.create(
        vaultId: auth.vaultId,
        action: 'secret.create',
        metadata: '{"name":"test"}',
      );
      await db.auditEventDao.create(
        vaultId: auth.vaultId,
        action: 'secret.read',
        metadata: '{"name":"test"}',
      );

      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          authProvider.overrideWith((ref) => notifier),
        ],
      );
      addTearDown(container.dispose);

      final events = await container.read(auditEventsProvider.future);
      // vault.setup (1) + 2 manual events = 3
      expect(events.length, greaterThanOrEqualTo(2));
    });

    test(
      're-fetches fresh events on re-entry (autoDispose freshness)',
      () async {
        final notifier = AuthNotifier(db);
        await notifier.setup(
          password: 'testpassword123',
          confirmation: 'testpassword123',
        );
        final auth = notifier.state as AuthUnlocked;
        final container = ProviderContainer(
          overrides: [
            databaseProvider.overrideWithValue(db),
            authProvider.overrideWith((ref) => notifier),
          ],
        );
        addTearDown(container.dispose);

        // First view of the audit screen.
        final sub1 = container.listen(auditEventsProvider, (_, __) {});
        final first = await container.read(auditEventsProvider.future);
        sub1.close(); // leave the screen → autoDispose drops the cached page
        await Future<void>.delayed(Duration.zero);

        // A new event is logged while away.
        await db.auditEventDao.create(
          vaultId: auth.vaultId,
          action: 'secret.read',
        );

        // Re-enter → a fresh fetch includes the new event.
        final sub2 = container.listen(auditEventsProvider, (_, __) {});
        addTearDown(sub2.close);
        final second = await container.read(auditEventsProvider.future);
        expect(
          second.length,
          greaterThan(first.length),
          reason:
              'autoDispose re-fetches on re-entry, showing events logged away',
        );
      },
    );

    test('page provider defaults to 0', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(auditPageProvider), 0);
    });

    test('page provider can be incremented', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(auditPageProvider.notifier).state = 1;
      expect(container.read(auditPageProvider), 1);
    });
  });
}
