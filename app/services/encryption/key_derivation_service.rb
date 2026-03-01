module Encryption
  class KeyDerivationService
    ITERATIONS = 600_000
    KEY_LENGTH = 32
    SALT_LENGTH = 32
    DIGEST = "sha256"

    def self.generate_salt
      OpenSSL::Random.random_bytes(SALT_LENGTH)
    end

    def self.derive_key(password:, salt:)
      OpenSSL::KDF.pbkdf2_hmac(
        password,
        salt: salt,
        iterations: ITERATIONS,
        length: KEY_LENGTH,
        hash: DIGEST
      )
    end
  end
end
