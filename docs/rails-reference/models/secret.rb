class Secret < ApplicationRecord
  # Constants
  MAX_NAME_LENGTH = 200
  MAX_NOTES_LENGTH = 2000
  MAX_TAGS_LENGTH = 500
  MAX_SERVICE_NAME_LENGTH = 100
  MAX_ENVIRONMENT_LENGTH = 50
  SECRET_TYPES = %w[api_key token password credential certificate ssh_key other].freeze
  ENVIRONMENTS = %w[production staging development test].freeze

  # Associations
  belongs_to :folder, counter_cache: true
  belongs_to :vault

  # Validations
  validates :name,
    presence: true,
    length: { maximum: MAX_NAME_LENGTH }
  validates :encrypted_value, presence: true
  validates :encrypted_value_iv, presence: true
  validates :encrypted_value_auth_tag, presence: true
  validates :notes,
    length: { maximum: MAX_NOTES_LENGTH }
  validates :tags,
    length: { maximum: MAX_TAGS_LENGTH }
  validates :secret_type,
    inclusion: { in: SECRET_TYPES }
  validates :service_name,
    length: { maximum: MAX_SERVICE_NAME_LENGTH }
  validates :environment,
    inclusion: { in: ENVIRONMENTS },
    allow_blank: true

  # Scopes
  scope :recent, -> { order(updated_at: :desc) }
  scope :by_type, ->(type) { where(secret_type: type) }
  scope :by_service, ->(service) { where(service_name: service) }
  scope :by_environment, ->(env) { where(environment: env) }
  scope :frequently_accessed, -> { order(access_count: :desc) }

  # Instance Methods
  def record_access!
    update_columns(
      last_accessed_at: Time.current,
      access_count: access_count + 1
    )
  end

  def tags_array
    return [] if tags.blank?
    tags.split(",").map(&:strip).reject(&:blank?)
  end

  def tags_array=(array)
    self.tags = Array(array).map(&:strip).reject(&:blank?).join(", ")
  end
end
