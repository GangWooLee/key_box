import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:key_box/core/database/database.dart';
import 'package:key_box/core/database/vault_paths.dart';
import 'package:key_box/features/auth/domain/auth_notifier.dart';

import '../../helpers/test_helpers.dart';
import '../../helpers/widget_test_helpers.dart';

/// Records close() so dispose behavior is observable without racy queries.
class _ProbeDb extends AppDatabase {
  _ProbeDb(super.e) : super.forTesting();

  bool closed = false;

  @override
  Future<void> close() {
    closed = true;
    return super.close();
  }
}

void main() {
  late Directory tempDir;
  late Future<Directory> Function() originalSupportDir;

  setUp(() {
    suppressDriftWarning();
    tempDir = Directory.systemTemp.createTempSync('database_provider_test');
    originalSupportDir = VaultPaths.supportDir;
    VaultPaths.supportDir = () async => tempDir;
  });

  tearDown(() {
    VaultPaths.supportDir = originalSupportDir;
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('databaseProvider — lazy holder', () {
    test('1. read before unlock throws StateError', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(() => container.read(databaseProvider), throwsStateError);
    });

    test('2. the pre-unlock error is not cached: read after holder set '
        'returns the instance', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // First read throws...
      expect(() => container.read(databaseProvider), throwsStateError);

      // ...then the holder is filled (unlock) and the SAME container
      // must now resolve successfully.
      final db = createTestDatabase();
      container.read(databaseHolderProvider.notifier).state = db;

      expect(container.read(databaseProvider), same(db));
    });

    test('3. legacy overrideWithValue pattern bypasses the holder', () {
      final db = createTestDatabase();
      addTearDown(db.close);
      final container = createTestContainer(db: db);
      addTearDown(container.dispose);

      expect(container.read(databaseProvider), same(db));
      expect(container.read(databaseHolderProvider), isNull);
    });

    test('4. container dispose closes the held database', () {
      final probe = _ProbeDb(NativeDatabase.memory());
      final container = ProviderContainer();

      container.read(databaseHolderProvider.notifier).state = probe;
      expect(probe.closed, isFalse);

      container.dispose();

      expect(probe.closed, isTrue);
    });
  });

  group('authProvider — lazy wiring', () {
    test(
      '5. creating authProvider opens no DB; setup fills the holder',
      () async {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        // Creating the notifier must be IO-free: holder stays empty.
        container.read(authProvider);
        expect(container.read(databaseHolderProvider), isNull);

        final error = await container
            .read(authProvider.notifier)
            .setup(password: 'testpass1234', confirmation: 'testpass1234');

        expect(error, isNull);
        expect(container.read(databaseHolderProvider), isNotNull);
        // The real FileSidecarStore wrote next to the DB.
        expect(
          File('${tempDir.path}/${VaultPaths.sidecarFileName}').existsSync(),
          isTrue,
        );
      },
    );

    test(
      '6. reset then setup in the same session succeeds with a fresh DB',
      () async {
        // Regression for the closed-DB-in-holder gap: reset closes the DB, so
        // the openDatabase closure must not hand the stale instance back to
        // the next setup.
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final notifier = container.read(authProvider.notifier);
        expect(
          await notifier.setup(
            password: 'testpass1234',
            confirmation: 'testpass1234',
          ),
          isNull,
        );

        await notifier.resetAndReinitialize();
        expect(container.read(databaseHolderProvider), isNull);

        expect(
          await notifier.setup(
            password: 'testpass2345',
            confirmation: 'testpass2345',
          ),
          isNull,
        );
        expect(container.read(databaseHolderProvider), isNotNull);
      },
    );
  });
}
