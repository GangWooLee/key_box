import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:key_box/core/database/vault_paths.dart';

void main() {
  late Directory tempDir;
  late Future<Directory> Function() originalSupportDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('vault_paths_test');
    originalSupportDir = VaultPaths.supportDir;
    VaultPaths.supportDir = () async => tempDir;
  });

  tearDown(() {
    VaultPaths.supportDir = originalSupportDir;
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  File dbFileSync() => File('${tempDir.path}/${VaultPaths.dbFileName}');
  File walFileSync() => File('${tempDir.path}/${VaultPaths.dbWalFileName}');
  File shmFileSync() => File('${tempDir.path}/${VaultPaths.dbShmFileName}');

  group('dbFileExists', () {
    test('returns false when the database file is absent', () async {
      expect(await VaultPaths.dbFileExists(), isFalse);
    });

    test('returns true when the database file is present', () async {
      dbFileSync().writeAsStringSync('db');
      expect(await VaultPaths.dbFileExists(), isTrue);
    });
  });

  group('deleteDatabaseFiles', () {
    test('removes db, wal, and shm files', () async {
      dbFileSync().writeAsStringSync('db');
      walFileSync().writeAsStringSync('wal');
      shmFileSync().writeAsStringSync('shm');

      await VaultPaths.deleteDatabaseFiles();

      expect(dbFileSync().existsSync(), isFalse);
      expect(walFileSync().existsSync(), isFalse);
      expect(shmFileSync().existsSync(), isFalse);
    });

    test('is idempotent when only some files exist', () async {
      dbFileSync().writeAsStringSync('db');
      // wal and shm intentionally absent.

      await VaultPaths.deleteDatabaseFiles();

      expect(dbFileSync().existsSync(), isFalse);
      expect(walFileSync().existsSync(), isFalse);
      expect(shmFileSync().existsSync(), isFalse);
    });

    test('is idempotent when no files exist', () async {
      await VaultPaths.deleteDatabaseFiles();
      expect(dbFileSync().existsSync(), isFalse);
    });
  });

  group('path helpers', () {
    test('dbFile resolves under the support directory', () async {
      final file = await VaultPaths.dbFile();
      expect(file.path, equals('${tempDir.path}/${VaultPaths.dbFileName}'));
    });

    test('sidecarFile resolves under the support directory', () async {
      final file = await VaultPaths.sidecarFile();
      expect(
        file.path,
        equals('${tempDir.path}/${VaultPaths.sidecarFileName}'),
      );
    });
  });
}
