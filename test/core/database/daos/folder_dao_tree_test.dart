import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:key_box/core/database/database.dart';

void main() {
  late AppDatabase db;
  late int vaultId;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    final vault = await db.vaultDao.create(name: 'Test');
    vaultId = vault.id;
  });

  tearDown(() async {
    await db.close();
  });

  group('FolderDao — tree methods', () {
    test(
      'watchRootFolders returns only root folders (parentId == null)',
      () async {
        final root1 = await db.folderDao.create(
          vaultId: vaultId,
          name: 'Root 1',
        );
        await db.folderDao.create(vaultId: vaultId, name: 'Root 2');
        await db.folderDao.create(
          vaultId: vaultId,
          name: 'Child 1',
          parentId: root1.id,
        );

        final roots = await db.folderDao.watchRootFolders(vaultId).first;
        expect(roots, hasLength(2));
        expect(roots.map((f) => f.name), containsAll(['Root 1', 'Root 2']));
      },
    );

    test('watchChildren returns direct children only', () async {
      final root = await db.folderDao.create(vaultId: vaultId, name: 'Root');
      final child1 = await db.folderDao.create(
        vaultId: vaultId,
        name: 'Child 1',
        parentId: root.id,
      );
      await db.folderDao.create(
        vaultId: vaultId,
        name: 'Grandchild',
        parentId: child1.id,
      );

      final children = await db.folderDao.watchChildren(root.id).first;
      expect(children, hasLength(1));
      expect(children.first.name, equals('Child 1'));
    });

    test('getDescendantIds returns all nested descendants', () async {
      // Root → Child → Grandchild
      final root = await db.folderDao.create(vaultId: vaultId, name: 'Root');
      final child = await db.folderDao.create(
        vaultId: vaultId,
        name: 'Child',
        parentId: root.id,
      );
      final grandchild = await db.folderDao.create(
        vaultId: vaultId,
        name: 'Grandchild',
        parentId: child.id,
      );

      final ids = await db.folderDao.getDescendantIds(root.id);
      expect(ids, containsAll([child.id, grandchild.id]));
      expect(ids, isNot(contains(root.id)));
    });

    test('moveFolder changes parent', () async {
      final root1 = await db.folderDao.create(vaultId: vaultId, name: 'Root 1');
      final root2 = await db.folderDao.create(vaultId: vaultId, name: 'Root 2');
      final child = await db.folderDao.create(
        vaultId: vaultId,
        name: 'Child',
        parentId: root1.id,
      );

      // Move child from root1 to root2
      final success = await db.folderDao.moveFolder(child.id, root2.id);
      expect(success, isTrue);

      // root1 should have no children
      final r1Children = await db.folderDao.watchChildren(root1.id).first;
      expect(r1Children, isEmpty);

      // root2 should have the child
      final r2Children = await db.folderDao.watchChildren(root2.id).first;
      expect(r2Children, hasLength(1));
      expect(r2Children.first.name, equals('Child'));
    });

    test('moveFolder to root (null parent)', () async {
      final root = await db.folderDao.create(vaultId: vaultId, name: 'Root');
      final child = await db.folderDao.create(
        vaultId: vaultId,
        name: 'Child',
        parentId: root.id,
      );

      await db.folderDao.moveFolder(child.id, null);

      final roots = await db.folderDao.watchRootFolders(vaultId).first;
      expect(roots.map((f) => f.name), contains('Child'));
    });

    test('3-level nesting works correctly', () async {
      final l1 = await db.folderDao.create(vaultId: vaultId, name: 'L1');
      final l2 = await db.folderDao.create(
        vaultId: vaultId,
        name: 'L2',
        parentId: l1.id,
      );
      final l3 = await db.folderDao.create(
        vaultId: vaultId,
        name: 'L3',
        parentId: l2.id,
      );

      // l1 descendants = l2, l3
      final l1Desc = await db.folderDao.getDescendantIds(l1.id);
      expect(l1Desc, hasLength(2));
      expect(l1Desc, containsAll([l2.id, l3.id]));

      // l2 descendants = l3 only
      final l2Desc = await db.folderDao.getDescendantIds(l2.id);
      expect(l2Desc, hasLength(1));
      expect(l2Desc, contains(l3.id));

      // l3 has no descendants
      final l3Desc = await db.folderDao.getDescendantIds(l3.id);
      expect(l3Desc, isEmpty);
    });
  });
}
