module Secrets
  class DeletionService
    Result = Struct.new(:success?, :errors, keyword_init: true)

    def initialize(secret:, user:, request: nil)
      @secret = secret
      @user = user
      @request = request
    end

    def call
      name = secret.name
      vault = secret.vault

      ActiveRecord::Base.transaction do
        secret.destroy!
      end

      log_audit(name, vault)
      Result.new(success?: true, errors: [])
    rescue ActiveRecord::RecordNotDestroyed => e
      Result.new(success?: false, errors: [ e.message ])
    end

    private

    attr_reader :secret, :user, :request

    def log_audit(name, vault)
      Audit::EventLoggerService.new(user: user, vault: vault, request: request)
        .log(action: "secret.delete", metadata: { name: name })
    end
  end
end
