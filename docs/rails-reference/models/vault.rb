class Vault < ApplicationRecord
  # Constants
  MAX_NAME_LENGTH = 100
  MAX_DESCRIPTION_LENGTH = 500

  # Enums
  enum :vault_type, { personal: 0, team: 1 }, prefix: true

  # Associations
  has_one :vault_config, dependent: :destroy
  has_many :memberships, dependent: :destroy
  has_many :users, through: :memberships
  has_many :folders, dependent: :destroy
  has_many :secrets, dependent: :destroy
  has_many :audit_events, dependent: :destroy

  # Validations
  validates :name,
    presence: true,
    length: { maximum: MAX_NAME_LENGTH }
  validates :description,
    length: { maximum: MAX_DESCRIPTION_LENGTH }

  # Scopes
  scope :personal, -> { where(vault_type: :personal) }
  scope :team, -> { where(vault_type: :team) }

  # Instance Methods
  def owner
    memberships.find_by(role: :owner)&.user
  end
end
