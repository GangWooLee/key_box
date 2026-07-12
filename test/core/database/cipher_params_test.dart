import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:key_box/core/database/cipher_params.dart';

void main() {
  group('cipherHardPinPragmas', () {
    test('renders the exact SQLCipher 4 hard-pin statements (B3 contract)', () {
      // These strings are the on-disk format contract established in B3.
      // Any change here re-interprets existing vault files — one-way door.
      expect(cipherHardPinPragmas(), [
        'PRAGMA cipher_page_size = 4096;',
        'PRAGMA cipher_hmac_algorithm = HMAC_SHA512;',
        'PRAGMA cipher_kdf_algorithm = PBKDF2_HMAC_SHA512;',
        'PRAGMA kdf_iter = 256000;',
        'PRAGMA cipher_use_hmac = ON;',
        'PRAGMA cipher_plaintext_header_size = 0;',
      ]);
    });

    test('schema-qualifies every statement for ATTACHed databases', () {
      expect(cipherHardPinPragmas(schema: 'encrypted'), [
        'PRAGMA encrypted.cipher_page_size = 4096;',
        'PRAGMA encrypted.cipher_hmac_algorithm = HMAC_SHA512;',
        'PRAGMA encrypted.cipher_kdf_algorithm = PBKDF2_HMAC_SHA512;',
        'PRAGMA encrypted.kdf_iter = 256000;',
        'PRAGMA encrypted.cipher_use_hmac = ON;',
        'PRAGMA encrypted.cipher_plaintext_header_size = 0;',
      ]);
    });
  });

  group('sqlcipherRawKeyHex', () {
    test('encodes bytes as lowercase hex without separators', () {
      final key = Uint8List.fromList([0x00, 0x01, 0x0A, 0xFF, 0xAB]);
      expect(sqlcipherRawKeyHex(key), '00010affab');
    });

    test('a 32-byte key renders 64 hex characters', () {
      final key = Uint8List.fromList(List.generate(32, (i) => i));
      expect(sqlcipherRawKeyHex(key).length, 64);
    });
  });
}
