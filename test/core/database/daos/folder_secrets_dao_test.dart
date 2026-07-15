import 'dart:typed_data';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:key_box/core/database/database.dart';

void main() {
  late AppDatabase db;
  late int vaultId;
  late int folder1Id;
  late int folder2Id;

  Future<Secret> createSecret(String name, int folderId) {
    return db.secretDao.create(
      vaultId: vaultId,
      folderId: folderId,
      name: name,
      encryptedValue: Uint8List.fromList([1]),
      encryptedValueIv: Uint8List.fromList([2]),
      encryptedValueAuthTag: Uint8List.fromList([3]),
    );
  }

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    final vault = await db.vaultDao.create(name: 'Test');
    vaultId = vault.id;
    final f1 = await db.folderDao.create(vaultId: vaultId, name: 'Folder A');
    final f2 = await db.folderDao.create(vaultId: vaultId, name: 'Folder B');
    folder1Id = f1.id;
    folder2Id = f2.id;
  });

  tearDown(() async {
    await db.close();
  });

  group('FolderSecretsDao', () {
    test('link and isLinked', () async {
      final secret = await createSecret('S1', folder1Id);

      expect(await db.folderSecretsDao.isLinked(folder1Id, secret.id), isFalse);

      await db.folderSecretsDao.link(folder1Id, secret.id);
      expect(await db.folderSecretsDao.isLinked(folder1Id, secret.id), isTrue);
    });

    test('unlink removes the link', () async {
      final secret = await createSecret('S1', folder1Id);
      await db.folderSecretsDao.link(folder1Id, secret.id);

      await db.folderSecretsDao.unlink(folder1Id, secret.id);
      expect(await db.folderSecretsDao.isLinked(folder1Id, secret.id), isFalse);
    });

    test('watchSecretsByFolderId returns linked secrets', () async {
      final s1 = await createSecret('S1', folder1Id);
      final s2 = await createSecret('S2', folder1Id);
      await db.folderSecretsDao.link(folder1Id, s1.id);
      await db.folderSecretsDao.link(folder1Id, s2.id);

      final secrets = await db.folderSecretsDao
          .watchSecretsByFolderId(folder1Id)
          .first;
      expect(secrets, hasLength(2));
      expect(secrets.map((s) => s.name), containsAll(['S1', 'S2']));
    });

    test('getFolderIdsBySecretId returns all linked folders', () async {
      final secret = await createSecret('Shared', folder1Id);
      await db.folderSecretsDao.link(folder1Id, secret.id);
      await db.folderSecretsDao.link(folder2Id, secret.id);

      final ids = await db.folderSecretsDao.getFolderIdsBySecretId(secret.id);
      expect(ids, containsAll([folder1Id, folder2Id]));
    });

    test('unlinkAllForSecret removes all links', () async {
      final secret = await createSecret('S', folder1Id);
      await db.folderSecretsDao.link(folder1Id, secret.id);
      await db.folderSecretsDao.link(folder2Id, secret.id);

      await db.folderSecretsDao.unlinkAllForSecret(secret.id);

      expect(await db.folderSecretsDao.isLinked(folder1Id, secret.id), isFalse);
      expect(await db.folderSecretsDao.isLinked(folder2Id, secret.id), isFalse);
    });

    test('unlinkAllForFolder removes all links for that folder', () async {
      final s1 = await createSecret('S1', folder1Id);
      final s2 = await createSecret('S2', folder1Id);
      await db.folderSecretsDao.link(folder1Id, s1.id);
      await db.folderSecretsDao.link(folder1Id, s2.id);

      await db.folderSecretsDao.unlinkAllForFolder(folder1Id);

      final secrets = await db.folderSecretsDao
          .watchSecretsByFolderId(folder1Id)
          .first;
      expect(secrets, isEmpty);
    });

    group('watchCountsByFolder (derived count — single source of truth)', () {
      test('returns per-folder live member counts', () async {
        final s1 = await createSecret('S1', folder1Id);
        final s2 = await createSecret('S2', folder1Id);
        final s3 = await createSecret('S3', folder2Id);
        await db.folderSecretsDao.link(folder1Id, s1.id);
        await db.folderSecretsDao.link(folder1Id, s2.id);
        await db.folderSecretsDao.link(folder2Id, s3.id);

        final counts = await db.folderSecretsDao.watchCountsByFolder().first;
        expect(counts[folder1Id], 2);
        expect(counts[folder2Id], 1);
      });

      test('omits folders with no links (caller uses ?? 0)', () async {
        final s1 = await createSecret('S1', folder1Id);
        await db.folderSecretsDao.link(folder1Id, s1.id);

        final counts = await db.folderSecretsDao.watchCountsByFolder().first;
        expect(counts[folder1Id], 1);
        expect(counts[folder2Id], isNull);
      });

      test(
        'reflects unlink live (matches the join table, no cache drift)',
        () async {
          final s1 = await createSecret('S1', folder1Id);
          final s2 = await createSecret('S2', folder1Id);
          await db.folderSecretsDao.link(folder1Id, s1.id);
          await db.folderSecretsDao.link(folder1Id, s2.id);
          expect(
            (await db.folderSecretsDao.watchCountsByFolder().first)[folder1Id],
            2,
          );

          await db.folderSecretsDao.unlinkAllForSecret(s1.id);
          expect(
            (await db.folderSecretsDao.watchCountsByFolder().first)[folder1Id],
            1,
          );
        },
      );
    });
  });
}
