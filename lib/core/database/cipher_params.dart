import 'dart:typed_data';

/// SQLCipher 4 cipher parameters, hard-pinned to today's library defaults.
///
/// A `pub upgrade` that ships a library with different defaults would
/// otherwise change how existing files are interpreted and lock every vault
/// out (a one-way door). Stating them explicitly freezes the on-disk format
/// regardless of library defaults. The KDF-related pins are unused in
/// raw-key mode (we already ran PBKDF2+HKDF ourselves, so SQLCipher's
/// internal KDF is bypassed by design) but are pinned defensively in case a
/// future code path ever supplies a passphrase key.
///
/// Shared by the runtime drift connection (database.dart) and the
/// plaintext→encrypted VaultMigrator, which must apply the identical set to
/// the ATTACHed target schema during `sqlcipher_export`.
const List<({String name, String value})> cipherHardPinSettings = [
  (name: 'cipher_page_size', value: '4096'),
  (name: 'cipher_hmac_algorithm', value: 'HMAC_SHA512'),
  (name: 'cipher_kdf_algorithm', value: 'PBKDF2_HMAC_SHA512'),
  (name: 'kdf_iter', value: '256000'),
  (name: 'cipher_use_hmac', value: 'ON'),
  (name: 'cipher_plaintext_header_size', value: '0'),
];

/// Renders the hard-pin PRAGMA statements, optionally schema-qualified
/// (`PRAGMA <schema>.<name> = <value>;`) for ATTACHed databases.
List<String> cipherHardPinPragmas({String? schema}) {
  final prefix = schema == null ? '' : '$schema.';
  return [
    for (final setting in cipherHardPinSettings)
      'PRAGMA $prefix${setting.name} = ${setting.value};',
  ];
}

/// Lowercase hex encoding for SQLCipher raw-key mode (`x'<hex64>'`).
String sqlcipherRawKeyHex(Uint8List key) =>
    key.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
