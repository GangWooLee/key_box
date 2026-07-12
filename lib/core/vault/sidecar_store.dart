import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import '../constants/crypto_constants.dart';
import '../database/vault_paths.dart';

/// Outcome of reading the salt sidecar.
///
/// A sealed result (never a bool) so the boot matrix can branch cleanly on
/// each distinct case instead of collapsing "missing" and "corrupted".
sealed class SidecarReadResult {}

/// The sidecar file does not exist.
final class SidecarMissing extends SidecarReadResult {}

/// The sidecar exists but is unusable; [reason] identifies why.
final class SidecarCorrupted extends SidecarReadResult {
  SidecarCorrupted(this.reason);
  final String reason;
}

/// The sidecar is valid; [salt] is the 32-byte KDF salt.
final class SidecarFound extends SidecarReadResult {
  SidecarFound(this.salt);
  final Uint8List salt;
}

/// Persists the KDF salt in a small plaintext JSON file alongside the vault
/// database, so the salt is readable before the (eventually encrypted) DB is
/// opened.
abstract interface class SidecarStore {
  Future<SidecarReadResult> read();

  /// Writes [salt]. Throws on failure; the caller treats a write failure as
  /// non-fatal and lets the next boot self-heal.
  Future<void> write(Uint8List salt);

  /// Deletes the sidecar. Idempotent.
  Future<void> delete();
}

/// File-backed [SidecarStore] using an atomic tmp-write-then-rename.
class FileSidecarStore implements SidecarStore {
  FileSidecarStore({Future<Directory> Function()? baseDir})
    : _baseDir = baseDir ?? VaultPaths.supportDir;

  final Future<Directory> Function() _baseDir;

  static const String _format = 'keybox-vault-sidecar';
  static const int _formatVersion = 1;
  static const String _kdfAlgorithm = 'PBKDF2-HMAC-SHA256';

  Future<File> _file() async =>
      File('${(await _baseDir()).path}/${VaultPaths.sidecarFileName}');

  Future<File> _tmpFile() async =>
      File('${(await _baseDir()).path}/${VaultPaths.sidecarFileName}.tmp');

  @override
  Future<SidecarReadResult> read() async {
    final file = await _file();
    if (!await file.exists()) return SidecarMissing();
    return _parse(await file.readAsString());
  }

  /// The sidecar is not authenticated, so its KDF parameters are recorded but
  /// never trusted: anything diverging from [CryptoConstants] (e.g. an
  /// iteration-count downgrade) is treated as corruption.
  SidecarReadResult _parse(String content) {
    final Map<String, dynamic> json;
    try {
      json = jsonDecode(content) as Map<String, dynamic>;
    } catch (_) {
      return SidecarCorrupted('malformed JSON');
    }
    if (json['format'] != _format) return SidecarCorrupted('format mismatch');
    if (json['formatVersion'] != _formatVersion) {
      return SidecarCorrupted('formatVersion mismatch');
    }
    if (!_isValidKdf(json['kdf'])) {
      return SidecarCorrupted('kdf parameter mismatch');
    }
    final Uint8List salt;
    try {
      salt = base64Decode(json['salt'] as String);
    } catch (_) {
      return SidecarCorrupted('salt decode failure');
    }
    if (salt.length != CryptoConstants.saltLength) {
      return SidecarCorrupted('salt length mismatch');
    }
    return SidecarFound(salt);
  }

  bool _isValidKdf(Object? kdf) {
    if (kdf is! Map) return false;
    return kdf['algorithm'] == _kdfAlgorithm &&
        kdf['iterations'] == CryptoConstants.pbkdf2Iterations &&
        kdf['saltLength'] == CryptoConstants.saltLength &&
        kdf['keyLength'] == CryptoConstants.keyLength;
  }

  @override
  Future<void> write(Uint8List salt) async {
    final content = _encode(salt);
    // Write to a fixed same-directory tmp, then rename onto the target: APFS
    // guarantees rename atomicity on the same volume, so a reader never sees a
    // partially written sidecar.
    final tmp = await _tmpFile();
    final raf = await tmp.open(mode: FileMode.write);
    try {
      await raf.writeString(content);
      await raf.flush();
    } finally {
      await raf.close();
    }
    await tmp.rename((await _file()).path);
  }

  String _encode(Uint8List salt) => jsonEncode({
    'format': _format,
    'formatVersion': _formatVersion,
    'kdf': {
      'algorithm': _kdfAlgorithm,
      'iterations': CryptoConstants.pbkdf2Iterations,
      'saltLength': CryptoConstants.saltLength,
      'keyLength': CryptoConstants.keyLength,
    },
    'salt': base64Encode(salt),
  });

  @override
  Future<void> delete() async {
    final file = await _file();
    if (await file.exists()) await file.delete();
  }
}

/// In-memory [SidecarStore] for tests and the legacy in-memory constructor.
class InMemorySidecarStore implements SidecarStore {
  Uint8List? _salt;

  @override
  Future<SidecarReadResult> read() async {
    final salt = _salt;
    // Defensive copy: callers zero the salt they read (security rule), which
    // must not corrupt the stored value.
    return salt == null
        ? SidecarMissing()
        : SidecarFound(Uint8List.fromList(salt));
  }

  @override
  Future<void> write(Uint8List salt) async => _salt = Uint8List.fromList(salt);

  @override
  Future<void> delete() async => _salt = null;
}
