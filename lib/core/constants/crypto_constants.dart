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

  // Minimum password
  static const int minPasswordLength = 8;
}
