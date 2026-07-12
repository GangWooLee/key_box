import 'dart:typed_data';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:key_box/core/database/database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('VaultDao', () {
    test('creates a vault', () async {
      final vault = await db.vaultDao.create(name: 'Personal');
      expect(vault.name, equals('Personal'));
      expect(vault.id, isPositive);
    });

    test('getFirst returns null when empty', () async {
      final vault = await db.vaultDao.getFirst();
      expect(vault, isNull);
    });

    test('getFirst returns the first vault', () async {
      await db.vaultDao.create(name: 'First');
      await db.vaultDao.create(name: 'Second');
      final vault = await db.vaultDao.getFirst();
      expect(vault!.name, equals('First'));
    });
  });

  group('VaultConfigDao', () {
    test('creates and retrieves config', () async {
      final vault = await db.vaultDao.create(name: 'Test');
      final config = await db.vaultConfigDao.create(
        vaultId: vault.id,
        masterKeySalt: Uint8List.fromList(List.filled(32, 0x42)),
        encryptedMasterKey: Uint8List.fromList(List.filled(60, 0xAA)),
      );

      expect(config.vaultId, equals(vault.id));
      expect(config.masterKeySalt.length, equals(32));
      expect(config.encryptedMasterKey.length, equals(60));
    });

    test('getByVaultId returns config', () async {
      final vault = await db.vaultDao.create(name: 'Test');
      await db.vaultConfigDao.create(
        vaultId: vault.id,
        masterKeySalt: Uint8List.fromList(List.filled(32, 0x42)),
        encryptedMasterKey: Uint8List.fromList(List.filled(60, 0xAA)),
      );

      final config = await db.vaultConfigDao.getByVaultId(vault.id);
      expect(config, isNotNull);
      expect(config!.vaultId, equals(vault.id));
    });

    test('exists returns false when empty', () async {
      expect(await db.vaultConfigDao.exists(), isFalse);
    });

    test('exists returns true when config exists', () async {
      final vault = await db.vaultDao.create(name: 'Test');
      await db.vaultConfigDao.create(
        vaultId: vault.id,
        masterKeySalt: Uint8List.fromList(List.filled(32, 0x42)),
        encryptedMasterKey: Uint8List.fromList(List.filled(60, 0xAA)),
      );
      expect(await db.vaultConfigDao.exists(), isTrue);
    });
  });

  group('FolderDao', () {
    late int vaultId;

    setUp(() async {
      final vault = await db.vaultDao.create(name: 'Test');
      vaultId = vault.id;
    });

    test('creates a folder', () async {
      final folder = await db.folderDao.create(
        vaultId: vaultId,
        name: 'General',
      );
      expect(folder.name, equals('General'));
      expect(folder.icon, equals('folder'));
      expect(folder.position, equals(0));
      expect(folder.secretsCount, equals(0));
    });

    test('getByVaultId returns folders ordered by position', () async {
      await db.folderDao.create(vaultId: vaultId, name: 'B', position: 2);
      await db.folderDao.create(vaultId: vaultId, name: 'A', position: 1);
      await db.folderDao.create(vaultId: vaultId, name: 'C', position: 0);

      final folders = await db.folderDao.getByVaultId(vaultId);
      expect(folders.map((f) => f.name).toList(), equals(['C', 'A', 'B']));
    });

    test('updateFolder changes name', () async {
      final folder = await db.folderDao.create(
        vaultId: vaultId,
        name: 'Old Name',
      );
      final updated = await db.folderDao.updateFolder(
        folder.id,
        name: 'New Name',
      );
      expect(updated, isTrue);
    });

    test('deleteFolder removes folder', () async {
      final folder = await db.folderDao.create(
        vaultId: vaultId,
        name: 'To Delete',
      );
      await db.folderDao.deleteFolder(folder.id);
      final folders = await db.folderDao.getByVaultId(vaultId);
      expect(folders, isEmpty);
    });
  });

  group('SecretDao', () {
    late int vaultId;
    late int folderId;

    setUp(() async {
      final vault = await db.vaultDao.create(name: 'Test');
      vaultId = vault.id;
      final folder = await db.folderDao.create(
        vaultId: vaultId,
        name: 'General',
      );
      folderId = folder.id;
    });

    test('creates a secret', () async {
      final secret = await db.secretDao.create(
        vaultId: vaultId,
        folderId: folderId,
        name: 'API Key',
        encryptedValue: Uint8List.fromList(List.filled(20, 0x01)),
        encryptedValueIv: Uint8List.fromList(List.filled(12, 0x02)),
        encryptedValueAuthTag: Uint8List.fromList(List.filled(16, 0x03)),
        secretType: 'api_key',
        serviceName: 'Stripe',
      );

      expect(secret.name, equals('API Key'));
      expect(secret.secretType, equals('api_key'));
      expect(secret.serviceName, equals('Stripe'));
      expect(secret.accessCount, equals(0));
    });

    test('getById returns secret', () async {
      final created = await db.secretDao.create(
        vaultId: vaultId,
        folderId: folderId,
        name: 'Test Secret',
        encryptedValue: Uint8List.fromList(List.filled(10, 0x01)),
        encryptedValueIv: Uint8List.fromList(List.filled(12, 0x02)),
        encryptedValueAuthTag: Uint8List.fromList(List.filled(16, 0x03)),
      );

      final found = await db.secretDao.getById(created.id);
      expect(found, isNotNull);
      expect(found!.name, equals('Test Secret'));
    });

    test('search finds by name', () async {
      await db.secretDao.create(
        vaultId: vaultId,
        folderId: folderId,
        name: 'Stripe API Key',
        encryptedValue: Uint8List.fromList(List.filled(10, 0x01)),
        encryptedValueIv: Uint8List.fromList(List.filled(12, 0x02)),
        encryptedValueAuthTag: Uint8List.fromList(List.filled(16, 0x03)),
        serviceName: 'Stripe',
      );
      await db.secretDao.create(
        vaultId: vaultId,
        folderId: folderId,
        name: 'GitHub Token',
        encryptedValue: Uint8List.fromList(List.filled(10, 0x01)),
        encryptedValueIv: Uint8List.fromList(List.filled(12, 0x02)),
        encryptedValueAuthTag: Uint8List.fromList(List.filled(16, 0x03)),
        serviceName: 'GitHub',
      );

      final results = await db.secretDao.search(vaultId, 'Stripe');
      expect(results.length, equals(1));
      expect(results.first.name, equals('Stripe API Key'));
    });

    test('search finds by service name', () async {
      await db.secretDao.create(
        vaultId: vaultId,
        folderId: folderId,
        name: 'Production Key',
        encryptedValue: Uint8List.fromList(List.filled(10, 0x01)),
        encryptedValueIv: Uint8List.fromList(List.filled(12, 0x02)),
        encryptedValueAuthTag: Uint8List.fromList(List.filled(16, 0x03)),
        serviceName: 'AWS',
      );

      final results = await db.secretDao.search(vaultId, 'AWS');
      expect(results.length, equals(1));
    });

    test('updateSecret modifies fields', () async {
      final secret = await db.secretDao.create(
        vaultId: vaultId,
        folderId: folderId,
        name: 'Old Name',
        encryptedValue: Uint8List.fromList(List.filled(10, 0x01)),
        encryptedValueIv: Uint8List.fromList(List.filled(12, 0x02)),
        encryptedValueAuthTag: Uint8List.fromList(List.filled(16, 0x03)),
      );

      await db.secretDao.updateSecret(secret.id, name: 'New Name');
      final updated = await db.secretDao.getById(secret.id);
      expect(updated!.name, equals('New Name'));
    });

    test('deleteSecret removes secret', () async {
      final secret = await db.secretDao.create(
        vaultId: vaultId,
        folderId: folderId,
        name: 'To Delete',
        encryptedValue: Uint8List.fromList(List.filled(10, 0x01)),
        encryptedValueIv: Uint8List.fromList(List.filled(12, 0x02)),
        encryptedValueAuthTag: Uint8List.fromList(List.filled(16, 0x03)),
      );

      await db.secretDao.deleteSecret(secret.id);
      final found = await db.secretDao.getById(secret.id);
      expect(found, isNull);
    });
  });

  group('AuditEventDao', () {
    late int vaultId;

    setUp(() async {
      final vault = await db.vaultDao.create(name: 'Test');
      vaultId = vault.id;
    });

    test('creates an audit event', () async {
      final event = await db.auditEventDao.create(
        vaultId: vaultId,
        action: 'secret.create',
        metadata: '{"name": "API Key"}',
      );

      expect(event.action, equals('secret.create'));
      expect(event.metadata, equals('{"name": "API Key"}'));
    });

    test('getPage returns paginated results', () async {
      for (var i = 0; i < 5; i++) {
        await db.auditEventDao.create(vaultId: vaultId, action: 'secret.read');
      }

      final page = await db.auditEventDao.getPage(vaultId);
      expect(page.length, equals(5));
    });
  });
}
