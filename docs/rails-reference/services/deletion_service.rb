module Secrets
  class DeletionService
    Result = Struct.new(:success?, :errors, keyword_init: true)

    def initialize(secret:, vault:, request: nil)
      @secret = secret
      @vault = vault
      @request = request
    end

    def call
      name = secret.name
      vault_ref = secret.vault

      ActiveRecord::Base.transaction do
        secret.destroy!
      end

      log_audit(name, vault_ref)
      Result.new(success?: true, errors: [])
    rescue ActiveRecord::RecordNotDestroyed => e
      Result.new(success?: false, errors: [ e.message ])
    end

    private

    attr_reader :secret, :vault, :request

    def log_audit(name, vault_ref)
      Audit::EventLoggerService.new(vault: vault_ref, request: request)
        .log(action: "secret.delete", metadata: { name: name })
    end
  end
end
