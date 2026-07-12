// SPIKE(sqlite3-multiple-ciphers): POSITIVE CONTROL — throwaway. DO NOT SHIP.
//
// Goal: prove, in the REAL macOS app runtime (where CocoaPods bundles the
// cipher-capable native dylib from `sqlcipher_flutter_libs`), that:
//   A0 (diagnostic) — which sqlite3 library is actually loaded (compile_options,
//                     cipher_version), NOT Apple's restricted system libsqlite3.
//   A1 — a cipher codec is linked (SQLCipher `cipher_version` returns a version).
//   A2 — encryption is REAL: raw file bytes do NOT contain the plaintext marker,
//        AND reopening WITHOUT the key FAILS / returns no plaintext.
//
// This is the thing `flutter test` could NOT do (host VM loads Apple's
// HAS_CODEC_RESTRICTED libsqlite3 which silently ignores PRAGMA key).
//
// Run ONLY on a real macOS device:
//   flutter test integration_test/cipher_positive_test.dart -d macos
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

const _plaintextMarker = 'SPIKE_SECRET_PLAINTEXT_MARKER_9F3A2B';

List<String> _compileOptions(Database db) => db
    .select('PRAGMA compile_options;')
    .map((r) => r.values.first.toString())
    .toList();

/// SQLCipher exposes `PRAGMA cipher_version;`. SQLite3MultipleCiphers exposes
/// `PRAGMA cipher;` (and also `cipher_version` in newer builds). We probe both.
String _probePragma(Database db, String pragma) {
  try {
    final rows = db.select('PRAGMA $pragma;');
    if (rows.isEmpty) return '<empty>';
    return rows.map((r) => r.values.map((v) => '$v').join(',')).join(' | ');
  } catch (e) {
    return '<threw: $e>';
  }
}

bool _fileContainsMarker(File f) {
  final bytes = f.readAsBytesSync();
  final needle = Uint8List.fromList(_plaintextMarker.codeUnits);
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

  setUp(() async {
    // Use an app-sandbox writable dir (macOS app is sandboxed).
    final base = await getApplicationSupportDirectory();
    tmp = Directory(
      '${base.path}/spike_cipher_${DateTime.now().microsecondsSinceEpoch}',
    )..createSync(recursive: true);
  });
  tearDown(() {
    if (tmp.existsSync()) tmp.deleteSync(recursive: true);
  });

  testWidgets('A0 DIAGNOSTIC: which sqlite3 lib is loaded in the real app', (
    tester,
  ) async {
    final db = sqlite3.openInMemory();
    final version = db.select('SELECT sqlite_version() AS v;').first['v'];
    final opts = _compileOptions(db);
    final cipherVersion = _probePragma(db, 'cipher_version');
    final cipher = _probePragma(db, 'cipher');
    final hasCipherOpt = opts.any((o) {
      final u = o.toUpperCase();
      return u.contains('CIPHER') ||
          u.contains('CODEC') ||
          u.contains('SQLITE3MC');
    });
    // Apple's restricted system lib is identifiable by these markers.
    final appleRestricted = opts.any((o) {
      final u = o.toUpperCase();
      return u.contains('HAS_CODEC_RESTRICTED') || u.contains('SEE-CCCRYPT');
    });
    db.dispose();

    // ignore: avoid_print
    print('[SPIKE][A0] sqlite_version      = $version');
    // ignore: avoid_print
    print('[SPIKE][A0] PRAGMA cipher_version = $cipherVersion');
    // ignore: avoid_print
    print('[SPIKE][A0] PRAGMA cipher          = $cipher');
    // ignore: avoid_print
    print('[SPIKE][A0] cipher/codec compile_option present = $hasCipherOpt');
    // ignore: avoid_print
    print(
      '[SPIKE][A0] APPLE-RESTRICTED (vacuous) markers    = $appleRestricted',
    );
    // ignore: avoid_print
    print('[SPIKE][A0] compile_options = $opts');
  });

  testWidgets(
    'A1: a cipher codec is linked (cipher_version/cipher non-empty)',
    (tester) async {
      final db = sqlite3.openInMemory();
      final cipherVersion = _probePragma(db, 'cipher_version');
      final cipher = _probePragma(db, 'cipher');
      db.dispose();

      final linked =
          (cipherVersion != '<empty>' && !cipherVersion.startsWith('<threw')) ||
          (cipher != '<empty>' && !cipher.startsWith('<threw'));
      // ignore: avoid_print
      print(
        '[SPIKE][A1] cipher linked = $linked '
        '(cipher_version=$cipherVersion, cipher=$cipher)',
      );
      expect(
        linked,
        isTrue,
        reason:
            'Neither PRAGMA cipher_version nor PRAGMA cipher returned a '
            'value -> no cipher codec linked in the real app. '
            'cipher_version=$cipherVersion cipher=$cipher',
      );
    },
  );

  testWidgets(
    'A2: real encryption — raw file has no plaintext & no-key read fails',
    (tester) async {
      final path = '${tmp.path}/enc.db';

      // 1) Create encrypted DB, key it, write marker, close.
      final db = sqlite3.open(path);
      db.execute("PRAGMA key = 'correct horse battery staple';");
      db.execute('CREATE TABLE t (v TEXT);');
      db.execute("INSERT INTO t (v) VALUES ('$_plaintextMarker');");
      // Force pages to flush to disk.
      db.execute('PRAGMA wal_checkpoint(FULL);');
      db.dispose();

      // 2) Raw bytes must NOT contain the plaintext marker.
      final rawHasPlaintext = _fileContainsMarker(File(path));
      // Also inspect the file header: SQLCipher files do NOT start with the
      // classic "SQLite format 3\000" magic; encrypted files have random header.
      final header = File(path).readAsBytesSync().take(16).toList();
      final headerStr = String.fromCharCodes(
        header.where((b) => b >= 32 && b < 127),
      );
      // ignore: avoid_print
      print(
        '[SPIKE][A2] raw file contains plaintext marker = $rawHasPlaintext',
      );
      // ignore: avoid_print
      print('[SPIKE][A2] file header (printable) = "$headerStr" bytes=$header');

      // 3) Reopen WITHOUT the key -> read must fail / not return plaintext.
      var wrongKeyReadSucceeded = false;
      Object? wrongKeyError;
      try {
        final db2 = sqlite3.open(path);
        final rows = db2.select('SELECT v FROM t;');
        wrongKeyReadSucceeded =
            rows.isNotEmpty && rows.first['v'] == _plaintextMarker;
        db2.dispose();
      } catch (e) {
        wrongKeyError = e;
      }
      // ignore: avoid_print
      print(
        '[SPIKE][A2] read WITHOUT key succeeded = $wrongKeyReadSucceeded, '
        'error = $wrongKeyError',
      );

      // 4) Sanity: reopen WITH the correct key must return the marker.
      var correctKeyReadOk = false;
      try {
        final db3 = sqlite3.open(path);
        db3.execute("PRAGMA key = 'correct horse battery staple';");
        final rows = db3.select('SELECT v FROM t;');
        correctKeyReadOk =
            rows.isNotEmpty && rows.first['v'] == _plaintextMarker;
        db3.dispose();
      } catch (e) {
        // ignore: avoid_print
        print('[SPIKE][A2] correct-key reopen threw: $e');
      }
      // ignore: avoid_print
      print('[SPIKE][A2] read WITH correct key ok = $correctKeyReadOk');

      expect(
        rawHasPlaintext,
        isFalse,
        reason:
            'Plaintext marker found in raw DB file -> NOT encrypted '
            '(PRAGMA key was a no-op / vacuous gate).',
      );
      expect(
        wrongKeyReadSucceeded,
        isFalse,
        reason: 'DB readable without the key -> encryption is a no-op.',
      );
      expect(
        correctKeyReadOk,
        isTrue,
        reason:
            'Correct key could not read back the marker -> the DB is not '
            'actually a functioning keyed DB (round-trip failed).',
      );
    },
  );
}
