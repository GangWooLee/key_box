import 'dart:typed_data';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:key_box/core/database/database.dart';
import 'package:key_box/core/encryption/key_derivation_service.dart';
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
      test(
        'creates vault and transitions to Unlocked with isFirstSetup',
        () async {
          final error = await notifier.setup(
            password: 'testpassword123',
            confirmation: 'testpassword123',
          );

          expect(error, isNull);
          expect(notifier.state, isA<AuthUnlocked>());

          final state = notifier.state as AuthUnlocked;
          expect(state.masterEncryptionKey.length, equals(32));
          expect(state.vaultId, isPositive);
          expect(state.isFirstSetup, isTrue);
        },
      );

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

        expect(error, contains('at least 12'));
        expect(notifier.state, isA<AuthInitial>());
      });

      test('rejects an 11-char password (below the 12-char floor)', () async {
        final error = await notifier.setup(
          password: 'eleven_char', // 11 chars — one below the minimum
          confirmation: 'eleven_char',
        );

        expect(error, contains('at least 12'));
        expect(notifier.state, isA<AuthInitial>());
      });

      test('accepts a 12-char password (at the floor)', () async {
        final error = await notifier.setup(
          password: 'twelve_chars', // exactly 12 chars
          confirmation: 'twelve_chars',
        );

        // No length rejection — setup proceeds to a created vault.
        expect(error, isNull);
        expect(notifier.state, isA<AuthUnlocked>());
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

    group('lock', () {
      test(
        'zeroes the master key in memory to prevent memory-dump extraction',
        () async {
          await notifier.setup(
            password: 'testpassword123',
            confirmation: 'testpassword123',
          );
          final mekRef = (notifier.state as AuthUnlocked).masterEncryptionKey;
          // Sanity: a freshly generated MEK is not already all zeros.
          expect(mekRef.any((b) => b != 0), isTrue);

          notifier.lock();

          expect(notifier.state, isA<AuthLocked>());
          expect(
            mekRef.every((b) => b == 0),
            isTrue,
            reason:
                'lock() must zero the MEK so it cannot be recovered '
                'from a memory dump after locking',
          );
        },
      );
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

      test('unlocks with correct password and isFirstSetup false', () async {
        expect(notifier.state, isA<AuthLocked>());

        final error = await notifier.unlock(password: 'testpassword123');

        expect(error, isNull);
        expect(notifier.state, isA<AuthUnlocked>());
        expect((notifier.state as AuthUnlocked).isFirstSetup, isFalse);
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
          password: 'mypassword12',
          confirmation: 'mypassword12',
        );
        // Snapshot the MEK value (a copy) before locking: lock() now zeroes
        // the live buffer in place, so a plain reference would read back as
        // all-zeros. We assert value equality against the pre-lock snapshot.
        final setupMek = Uint8List.fromList(
          (notifier2.state as AuthUnlocked).masterEncryptionKey,
        );

        notifier2.lock();
        await notifier2.unlock(password: 'mypassword12');

        final unlockMek = (notifier2.state as AuthUnlocked).masterEncryptionKey;
        expect(unlockMek, equals(setupMek));

        await db2.close();
      });

      test('unlocks with special character password', () async {
        final db2 = AppDatabase.forTesting(NativeDatabase.memory());
        final notifier2 = AuthNotifier(db2);

        final error = await notifier2.setup(
          password: 'p@ss!word#123',
          confirmation: 'p@ss!word#123',
        );
        expect(error, isNull);
        expect(notifier2.state, isA<AuthUnlocked>());

        notifier2.lock();

        final unlockError = await notifier2.unlock(password: 'p@ss!word#123');
        expect(unlockError, isNull);
        expect(notifier2.state, isA<AuthUnlocked>());

        await db2.close();
      });

      test('unlocks with symbols and mixed case password', () async {
        final db2 = AppDatabase.forTesting(NativeDatabase.memory());
        final notifier2 = AuthNotifier(db2);

        const pwd = r'C0mpl3x!@#$%^&*()_+-=[]{}';
        final error = await notifier2.setup(password: pwd, confirmation: pwd);
        expect(error, isNull);

        notifier2.lock();

        final unlockError = await notifier2.unlock(password: pwd);
        expect(unlockError, isNull);
        expect(notifier2.state, isA<AuthUnlocked>());

        await db2.close();
      });

      test('unlock with new notifier simulates app restart', () async {
        // notifier already has a vault set up and is locked (from group setUp)
        // Create a fresh notifier on the same DB to simulate restart
        final notifier2 = AuthNotifier(db);
        await notifier2.initialize();
        expect(notifier2.state, isA<AuthLocked>());

        final error = await notifier2.unlock(password: 'testpassword123');
        expect(error, isNull);
        expect(notifier2.state, isA<AuthUnlocked>());
      });
    });

    group('completeOnboarding', () {
      test('clears isFirstSetup flag', () async {
        await notifier.setup(
          password: 'testpassword123',
          confirmation: 'testpassword123',
        );
        expect((notifier.state as AuthUnlocked).isFirstSetup, isTrue);

        notifier.completeOnboarding();

        expect(notifier.state, isA<AuthUnlocked>());
        final state = notifier.state as AuthUnlocked;
        expect(state.isFirstSetup, isFalse);
      });

      test('preserves MEK and vaultId', () async {
        await notifier.setup(
          password: 'testpassword123',
          confirmation: 'testpassword123',
        );
        final before = notifier.state as AuthUnlocked;

        notifier.completeOnboarding();

        final after = notifier.state as AuthUnlocked;
        expect(after.masterEncryptionKey, equals(before.masterEncryptionKey));
        expect(after.vaultId, equals(before.vaultId));
      });

      test('no-op when not in first setup', () async {
        await notifier.setup(
          password: 'testpassword123',
          confirmation: 'testpassword123',
        );
        notifier.completeOnboarding();
        final state1 = notifier.state as AuthUnlocked;

        // Calling again should be a no-op
        notifier.completeOnboarding();
        expect(identical(notifier.state, state1), isTrue);
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

  group('KeyDerivationService', () {
    final kds = KeyDerivationService();

    test('produces consistent PDK for same password and salt', () {
      final salt = kds.generateSalt();
      final pdk1 = kds.deriveKey(password: 'test!@#', salt: salt);
      final pdk2 = kds.deriveKey(password: 'test!@#', salt: salt);
      expect(pdk1, equals(pdk2));
    });

    test('produces different PDK for different passwords', () {
      final salt = kds.generateSalt();
      final pdk1 = kds.deriveKey(password: 'password1!', salt: salt);
      final pdk2 = kds.deriveKey(password: 'password2!', salt: salt);
      expect(pdk1, isNot(equals(pdk2)));
    });

    test('produces different PDK for different salts', () {
      final salt1 = kds.generateSalt();
      final salt2 = kds.generateSalt();
      final pdk1 = kds.deriveKey(password: 'same_pass!', salt: salt1);
      final pdk2 = kds.deriveKey(password: 'same_pass!', salt: salt2);
      expect(pdk1, isNot(equals(pdk2)));
    });

    test('derives 32-byte key', () {
      final salt = kds.generateSalt();
      final pdk = kds.deriveKey(password: 'test_pass!', salt: salt);
      expect(pdk.length, equals(32));
      expect(pdk, isA<Uint8List>());
    });
  });
}
