// PR-B (B3): AppDatabase keyed open — SQLCipher encryption gate.
//
// Cipher-dependent verification MUST run as an integration test on the real
// macOS app: plain `flutter test` loads Apple's restricted system libsqlite3,
// which silently ignores `PRAGMA key` (project-confirmed lesson), so these
// assertions would pass vacuously there. The real app bundles the
// cipher-capable dylib from `sqlcipher_flutter_libs` via CocoaPods.
//
// Run ONLY on a real macOS device:
//   flutter test integration_test/encrypted_vault_test.dart -d macos
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:key_box/core/database/database.dart';
import 'package:key_box/core/database/vault_paths.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

const _marker = 'KEYBOX_B3_ENCRYPTION_MARKER_7C4E9D';

/// Fixed 32-byte DB keys (deterministic — this test is about the keyed-open
/// plumbing, not key generation).
Uint8List _keyA() => Uint8List.fromList(List.generate(32, (i) => i + 1));
Uint8List _keyB() => Uint8List.fromList(List.generate(32, (i) => 0xE0 - i));

String _hex(Uint8List bytes) =>
    bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

/// The SQLCipher 4 parameter set hard-pinned by AppDatabase — reopening with
/// these explicitly stated must be compatible with what AppDatabase wrote.
const _hardPinPragmas = [
  'PRAGMA cipher_page_size = 4096;',
  'PRAGMA cipher_hmac_algorithm = HMAC_SHA512;',
  'PRAGMA cipher_kdf_algorithm = PBKDF2_HMAC_SHA512;',
  'PRAGMA kdf_iter = 256000;',
  'PRAGMA cipher_use_hmac = ON;',
  'PRAGMA cipher_plaintext_header_size = 0;',
];

bool _containsMarker(Uint8List bytes) {
  final needle = _marker.codeUnits;
  for (var i = 0; i + needle.length <= bytes.length; i++) {
    var match = true;
    for (var j = 0; j < needle.length; j++) {
      if (bytes[i + j] != needle[j]) {
        match = false;
        break;
      }
    }
    if (match) return true;
  }
  return false;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late Directory tmp;
  late Future<Directory> Function() previousSupportDir;

  setUp(() async {
    // Redirect VaultPaths into a per-test temp dir inside the app sandbox so
    // AppDatabase (which resolves its file via VaultPaths) writes there.
    final base = await getApplicationSupportDirectory();
    tmp = Directory(
      '${base.path}/b3_encrypted_vault_${DateTime.now().microsecondsSinceEpoch}',
    )..createSync(recursive: true);
    previousSupportDir = VaultPaths.supportDir;
    VaultPaths.supportDir = () async => tmp;
  });

  tearDown(() {
    VaultPaths.supportDir = previousSupportDir;
    if (tmp.existsSync()) tmp.deleteSync(recursive: true);
  });

  Future<File> dbFileOnDisk() async => VaultPaths.dbFile();

  /// Creates a keyed vault DB containing the marker vault row, then closes it.
  Future<void> writeMarkerVault(Uint8List key) async {
    final db = AppDatabase(dbKey: key);
    await db.vaultDao.create(name: _marker);
    await db.close();
  }

  testWidgets('keyed AppDatabase writes real ciphertext: no plaintext marker, '
      'no SQLite header, no keyless read — and reopens with the same key', (
    tester,
  ) async {
    await writeMarkerVault(_keyA());

    final file = await dbFileOnDisk();
    expect(file.existsSync(), isTrue);
    final bytes = file.readAsBytesSync();

    // ① Raw file bytes carry neither the plaintext marker nor the classic
    // "SQLite format 3" magic (encrypted headers are indistinguishable
    // from random bytes).
    expect(
      _containsMarker(bytes),
      isFalse,
      reason: 'plaintext marker found in raw DB file — PRAGMA key no-op',
    );
    final header = String.fromCharCodes(bytes.take(15));
    expect(
      header,
      isNot(equals('SQLite format 3')),
      reason: 'plaintext SQLite header — file is not encrypted',
    );

    // ② A keyless raw open must fail to read.
    Object? keylessError;
    try {
      final raw = sqlite3.open(file.path);
      try {
        raw.select('SELECT name FROM vaults;');
      } finally {
        raw.dispose();
      }
    } catch (e) {
      keylessError = e;
    }
    // ignore: avoid_print
    print('[B3] keyless read error = $keylessError');
    expect(
      keylessError,
      isA<SqliteException>(),
      reason: 'keyless read succeeded — encryption is a no-op',
    );

    // ③ Reopening through AppDatabase with the same key round-trips.
    final db = AppDatabase(dbKey: _keyA());
    final vault = await db.vaultDao.getFirst();
    expect(vault?.name, equals(_marker));
    await db.close();
  });

  testWidgets('a wrong 32-byte key is rejected (no cross-key read)', (
    tester,
  ) async {
    await writeMarkerVault(_keyA());

    final wrong = AppDatabase(dbKey: _keyB());
    Object? error;
    try {
      await wrong.vaultDao.getFirst();
    } catch (e) {
      error = e;
    } finally {
      try {
        await wrong.close();
      } catch (_) {
        // The connection never became usable; close failures are irrelevant.
      }
    }

    // ignore: avoid_print
    print('[B3] wrong-key open error = $error');
    expect(error, isNotNull, reason: 'wrong key read the vault');
    expect(
      '$error',
      contains('not a database'),
      reason: 'expected SQLITE_NOTADB (26) HMAC rejection, got: $error',
    );
  });

  testWidgets(
    'hard-pin round-trip: raw sqlite3 reopen with the explicit SQLCipher 4 '
    'parameter set reads AppDatabase-written data',
    (tester) async {
      await writeMarkerVault(_keyA());

      final file = await dbFileOnDisk();
      final raw = sqlite3.open(file.path);
      try {
        raw.execute('PRAGMA key = "x\'${_hex(_keyA())}\'";');
        for (final pragma in _hardPinPragmas) {
          raw.execute(pragma);
        }
        final rows = raw.select('SELECT name FROM vaults;');
        expect(rows, hasLength(1));
        expect(rows.first['name'], equals(_marker));
      } finally {
        raw.dispose();
      }
    },
  );

  testWidgets('drift creates the full v3 schema on a keyed database', (
    tester,
  ) async {
    final db = AppDatabase(dbKey: _keyA());

    final versionRow = await db.customSelect('PRAGMA user_version').getSingle();
    expect(versionRow.data['user_version'], equals(3));

    // v3 shape proof on the keyed DB: secrets carries record_version.
    final secretColumns =
        (await db.customSelect('PRAGMA table_info(secrets)').get())
            .map((r) => r.data['name'])
            .toList();
    expect(secretColumns, contains('record_version'));

    // Full-stack write/read through the DAOs works on the keyed DB.
    final vault = await db.vaultDao.create(name: 'Personal');
    final folder = await db.folderDao.create(
      vaultId: vault.id,
      name: 'General',
    );
    final secret = await db.secretDao.create(
      vaultId: vault.id,
      folderId: folder.id,
      name: 'API Key',
      encryptedValue: Uint8List.fromList([1, 2, 3]),
      encryptedValueIv: Uint8List.fromList([4, 5, 6]),
      encryptedValueAuthTag: Uint8List.fromList([7, 8, 9]),
    );
    expect(secret.recordVersion, equals(1));

    await db.close();
  });
}
