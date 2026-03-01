class User < ApplicationRecord
  # Constants
  MAX_NAME_LENGTH = 50
  MAX_IP_LENGTH = 45

  # Authentication
  has_secure_password

  # Associations
  has_many :memberships, dependent: :destroy
  has_many :vaults, through: :memberships
  has_many :audit_events, dependent: :destroy

  # Validations
  validates :email,
    presence: true,
    uniqueness: { case_sensitive: false },
    format: { with: URI::MailTo::EMAIL_REGEXP },
    length: { maximum: 255 }
  validates :name,
    presence: true,
    length: { maximum: MAX_NAME_LENGTH }
  validates :password,
    length: { minimum: 8 },
    if: -> { new_record? || password.present? }
  validates :master_key_salt, presence: true
  validates :encrypted_master_key, presence: true

  # Callbacks
  before_validation :downcase_email

  # Scopes
  scope :recent, -> { order(created_at: :desc) }

  # Instance Methods
  def personal_vault
    vaults.joins(:memberships)
          .where(vault_type: :personal, memberships: { role: :owner })
          .first
  end

  def remember
    token = SecureRandom.urlsafe_base64
    update_column(:remember_digest, BCrypt::Password.create(token, cost: 12))
    token
  end

  def forget
    update_column(:remember_digest, nil)
  end

  def remembered?(token)
    return false unless remember_digest.present?
    BCrypt::Password.new(remember_digest).is_password?(token)
  end

  def record_login(ip:)
    update_columns(last_login_at: Time.current, last_login_ip: ip)
  end

  private

  def downcase_email
    self.email = email&.downcase&.strip
  end
end
