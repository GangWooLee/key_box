import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:pointycastle/export.dart';

import '../constants/crypto_constants.dart';

/// HKDF-SHA256 domain separation from the PDK.
///
/// The PDK (PBKDF2 output) is treated as the PRK-grade input; subkeys are
/// derived with distinct info labels. Raw PDK must never be used as a key.
///
/// - [deriveDbKey] → SQLCipher `PRAGMA key` material (used by B3).
/// - [deriveKek]   → key-encryption key that wraps/unwraps the MEK (used by B4).
///
/// The master salt is never reused here: the HKDF salt is empty, so per
/// RFC 5869 the Extract step uses HashLen zero bytes. Domain separation is
/// carried entirely by the `info` label.
class KeyHierarchyService {
  /// Derive the SQLCipher `PRAGMA key` material from the [pdk].
  Uint8List deriveDbKey(Uint8List pdk) {
    _requireValidPdk(pdk);
    return hkdfExpand(
      ikm: pdk,
      salt: Uint8List(0),
      info: _label(CryptoConstants.hkdfInfoDbKey),
      length: CryptoConstants.keyLength,
    );
  }

  /// Derive the key-encryption key (KEK) that wraps/unwraps the MEK from the
  /// [pdk].
  Uint8List deriveKek(Uint8List pdk) {
    _requireValidPdk(pdk);
    return hkdfExpand(
      ikm: pdk,
      salt: Uint8List(0),
      info: _label(CryptoConstants.hkdfInfoKek),
      length: CryptoConstants.keyLength,
    );
  }

  /// HKDF-SHA256 (RFC 5869 Extract-and-Expand).
  ///
  /// Exposed for vector testing (RFC 5869 Appendix A.1). An empty [salt] means
  /// the Extract step uses HashLen zero bytes, per RFC 5869.
  @visibleForTesting
  Uint8List hkdfExpand({
    required Uint8List ikm,
    required Uint8List salt,
    required Uint8List info,
    required int length,
  }) {
    final hkdf = HKDFKeyDerivator(SHA256Digest());
    hkdf.init(HkdfParameters(ikm, length, salt, info));
    final out = Uint8List(length);
    hkdf.deriveKey(null, 0, out, 0);
    return out;
  }

  void _requireValidPdk(Uint8List pdk) {
    if (pdk.length != CryptoConstants.keyLength) {
      throw ArgumentError.value(
        pdk.length,
        'pdk',
        'PDK must be ${CryptoConstants.keyLength} bytes',
      );
    }
  }

  Uint8List _label(String value) => Uint8List.fromList(ascii.encode(value));
}
