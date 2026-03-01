class Membership < ApplicationRecord
  # Enums
  enum :role, { owner: 0, admin: 1, member: 2, viewer: 3 }, prefix: true

  # Associations
  belongs_to :user
  belongs_to :vault

  # Validations
  validates :user_id, uniqueness: { scope: :vault_id }

  # Scopes
  scope :owners, -> { where(role: :owner) }
end
