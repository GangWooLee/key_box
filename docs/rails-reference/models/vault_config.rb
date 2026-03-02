class VaultConfig < ApplicationRecord
  # Authentication (bcrypt digest for master password verification)
  has_secure_password :master_password

  # Associations
  belongs_to :vault

  # Validations
  validates :master_key_salt, presence: true
  validates :encrypted_master_key, presence: true
  validates :master_password,
    length: { minimum: 8 },
    if: -> { new_record? || master_password.present? }
end
