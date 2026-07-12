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

  // Minimum password
  static const int minPasswordLength = 8;
}
