class Folder < ApplicationRecord
  # Constants
  MAX_NAME_LENGTH = 100
  DEFAULT_ICON = "folder"

  # Associations
  belongs_to :vault
  has_many :secrets, dependent: :destroy

  # Validations
  validates :name,
    presence: true,
    length: { maximum: MAX_NAME_LENGTH },
    uniqueness: { scope: :vault_id }
  validates :icon,
    length: { maximum: 50 }

  # Scopes
  scope :ordered, -> { order(position: :asc) }
end
