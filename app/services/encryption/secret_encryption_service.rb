module Encryption
  class SecretEncryptionService
    CIPHER = "aes-256-gcm"
    AUTH_TAG_LENGTH = 16

    def self.encrypt(value:, key:)
      cipher = OpenSSL::Cipher.new(CIPHER).encrypt
      cipher.key = key
      iv = cipher.random_iv
      cipher.auth_data = ""

      encrypted = cipher.update(value.to_s) + cipher.final
      auth_tag = cipher.auth_tag(AUTH_TAG_LENGTH)

      { encrypted_value: encrypted, iv: iv, auth_tag: auth_tag }
    end

    def self.decrypt(encrypted_value:, iv:, auth_tag:, key:)
      cipher = OpenSSL::Cipher.new(CIPHER).decrypt
      cipher.key = key
      cipher.iv = iv
      cipher.auth_tag = auth_tag
      cipher.auth_data = ""

      cipher.update(encrypted_value) + cipher.final
    rescue OpenSSL::Cipher::CipherError
      nil
    end
  end
end
