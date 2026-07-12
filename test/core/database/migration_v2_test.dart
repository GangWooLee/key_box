import 'dart:typed_data';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:key_box/core/database/database.dart';

void main() {
  group('Schema v2 — fresh database', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    test('creates folder_secrets table', () async {
      // Insert a vault and folder first
      final vault = await db.vaultDao.create(name: 'Test');
      final folder = await db.folderDao.create(
        vaultId: vault.id,
        name: 'General',
      );

      // Link a secret via join table
      final secret = await db.secretDao.create(
        vaultId: vault.id,
        folderId: folder.id,
        name: 'API Key',
        encryptedValue: Uint8List.fromList([1, 2, 3]),
        encryptedValueIv: Uint8List.fromList([4, 5, 6]),
        encryptedValueAuthTag: Uint8List.fromList([7, 8, 9]),
      );

      await db.folderSecretsDao.link(folder.id, secret.id);
      final isLinked = await db.folderSecretsDao.isLinked(folder.id, secret.id);
      expect(isLinked, isTrue);
    });

    test('folders table has parentId column (nullable)', () async {
      final vault = await db.vaultDao.create(name: 'Test');

      // Root folder (parentId = null)
      final root = await db.folderDao.create(vaultId: vault.id, name: 'Root');
      expect(root.parentId, isNull);

      // Child folder (parentId = root.id)
      final child = await db.folderDao.create(
        vaultId: vault.id,
        name: 'Child',
        parentId: root.id,
      );
      expect(child.parentId, equals(root.id));
    });

    test('secret can be linked to multiple folders (M:N)', () async {
      final vault = await db.vaultDao.create(name: 'Test');
      final folder1 = await db.folderDao.create(
        vaultId: vault.id,
        name: 'Folder A',
      );
      final folder2 = await db.folderDao.create(
        vaultId: vault.id,
        name: 'Folder B',
      );

      final secret = await db.secretDao.create(
        vaultId: vault.id,
        folderId: folder1.id,
        name: 'Shared Secret',
        encryptedValue: Uint8List.fromList([1]),
        encryptedValueIv: Uint8List.fromList([2]),
        encryptedValueAuthTag: Uint8List.fromList([3]),
      );

      await db.folderSecretsDao.link(folder1.id, secret.id);
      await db.folderSecretsDao.link(folder2.id, secret.id);

      final folderIds = await db.folderSecretsDao.getFolderIdsBySecretId(
        secret.id,
      );
      expect(folderIds, containsAll([folder1.id, folder2.id]));
    });

    test('duplicate link is ignored (insertOrIgnore)', () async {
      final vault = await db.vaultDao.create(name: 'Test');
      final folder = await db.folderDao.create(
        vaultId: vault.id,
        name: 'Folder',
      );
      final secret = await db.secretDao.create(
        vaultId: vault.id,
        folderId: folder.id,
        name: 'S1',
        encryptedValue: Uint8List.fromList([1]),
        encryptedValueIv: Uint8List.fromList([2]),
        encryptedValueAuthTag: Uint8List.fromList([3]),
      );

      await db.folderSecretsDao.link(folder.id, secret.id);
      // Should not throw
      await db.folderSecretsDao.link(folder.id, secret.id);

      final ids = await db.folderSecretsDao.getFolderIdsBySecretId(secret.id);
      expect(ids, hasLength(1));
    });

    test('resetVault clears folder_secrets', () async {
      final vault = await db.vaultDao.create(name: 'Test');
      final folder = await db.folderDao.create(
        vaultId: vault.id,
        name: 'Folder',
      );
      final secret = await db.secretDao.create(
        vaultId: vault.id,
        folderId: folder.id,
        name: 'S1',
        encryptedValue: Uint8List.fromList([1]),
        encryptedValueIv: Uint8List.fromList([2]),
        encryptedValueAuthTag: Uint8List.fromList([3]),
      );
      await db.folderSecretsDao.link(folder.id, secret.id);

      await db.resetVault();

      // After reset, the join table should be empty
      final ids = await db.folderSecretsDao.getFolderIdsBySecretId(secret.id);
      expect(ids, isEmpty);
    });
  });
}
