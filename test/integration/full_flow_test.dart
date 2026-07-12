import 'dart:typed_data';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:key_box/core/database/database.dart';
import 'package:key_box/core/encryption/secret_encryption_service.dart';
import 'package:key_box/core/vault/sidecar_store.dart';
import 'package:key_box/features/auth/domain/auth_notifier.dart';
import 'package:key_box/features/auth/domain/auth_state.dart';

void main() {
  group('Full flow integration', () {
    late AppDatabase db;
    late AuthNotifier notifier;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      notifier = AuthNotifier(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('Setup → Create Secret → Reveal → Lock → Unlock → Verify', () async {
      // 1. Setup vault
      final setupError = await notifier.setup(
        password: 'integration-test-pw123',
        confirmation: 'integration-test-pw123',
      );
      expect(setupError, isNull);
      expect(notifier.state, isA<AuthUnlocked>());

      final auth1 = notifier.state as AuthUnlocked;
      final crypto = SecretEncryptionService();

      // 2. Create a folder
      final folder = await db.folderDao.create(
        vaultId: auth1.vaultId,
        name: 'Test Folder',
      );
      expect(folder.name, 'Test Folder');

      // 3. Encrypt and store a secret
      const secretValue = 'super-secret-api-key-12345';
      final encrypted = crypto.encrypt(
        value: secretValue,
        key: auth1.masterEncryptionKey,
      );
      final secret = await db.secretDao.create(
        vaultId: auth1.vaultId,
        folderId: folder.id,
        name: 'My API Key',
        encryptedValue: encrypted.encryptedValue,
        encryptedValueIv: encrypted.iv,
        encryptedValueAuthTag: encrypted.authTag,
        secretType: 'api_key',
        serviceName: 'GitHub',
      );
      expect(secret.name, 'My API Key');

      // 4. Reveal the secret
      final revealed = crypto.decrypt(
        encryptedValue: Uint8List.fromList(secret.encryptedValue),
        iv: Uint8List.fromList(secret.encryptedValueIv),
        authTag: Uint8List.fromList(secret.encryptedValueAuthTag),
        key: auth1.masterEncryptionKey,
      );
      expect(revealed, secretValue);

      // 5. Lock
      notifier.lock();
      expect(notifier.state, isA<AuthLocked>());

      // 6. Unlock
      final unlockError = await notifier.unlock(
        password: 'integration-test-pw123',
      );
      expect(unlockError, isNull);
      expect(notifier.state, isA<AuthUnlocked>());

      final auth2 = notifier.state as AuthUnlocked;

      // 7. Verify the secret is still accessible after unlock
      final storedSecret = await db.secretDao.getById(secret.id);
      expect(storedSecret, isNotNull);
      expect(storedSecret!.name, 'My API Key');

      final revealed2 = crypto.decrypt(
        encryptedValue: Uint8List.fromList(storedSecret.encryptedValue),
        iv: Uint8List.fromList(storedSecret.encryptedValueIv),
        authTag: Uint8List.fromList(storedSecret.encryptedValueAuthTag),
        key: auth2.masterEncryptionKey,
      );
      expect(revealed2, secretValue);

      // 8. Verify audit trail
      final events = await db.auditEventDao.getPage(auth2.vaultId);
      expect(events, isNotEmpty);
      expect(events.any((e) => e.action == 'vault.setup'), isTrue);
    });

    test('wrong password fails to unlock', () async {
      await notifier.setup(
        password: 'correct-password123',
        confirmation: 'correct-password123',
      );
      notifier.lock();

      final error = await notifier.unlock(password: 'wrong-password');
      expect(error, isNotNull);
      expect(notifier.state, isA<AuthLocked>());
    });

    test('secret update re-encrypts value', () async {
      await notifier.setup(
        password: 'updatetest123',
        confirmation: 'updatetest123',
      );
      final auth = notifier.state as AuthUnlocked;
      final crypto = SecretEncryptionService();

      final folder = await db.folderDao.create(
        vaultId: auth.vaultId,
        name: 'Folder',
      );

      // Create original secret
      const original = 'original-value';
      final enc1 = crypto.encrypt(
        value: original,
        key: auth.masterEncryptionKey,
      );
      final secret = await db.secretDao.create(
        vaultId: auth.vaultId,
        folderId: folder.id,
        name: 'Updatable',
        encryptedValue: enc1.encryptedValue,
        encryptedValueIv: enc1.iv,
        encryptedValueAuthTag: enc1.authTag,
      );

      // Update with new value
      const updated = 'new-updated-value';
      final enc2 = crypto.encrypt(
        value: updated,
        key: auth.masterEncryptionKey,
      );
      await db.secretDao.updateSecret(
        secret.id,
        name: 'Updated Secret',
        encryptedValue: enc2.encryptedValue,
        encryptedValueIv: enc2.iv,
        encryptedValueAuthTag: enc2.authTag,
      );

      // Verify update
      final fetched = await db.secretDao.getById(secret.id);
      expect(fetched!.name, 'Updated Secret');

      final decrypted = crypto.decrypt(
        encryptedValue: Uint8List.fromList(fetched.encryptedValue),
        iv: Uint8List.fromList(fetched.encryptedValueIv),
        authTag: Uint8List.fromList(fetched.encryptedValueAuthTag),
        key: auth.masterEncryptionKey,
      );
      expect(decrypted, updated);
    });

    test('secret deletion removes from database', () async {
      await notifier.setup(
        password: 'deletetest123',
        confirmation: 'deletetest123',
      );
      final auth = notifier.state as AuthUnlocked;
      final crypto = SecretEncryptionService();

      final folder = await db.folderDao.create(
        vaultId: auth.vaultId,
        name: 'Folder',
      );

      final enc = crypto.encrypt(
        value: 'to-delete',
        key: auth.masterEncryptionKey,
      );
      final secret = await db.secretDao.create(
        vaultId: auth.vaultId,
        folderId: folder.id,
        name: 'Deletable',
        encryptedValue: enc.encryptedValue,
        encryptedValueIv: enc.iv,
        encryptedValueAuthTag: enc.authTag,
      );

      await db.secretDao.deleteSecret(secret.id);

      final fetched = await db.secretDao.getById(secret.id);
      expect(fetched, isNull);
    });

    test('legacy healing: lost sidecar is regenerated from the DB, then '
        'unlock succeeds', () async {
      // Session 1: normal setup writes the sidecar.
      final sidecar1 = InMemorySidecarStore();
      final notifier1 = AuthNotifier(db, sidecar: sidecar1);
      await notifier1.setup(
        password: 'healing-test-pw123',
        confirmation: 'healing-test-pw123',
      );
      expect(await sidecar1.read(), isA<SidecarFound>());

      // Session 2: the sidecar file was lost (pre-sidecar install, manual
      // deletion) — boot must heal it from the plaintext DB, not error out.
      final sidecar2 = InMemorySidecarStore();
      final notifier2 = AuthNotifier(db, sidecar: sidecar2);
      await notifier2.initialize();
      expect(notifier2.state, isA<AuthLocked>());

      final healed = await sidecar2.read();
      expect(healed, isA<SidecarFound>());
      final vault = await db.vaultDao.getFirst();
      final config = await db.vaultConfigDao.getByVaultId(vault!.id);
      expect((healed as SidecarFound).salt, equals(config!.masterKeySalt));

      // The healed sidecar salt must actually unlock the vault.
      final unlockError = await notifier2.unlock(
        password: 'healing-test-pw123',
      );
      expect(unlockError, isNull);
      expect(notifier2.state, isA<AuthUnlocked>());
    });

    test('search finds secrets by name', () async {
      await notifier.setup(
        password: 'searchtest123',
        confirmation: 'searchtest123',
      );
      final auth = notifier.state as AuthUnlocked;
      final crypto = SecretEncryptionService();

      final folder = await db.folderDao.create(
        vaultId: auth.vaultId,
        name: 'Folder',
      );

      for (final name in ['GitHub Token', 'AWS Key', 'Stripe Secret']) {
        final enc = crypto.encrypt(value: 'val', key: auth.masterEncryptionKey);
        await db.secretDao.create(
          vaultId: auth.vaultId,
          folderId: folder.id,
          name: name,
          encryptedValue: enc.encryptedValue,
          encryptedValueIv: enc.iv,
          encryptedValueAuthTag: enc.authTag,
        );
      }

      final results = await db.secretDao.search(auth.vaultId, 'Git');
      expect(results.length, 1);
      expect(results.first.name, 'GitHub Token');

      final allResults = await db.secretDao.search(auth.vaultId, 'e');
      expect(allResults.length, greaterThanOrEqualTo(2));
    });
  });
}
