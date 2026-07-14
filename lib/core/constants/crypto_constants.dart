/// Cryptographic constants — must match Rails OpenSSL implementation exactly.
abstract final class CryptoConstants {
  // PBKDF2
  static const int pbkdf2Iterations = 600000;
  static const int saltLength = 32;
  static const int keyLength = 32;

  // AES-256-GCM
  static const int ivLength = 12;
  static const int authTagLength = 16;
  static const int mekLength = 32;

  // Wrapped MEK total = IV(12) + AuthTag(16) + Ciphertext(32) = 60 bytes
  static const int wrappedMekLength = ivLength + authTagLength + mekLength;

  // HKDF-SHA256 domain separation (PR-B key hierarchy).
  // The PDK is expanded into distinct subkeys via distinct info labels; the
  // raw PDK is never used directly as an encryption key. Output length reuses
  // keyLength (32 bytes). The master salt is never reused as HKDF salt.
  static const String hkdfInfoDbKey = 'keybox/v1/dbkey';
  static const String hkdfInfoKek = 'keybox/v1/kek';

  // AAD domain prefix for per-record binding (PR-B).
  // Full label: 'keybox/v1/secret:<secretId>:<recordVersion>' — binds each
  // ciphertext to its row identity (blocks record substitution) and to its
  // record version (blocks rollback to a previously rotated value).
  static const String aadSecretPrefix = 'keybox/v1/secret';

  // Minimum master-password length. Raised 8→12 (CSO threat model T7): an
  // 8-char lowercase password (~2e11 space) is within offline-brute-force
  // reach against the vault; 12 chars (~1e17) closes that window. Enforced
  // only at setup / password-change — never re-checked at unlock, so existing
  // shorter vaults still open.
  static const int minPasswordLength = 12;
}
