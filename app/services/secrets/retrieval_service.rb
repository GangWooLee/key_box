module Secrets
  class RetrievalService
    Result = Struct.new(:success?, :secret, :decrypted_value, :errors, keyword_init: true)

    def initialize(secret:, encryption_key:, user:, request: nil)
      @secret = secret
      @encryption_key = encryption_key
      @user = user
      @request = request
    end

    def call
      decrypted = decrypt_value
      return Result.new(success?: false, secret: secret, decrypted_value: nil, errors: [ "Decryption failed" ]) unless decrypted

      secret.record_access!
      log_audit
      Result.new(success?: true, secret: secret, decrypted_value: decrypted, errors: [])
    end

    private

    attr_reader :secret, :encryption_key, :user, :request

    def decrypt_value
      Encryption::SecretEncryptionService.decrypt(
        encrypted_value: secret.encrypted_value,
        iv: secret.encrypted_value_iv,
        auth_tag: secret.encrypted_value_auth_tag,
        key: encryption_key
      )
    end

    def log_audit
      Audit::EventLoggerService.new(user: user, vault: secret.vault, request: request)
        .log(action: "secret.read", secret: secret)
    end
  end
end
