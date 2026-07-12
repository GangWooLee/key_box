import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:key_box/core/constants/crypto_constants.dart';
import 'package:key_box/core/database/vault_paths.dart';
import 'package:key_box/core/vault/sidecar_store.dart';

void main() {
  Uint8List salt32(int fill) =>
      Uint8List.fromList(List.filled(CryptoConstants.saltLength, fill));

  group('FileSidecarStore', () {
    late Directory tempDir;
    late FileSidecarStore store;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('sidecar_store_test');
      store = FileSidecarStore(baseDir: () async => tempDir);
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    File sidecarFileSync() =>
        File('${tempDir.path}/${VaultPaths.sidecarFileName}');
    File tmpFileSync() =>
        File('${tempDir.path}/${VaultPaths.sidecarFileName}.tmp');

    test('round-trips a written salt', () async {
      final salt = salt32(0x11);
      await store.write(salt);

      final result = await store.read();
      expect(result, isA<SidecarFound>());
      expect((result as SidecarFound).salt, equals(salt));
    });

    test('read returns SidecarMissing when the file is absent', () async {
      expect(await store.read(), isA<SidecarMissing>());
    });

    test('read returns SidecarCorrupted on malformed JSON', () async {
      sidecarFileSync().writeAsStringSync('not json {{{');
      final result = await store.read();
      expect(result, isA<SidecarCorrupted>());
      expect((result as SidecarCorrupted).reason, isNotEmpty);
    });

    test('read rejects an iteration-count downgrade', () async {
      sidecarFileSync().writeAsStringSync(
        jsonEncode({
          'format': 'keybox-vault-sidecar',
          'formatVersion': 1,
          'kdf': {
            'algorithm': 'PBKDF2-HMAC-SHA256',
            'iterations': 1000,
            'saltLength': CryptoConstants.saltLength,
            'keyLength': CryptoConstants.keyLength,
          },
          'salt': base64Encode(salt32(0x22)),
        }),
      );
      expect(await store.read(), isA<SidecarCorrupted>());
    });

    test('read rejects a salt of the wrong length', () async {
      sidecarFileSync().writeAsStringSync(
        jsonEncode({
          'format': 'keybox-vault-sidecar',
          'formatVersion': 1,
          'kdf': {
            'algorithm': 'PBKDF2-HMAC-SHA256',
            'iterations': CryptoConstants.pbkdf2Iterations,
            'saltLength': CryptoConstants.saltLength,
            'keyLength': CryptoConstants.keyLength,
          },
          'salt': base64Encode(Uint8List.fromList(List.filled(16, 0x33))),
        }),
      );
      expect(await store.read(), isA<SidecarCorrupted>());
    });

    test('read rejects an unknown formatVersion', () async {
      sidecarFileSync().writeAsStringSync(
        jsonEncode({
          'format': 'keybox-vault-sidecar',
          'formatVersion': 2,
          'kdf': {
            'algorithm': 'PBKDF2-HMAC-SHA256',
            'iterations': CryptoConstants.pbkdf2Iterations,
            'saltLength': CryptoConstants.saltLength,
            'keyLength': CryptoConstants.keyLength,
          },
          'salt': base64Encode(salt32(0x44)),
        }),
      );
      expect(await store.read(), isA<SidecarCorrupted>());
    });

    test('write overwrites an existing sidecar', () async {
      await store.write(salt32(0x11));
      await store.write(salt32(0x99));

      final result = await store.read();
      expect((result as SidecarFound).salt, equals(salt32(0x99)));
    });

    test('a leftover tmp file does not affect read', () async {
      await store.write(salt32(0x55));
      tmpFileSync().writeAsStringSync('garbage leftover');

      final result = await store.read();
      expect(result, isA<SidecarFound>());
      expect((result as SidecarFound).salt, equals(salt32(0x55)));
    });

    test('delete removes the sidecar and is idempotent', () async {
      await store.write(salt32(0x11));
      await store.delete();
      expect(sidecarFileSync().existsSync(), isFalse);
      // Second delete on an absent file must not throw.
      await store.delete();
      expect(await store.read(), isA<SidecarMissing>());
    });
  });

  group('InMemorySidecarStore', () {
    test('round-trips a written salt', () async {
      final store = InMemorySidecarStore();
      expect(await store.read(), isA<SidecarMissing>());

      final salt = salt32(0x77);
      await store.write(salt);
      final result = await store.read();
      expect((result as SidecarFound).salt, equals(salt));

      await store.delete();
      expect(await store.read(), isA<SidecarMissing>());
    });

    test('read returns a defensive copy — zeroing it must not corrupt the '
        'stored salt', () async {
      // AuthNotifier.unlock() zeroes the salt buffer it read (security rule).
      // If read() leaks the internal reference, the second read returns a
      // zeroed salt and every later unlock silently degrades to the
      // DB-salt fallback path.
      final store = InMemorySidecarStore();
      final salt = salt32(0x42);
      await store.write(salt);

      final first = (await store.read()) as SidecarFound;
      first.salt.fillRange(0, first.salt.length, 0);

      final second = (await store.read()) as SidecarFound;
      expect(second.salt, equals(salt32(0x42)));
    });
  });
}
