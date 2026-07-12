import 'dart:typed_data';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:key_box/core/database/database.dart';
import 'package:key_box/core/encryption/key_derivation_service.dart';
import 'package:key_box/core/encryption/master_key_service.dart';
import 'package:key_box/core/encryption/secret_encryption_service.dart';
import 'package:key_box/core/utils/result.dart';
import 'package:key_box/features/auth/domain/auth_notifier.dart';
import 'package:key_box/features/auth/domain/auth_state.dart';
import 'package:key_box/features/secrets/domain/secrets_providers.dart';

void main() {
  late AppDatabase db;
  late ProviderContainer container;
  late int vaultId;
  late int folderId;
  late Uint8List mek;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());

    // Create vault + config + folder
    final vault = await db.vaultDao.create(name: 'Test');
    vaultId = vault.id;
    final kds = KeyDerivationService();
    final mks = MasterKeyService();
    final salt = kds.generateSalt();
    final pdk = kds.deriveKey(password: 'testpass123', salt: salt);
    mek = mks.generateMasterKey();
    final wrappedMek = mks.wrap(masterKey: mek, wrappingKey: pdk);
    await db.vaultConfigDao.create(
      vaultId: vaultId,
      masterKeySalt: salt,
      encryptedMasterKey: wrappedMek,
    );
    final folder = await db.folderDao.create(vaultId: vaultId, name: 'General');
    folderId = folder.id;

    container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        authProvider.overrideWith(
          (ref) => _FakeAuthNotifier(
            AuthUnlocked(masterEncryptionKey: mek, vaultId: vaultId),
          ),
        ),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  group('SecretOperations', () {
    test('create encrypts and stores secret', () async {
      final ops = container.read(secretOpsProvider);
      final result = await ops.create(
        name: 'Stripe API Key',
        value: 'sk_test_abc123',
        folderId: folderId,
        secretType: 'api_key',
        serviceName: 'Stripe',
      );

      expect(result, isA<Success>());
      final secret = (result as Success).data;
      expect(secret.name, equals('Stripe API Key'));
      expect(secret.encryptedValue, isNotEmpty);
    });

    test('create and then decrypt returns original value', () async {
      final ops = container.read(secretOpsProvider);
      await ops.create(
        name: 'My Secret',
        value: 'super-secret-value-123',
        folderId: folderId,
      );

      final secrets = await db.secretDao.getByFolderId(folderId);
      expect(secrets, hasLength(1));

      final decrypted = await ops.decrypt(secrets.first);
      expect(decrypted, equals('super-secret-value-123'));
    });

    test('delete removes secret', () async {
      final ops = container.read(secretOpsProvider);
      final result = await ops.create(
        name: 'To Delete',
        value: 'delete-me',
        folderId: folderId,
      );

      final secret = (result as Success).data;
      final deleteResult = await ops.delete(secret);
      expect(deleteResult, isA<Success>());

      final found = await db.secretDao.getById(secret.id);
      expect(found, isNull);
    });

    test('update re-encrypts value', () async {
      final ops = container.read(secretOpsProvider);
      final result = await ops.create(
        name: 'Updatable',
        value: 'old-value',
        folderId: folderId,
      );

      final secret = (result as Success).data;
      await ops.update(secret.id, value: 'new-value');

      final updated = await db.secretDao.getById(secret.id);
      final decrypted = await ops.decrypt(updated!);
      expect(decrypted, equals('new-value'));
    });

    test('create logs audit event', () async {
      final ops = container.read(secretOpsProvider);
      await ops.create(
        name: 'Audited Secret',
        value: 'value',
        folderId: folderId,
      );

      final events = await db.auditEventDao.getPage(vaultId);
      expect(events.any((e) => e.action == 'secret.create'), isTrue);
    });

    group('AAD binding', () {
      test('create binds the ciphertext to the record identity', () async {
        final ops = container.read(secretOpsProvider);
        await ops.create(name: 'Bound', value: 'aad-bound', folderId: folderId);

        final secret = (await db.secretDao.getByFolderId(folderId)).single;
        expect(secret.recordVersion, equals(1));

        final enc = SecretEncryptionService();
        // Correct identity authenticates…
        expect(
          enc.decrypt(
            encryptedValue: Uint8List.fromList(secret.encryptedValue),
            iv: Uint8List.fromList(secret.encryptedValueIv),
            authTag: Uint8List.fromList(secret.encryptedValueAuthTag),
            key: mek,
            aad: secretAad(secretId: secret.id, recordVersion: 1),
          ),
          equals('aad-bound'),
        );
        // …an unbound (empty-AAD) read does not.
        expect(
          enc.decrypt(
            encryptedValue: Uint8List.fromList(secret.encryptedValue),
            iv: Uint8List.fromList(secret.encryptedValueIv),
            authTag: Uint8List.fromList(secret.encryptedValueAuthTag),
            key: mek,
          ),
          isNull,
        );
      });

      test('update bumps recordVersion and rebinds the AAD', () async {
        final ops = container.read(secretOpsProvider);
        final created = await ops.create(
          name: 'Rotating',
          value: 'v1-value',
          folderId: folderId,
        );
        final id = ((created as Success).data as Secret).id;

        await ops.update(id, value: 'v2-value');

        final row = await db.secretDao.getById(id);
        expect(row!.recordVersion, equals(2));
        expect(await ops.decrypt(row), equals('v2-value'));

        // Rollback mutation: the new ciphertext must not authenticate under
        // the previous version's AAD.
        expect(
          SecretEncryptionService().decrypt(
            encryptedValue: Uint8List.fromList(row.encryptedValue),
            iv: Uint8List.fromList(row.encryptedValueIv),
            authTag: Uint8List.fromList(row.encryptedValueAuthTag),
            key: mek,
            aad: secretAad(secretId: id, recordVersion: 1),
          ),
          isNull,
        );
      });

      test('substitution mutation: record A ciphertext copied into record B '
          'fails decryption', () async {
        final ops = container.read(secretOpsProvider);
        final resultA = await ops.create(
          name: 'A',
          value: 'value-of-A',
          folderId: folderId,
        );
        final resultB = await ops.create(
          name: 'B',
          value: 'value-of-B',
          folderId: folderId,
        );
        final a = (resultA as Success).data as Secret;
        final b = (resultB as Success).data as Secret;

        // Attacker copies A's (ciphertext, iv, tag) over B's row.
        await db.secretDao.updateSecret(
          b.id,
          encryptedValue: Uint8List.fromList(a.encryptedValue),
          encryptedValueIv: Uint8List.fromList(a.encryptedValueIv),
          encryptedValueAuthTag: Uint8List.fromList(a.encryptedValueAuthTag),
        );

        final swapped = await db.secretDao.getById(b.id);
        expect(await ops.decrypt(swapped!), isNull);
      });
    });

    test('reveal logs audit event and records access', () async {
      final ops = container.read(secretOpsProvider);
      final result = await ops.create(
        name: 'Revealed Secret',
        value: 'peek-a-boo',
        folderId: folderId,
      );

      final secret = (result as Success).data;
      final value = await ops.reveal(secret);

      expect(value, equals('peek-a-boo'));

      final events = await db.auditEventDao.getPage(vaultId);
      expect(events.any((e) => e.action == 'secret.read'), isTrue);
    });
  });
}

// Minimal fake notifier for testing
class _FakeAuthNotifier extends AuthNotifier {
  _FakeAuthNotifier(this._initialState) : super(_createDummyDb());

  final AuthState _initialState;
  static AppDatabase _createDummyDb() =>
      AppDatabase.forTesting(NativeDatabase.memory());

  @override
  AuthState get state => _initialState;
}
