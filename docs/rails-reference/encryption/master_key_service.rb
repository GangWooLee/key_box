module Encryption
  class MasterKeyService
    MEK_LENGTH = 32
    IV_LENGTH = 12
    AUTH_TAG_LENGTH = 16
    CIPHER = "aes-256-gcm"

    def self.generate_master_key
      OpenSSL::Random.random_bytes(MEK_LENGTH)
    end

    def self.wrap(master_key:, wrapping_key:)
      cipher = OpenSSL::Cipher.new(CIPHER).encrypt
      cipher.key = wrapping_key
      iv = cipher.random_iv
      cipher.auth_data = ""

      encrypted = cipher.update(master_key) + cipher.final
      auth_tag = cipher.auth_tag(AUTH_TAG_LENGTH)

      iv + auth_tag + encrypted
    end

    def self.unwrap(wrapped_key:, wrapping_key:)
      iv = wrapped_key[0, IV_LENGTH]
      auth_tag = wrapped_key[IV_LENGTH, AUTH_TAG_LENGTH]
      encrypted = wrapped_key[(IV_LENGTH + AUTH_TAG_LENGTH)..]

      cipher = OpenSSL::Cipher.new(CIPHER).decrypt
      cipher.key = wrapping_key
      cipher.iv = iv
      cipher.auth_tag = auth_tag
      cipher.auth_data = ""

      cipher.update(encrypted) + cipher.final
    rescue OpenSSL::Cipher::CipherError
      nil
    end
  end
end
