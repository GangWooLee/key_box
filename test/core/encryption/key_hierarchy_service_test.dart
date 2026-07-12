import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:key_box/core/constants/crypto_constants.dart';
import 'package:key_box/core/encryption/key_hierarchy_service.dart';

/// Lowercase hex encoding of [bytes] for RFC 5869 vector comparison.
String _hex(Uint8List bytes) =>
    bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

void main() {
  late KeyHierarchyService service;

  /// A fixed, uniform 32-byte PDK stand-in (deterministic across tests).
  Uint8List pdkOf(int fill) => Uint8List.fromList(List.filled(32, fill));

  setUp(() {
    service = KeyHierarchyService();
  });

  group('KeyHierarchyService', () {
    group('subkey length', () {
      test('deriveDbKey returns a 32-byte key', () {
        final dbKey = service.deriveDbKey(pdkOf(0x11));
        expect(dbKey.length, equals(CryptoConstants.keyLength));
      });

      test('deriveKek returns a 32-byte key', () {
        final kek = service.deriveKek(pdkOf(0x11));
        expect(kek.length, equals(CryptoConstants.keyLength));
      });
    });

    group('determinism', () {
      test('deriveDbKey is deterministic for the same PDK', () {
        final pdk = pdkOf(0x22);
        expect(service.deriveDbKey(pdk), equals(service.deriveDbKey(pdk)));
      });

      test('deriveKek is deterministic for the same PDK', () {
        final pdk = pdkOf(0x22);
        expect(service.deriveKek(pdk), equals(service.deriveKek(pdk)));
      });
    });

    group('domain separation', () {
      test('dbKey and kek differ for the same PDK', () {
        final pdk = pdkOf(0x33);
        expect(service.deriveDbKey(pdk), isNot(equals(service.deriveKek(pdk))));
      });

      test('neither subkey equals the raw PDK (no raw PDK reuse)', () {
        final pdk = pdkOf(0x33);
        expect(service.deriveDbKey(pdk), isNot(equals(pdk)));
        expect(service.deriveKek(pdk), isNot(equals(pdk)));
      });
    });

    group('input sensitivity', () {
      test('different PDKs produce different dbKeys', () {
        expect(
          service.deriveDbKey(pdkOf(0x44)),
          isNot(equals(service.deriveDbKey(pdkOf(0x55)))),
        );
      });

      test('different PDKs produce different KEKs', () {
        expect(
          service.deriveKek(pdkOf(0x44)),
          isNot(equals(service.deriveKek(pdkOf(0x55)))),
        );
      });
    });

    group('HKDF RFC 5869 conformance', () {
      // RFC 5869 Appendix A.1, Test Case 1 (SHA-256).
      test('hkdfExpand matches RFC 5869 Test Case 1 vector', () {
        final ikm = Uint8List.fromList(List.filled(22, 0x0b));
        final salt = Uint8List.fromList(List.generate(13, (i) => i)); // 00..0c
        final info = Uint8List.fromList(
          List.generate(10, (i) => 0xf0 + i),
        ); // f0..f9

        final okm = service.hkdfExpand(
          ikm: ikm,
          salt: salt,
          info: info,
          length: 42,
        );

        expect(
          _hex(okm),
          equals(
            '3cb25f25faacd57a90434f64d0362f2a2d2d0a90cf1a5a4c5db02d56ecc4c5bf'
            '34007208d5b887185865',
          ),
        );
      });
    });

    group('input validation', () {
      test('deriveDbKey rejects a PDK of the wrong length', () {
        expect(() => service.deriveDbKey(Uint8List(16)), throwsArgumentError);
      });

      test('deriveKek rejects a PDK of the wrong length', () {
        expect(() => service.deriveKek(Uint8List(16)), throwsArgumentError);
      });
    });
  });
}
