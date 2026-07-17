module Vaults
  class SetupService
    Result = Struct.new(:success?, :vault, :errors, keyword_init: true)

    def initialize(password:, password_confirmation:)
      @password = password
      @password_confirmation = password_confirmation
    end

    def call
      return already_setup_error if vault_exists?
      return password_mismatch_error unless passwords_match?
      return password_too_short_error unless password_long_enough?

      ActiveRecord::Base.transaction do
        vault = create_vault
        create_vault_config(vault)
        create_default_folder(vault)
        Result.new(success?: true, vault: vault, errors: [])
      end
    rescue ActiveRecord::RecordInvalid => e
      Result.new(success?: false, vault: nil, errors: e.record.errors.full_messages)
    end

    private

    attr_reader :password, :password_confirmation

    MIN_PASSWORD_LENGTH = 8

    def vault_exists?
      ::Vault.joins(:vault_config).exists?
    end

    def passwords_match?
      password == password_confirmation
    end

    def password_long_enough?
      password.to_s.length >= MIN_PASSWORD_LENGTH
    end

    def create_vault
      ::Vault.create!(name: "Personal", vault_type: :personal)
    end

    def create_vault_config(vault)
      salt = Encryption::KeyDerivationService.generate_salt
      pdk = Encryption::KeyDerivationService.derive_key(password: password, salt: salt)
      mek = Encryption::MasterKeyService.generate_master_key
      wrapped_mek = Encryption::MasterKeyService.wrap(master_key: mek, wrapping_key: pdk)

      VaultConfig.create!(
        vault: vault,
        master_key_salt: salt,
        encrypted_master_key: wrapped_mek,
        master_password: password,
        master_password_confirmation: password
      )
    end

    def create_default_folder(vault)
      Folder.create!(vault: vault, name: "General", icon: "folder", position: 0)
    end

    def already_setup_error
      Result.new(success?: false, vault: nil, errors: [ "KeyBox is already set up" ])
    end

    def password_mismatch_error
      Result.new(success?: false, vault: nil, errors: [ "Passwords do not match" ])
    end

    def password_too_short_error
      Result.new(success?: false, vault: nil, errors: [ "Password must be at least #{MIN_PASSWORD_LENGTH} characters" ])
    end
  end
end
