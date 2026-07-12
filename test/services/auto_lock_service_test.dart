import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:key_box/core/database/database.dart';
import 'package:key_box/features/auth/domain/auth_notifier.dart';
import 'package:key_box/services/auto_lock_service.dart';

void main() {
  group('AutoLockService', () {
    late AppDatabase db;
    late ProviderContainer container;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      container = ProviderContainer(
        overrides: [databaseProvider.overrideWithValue(db)],
      );
    });

    tearDown(() async {
      container.dispose();
      await db.close();
    });

    test('service is created from provider', () {
      final service = container.read(autoLockProvider);
      expect(service, isA<AutoLockService>());
    });

    test('start and stop do not throw', () {
      final service = container.read(autoLockProvider);
      service.start();
      service.recordActivity();
      service.stop();
    });

    test('recordActivity resets timer without error', () {
      final service = container.read(autoLockProvider);
      service.start();
      service.recordActivity();
      service.recordActivity();
      service.stop();
    });

    test('stop cancels pending timer', () {
      final service = container.read(autoLockProvider);
      service.start();
      service.stop();
      // Should not throw after stop
      service.stop();
    });
  });
}
