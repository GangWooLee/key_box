import 'dart:math';
import 'dart:typed_data';
import 'package:pointycastle/export.dart';

final _secureRandom = _createSecureRandom();

SecureRandom _createSecureRandom() {
  final rng = SecureRandom('Fortuna');
  final seed = Uint8List(32);
  final dartRandom = Random.secure();
  for (var i = 0; i < seed.length; i++) {
    seed[i] = dartRandom.nextInt(256);
  }
  rng.seed(KeyParameter(seed));
  return rng;
}

/// Generate cryptographically secure random bytes.
Uint8List secureRandomBytes(int length) {
  return _secureRandom.nextBytes(length);
}
