class AuditEvent < ApplicationRecord
  # Constants
  ACTIONS = %w[
    secret.create secret.read secret.update secret.delete secret.copy
    vault.create vault.update
    folder.create folder.update folder.delete
    user.login user.logout user.signup
  ].freeze

  # Associations
  belongs_to :user
  belongs_to :vault
  belongs_to :secret, optional: true

  # Validations
  validates :action,
    presence: true,
    inclusion: { in: ACTIONS },
    length: { maximum: 50 }
  validates :ip_address,
    length: { maximum: 45 }
  validates :user_agent,
    length: { maximum: 500 }

  # Scopes
  scope :recent, -> { order(created_at: :desc) }
  scope :by_action, ->(action) { where(action: action) }
  scope :for_secret, ->(secret) { where(secret: secret) }

  # Immutable — prevent updates and deletes
  before_update { raise ActiveRecord::ReadOnlyRecord }
  before_destroy { raise ActiveRecord::ReadOnlyRecord }
end
