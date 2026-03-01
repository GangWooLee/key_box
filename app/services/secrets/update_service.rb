module Secrets
  class UpdateService
    Result = Struct.new(:success?, :secret, :errors, keyword_init: true)

    def initialize(secret:, params:, encryption_key:, user:, request: nil)
      @secret = secret
      @params = params
      @encryption_key = encryption_key
      @user = user
      @request = request
    end

    def call
      if params[:value].present?
        encrypted = encrypt_value
        return Result.new(success?: false, secret: secret, errors: [ "Encryption failed" ]) unless encrypted
        assign_encrypted_attributes(encrypted)
      end

      assign_metadata_attributes

      unless secret.valid?
        return Result.new(success?: false, secret: secret, errors: secret.errors.full_messages)
      end

      ActiveRecord::Base.transaction do
        secret.save!
      end

      log_audit
      Result.new(success?: true, secret: secret, errors: [])
    rescue ActiveRecord::RecordInvalid => e
      Result.new(success?: false, secret: e.record, errors: e.record.errors.full_messages)
    end

    private

    attr_reader :secret, :params, :encryption_key, :user, :request

    def encrypt_value
      Encryption::SecretEncryptionService.encrypt(
        value: params[:value],
        key: encryption_key
      )
    end

    def assign_encrypted_attributes(encrypted)
      secret.encrypted_value = encrypted[:encrypted_value]
      secret.encrypted_value_iv = encrypted[:iv]
      secret.encrypted_value_auth_tag = encrypted[:auth_tag]
    end

    def assign_metadata_attributes
      secret.name = params[:name] if params.key?(:name)
      secret.secret_type = params[:secret_type] if params.key?(:secret_type)
      secret.service_name = params[:service_name] if params.key?(:service_name)
      secret.environment = params[:environment] if params.key?(:environment)
      secret.notes = params[:notes] if params.key?(:notes)
      secret.tags = params[:tags] if params.key?(:tags)
      secret.folder_id = params[:folder_id] if params.key?(:folder_id)
    end

    def log_audit
      Audit::EventLoggerService.new(user: user, vault: secret.vault, request: request)
        .log(action: "secret.update", secret: secret, metadata: { name: secret.name })
    end
  end
end
