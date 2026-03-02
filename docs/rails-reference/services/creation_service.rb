module Secrets
  class CreationService
    Result = Struct.new(:success?, :secret, :errors, keyword_init: true)

    def initialize(params:, folder:, vault:, encryption_key:, request: nil)
      @params = params
      @folder = folder
      @vault = vault
      @encryption_key = encryption_key
      @request = request
    end

    def call
      encrypted = encrypt_value
      return Result.new(success?: false, secret: nil, errors: [ "Encryption failed" ]) unless encrypted

      secret = build_secret(encrypted)
      unless secret.valid?
        return Result.new(success?: false, secret: secret, errors: secret.errors.full_messages)
      end

      ActiveRecord::Base.transaction do
        secret.save!
      end

      log_audit(secret)
      Result.new(success?: true, secret: secret, errors: [])
    rescue ActiveRecord::RecordInvalid => e
      Result.new(success?: false, secret: e.record, errors: e.record.errors.full_messages)
    end

    private

    attr_reader :params, :folder, :vault, :encryption_key, :request

    def encrypt_value
      return nil if params[:value].blank?

      Encryption::SecretEncryptionService.encrypt(
        value: params[:value],
        key: encryption_key
      )
    end

    def build_secret(encrypted)
      Secret.new(
        folder: folder,
        vault: vault,
        name: params[:name],
        encrypted_value: encrypted[:encrypted_value],
        encrypted_value_iv: encrypted[:iv],
        encrypted_value_auth_tag: encrypted[:auth_tag],
        secret_type: params[:secret_type].presence || "api_key",
        service_name: params[:service_name],
        environment: params[:environment],
        notes: params[:notes],
        tags: params[:tags]
      )
    end

    def log_audit(secret)
      Audit::EventLoggerService.new(vault: vault, request: request)
        .log(action: "secret.create", secret: secret, metadata: { name: secret.name })
    end
  end
end
