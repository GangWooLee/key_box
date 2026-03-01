module Secrets
  class SearchQuery
    MAX_RESULTS = 50

    def initialize(vault:)
      @relation = vault.secrets.includes(:folder)
    end

    def call(query:, filters: {})
      results = @relation
      results = apply_text_search(results, query) if query.present?
      results = apply_filters(results, filters)
      results.recent.limit(MAX_RESULTS)
    end

    private

    def apply_text_search(results, query)
      sanitized = "%#{sanitize_like(query)}%"
      results.where(
        "secrets.name LIKE :q OR secrets.service_name LIKE :q OR secrets.tags LIKE :q OR secrets.notes LIKE :q",
        q: sanitized
      )
    end

    def apply_filters(results, filters)
      results = results.by_type(filters[:secret_type]) if filters[:secret_type].present?
      results = results.by_environment(filters[:environment]) if filters[:environment].present?
      results = results.by_service(filters[:service_name]) if filters[:service_name].present?
      results = results.where(folder_id: filters[:folder_id]) if filters[:folder_id].present?
      results
    end

    def sanitize_like(query)
      query.gsub(/[%_\\]/) { |m| "\\#{m}" }
    end
  end
end
