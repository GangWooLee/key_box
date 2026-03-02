module Audit
  class EventLoggerService
    def initialize(vault:, request: nil)
      @vault = vault
      @request = request
    end

    def log(action:, secret: nil, metadata: {})
      AuditEvent.create!(
        vault: @vault,
        secret: secret,
        action: action,
        ip_address: @request&.remote_ip,
        user_agent: truncate_user_agent(@request&.user_agent),
        metadata: metadata
      )
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.error "[AUDIT] Failed to log #{action}: #{e.message}"
      nil
    end

    private

    def truncate_user_agent(agent)
      return nil if agent.nil?
      agent.truncate(500)
    end
  end
end
