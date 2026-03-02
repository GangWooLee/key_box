import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:key_box/core/database/database.dart';
import 'package:key_box/features/auth/domain/auth_notifier.dart';
import 'package:key_box/features/auth/domain/auth_state.dart';

void main() {
  late AppDatabase db;
  late AuthNotifier notifier;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    notifier = AuthNotifier(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('AuthNotifier', () {
    group('initialize', () {
      test('transitions to FirstRun when no config exists', () async {
        await notifier.initialize();
        expect(notifier.state, isA<AuthFirstRun>());
      });
    });

    group('setup', () {
      test('creates vault and transitions to Unlocked', () async {
        final error = await notifier.setup(
          password: 'testpassword123',
          confirmation: 'testpassword123',
        );

        expect(error, isNull);
        expect(notifier.state, isA<AuthUnlocked>());

        final state = notifier.state as AuthUnlocked;
        expect(state.masterEncryptionKey.length, equals(32));
        expect(state.vaultId, isPositive);
      });

      test('rejects mismatched passwords', () async {
        final error = await notifier.setup(
          password: 'password123',
          confirmation: 'different123',
        );

        expect(error, equals('Passwords do not match'));
        expect(notifier.state, isA<AuthInitial>());
      });

      test('rejects short password', () async {
        final error = await notifier.setup(
          password: 'short',
          confirmation: 'short',
        );

        expect(error, contains('at least 8'));
        expect(notifier.state, isA<AuthInitial>());
      });

      test('creates default General folder', () async {
        await notifier.setup(
          password: 'testpassword123',
          confirmation: 'testpassword123',
        );

        final state = notifier.state as AuthUnlocked;
        final folders = await db.folderDao.getByVaultId(state.vaultId);
        expect(folders.length, equals(1));
        expect(folders.first.name, equals('General'));
      });
    });

    group('unlock', () {
      setUp(() async {
        // First set up a vault
        await notifier.setup(
          password: 'testpassword123',
          confirmation: 'testpassword123',
        );
        // Lock it
        notifier.lock();
      });

      test('unlocks with correct password', () async {
        expect(notifier.state, isA<AuthLocked>());

        final error = await notifier.unlock(password: 'testpassword123');

        expect(error, isNull);
        expect(notifier.state, isA<AuthUnlocked>());
      });

      test('rejects wrong password', () async {
        final error = await notifier.unlock(password: 'wrongpassword');

        expect(error, equals('Incorrect password'));
        expect(notifier.state, isA<AuthLocked>());
      });

      test('recovers same MEK after unlock', () async {
        // Store the MEK from setup before locking
        // (We already locked in setUp, so setup again)
        final db2 = AppDatabase.forTesting(NativeDatabase.memory());
        final notifier2 = AuthNotifier(db2);

        await notifier2.setup(
          password: 'mypassword',
          confirmation: 'mypassword',
        );
        final setupMek = (notifier2.state as AuthUnlocked).masterEncryptionKey;

        notifier2.lock();
        await notifier2.unlock(password: 'mypassword');

        final unlockMek = (notifier2.state as AuthUnlocked).masterEncryptionKey;
        expect(unlockMek, equals(setupMek));

        await db2.close();
      });
    });

    group('lock', () {
      test('transitions from Unlocked to Locked', () async {
        await notifier.setup(
          password: 'testpassword123',
          confirmation: 'testpassword123',
        );
        expect(notifier.state, isA<AuthUnlocked>());

        notifier.lock();
        expect(notifier.state, isA<AuthLocked>());
      });
    });

    group('initialize after setup', () {
      test('transitions to Locked when config exists', () async {
        await notifier.setup(
          password: 'testpassword123',
          confirmation: 'testpassword123',
        );

        // Simulate app restart with a new notifier on the same DB
        final notifier2 = AuthNotifier(db);
        await notifier2.initialize();
        expect(notifier2.state, isA<AuthLocked>());
      });
    });
  });
}
