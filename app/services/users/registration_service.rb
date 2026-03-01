module Users
  class RegistrationService
    Result = Struct.new(:success?, :user, :errors, keyword_init: true)

    def initialize(params:)
      @params = params
    end

    def call
      user = build_user
      unless user.valid?
        return Result.new(success?: false, user: user, errors: user.errors.full_messages)
      end

      ActiveRecord::Base.transaction do
        user.save!
        vault = create_personal_vault(user)
        create_default_folder(vault)
      end

      Result.new(success?: true, user: user, errors: [])
    rescue ActiveRecord::RecordInvalid => e
      Result.new(success?: false, user: e.record, errors: e.record.errors.full_messages)
    end

    private

    attr_reader :params

    def build_user
      salt = Encryption::KeyDerivationService.generate_salt
      pdk = Encryption::KeyDerivationService.derive_key(
        password: params[:password].to_s,
        salt: salt
      )
      mek = Encryption::MasterKeyService.generate_master_key
      wrapped_mek = Encryption::MasterKeyService.wrap(master_key: mek, wrapping_key: pdk)

      User.new(
        email: params[:email],
        name: params[:name],
        password: params[:password],
        password_confirmation: params[:password_confirmation],
        master_key_salt: salt,
        encrypted_master_key: wrapped_mek
      )
    end

    def create_personal_vault(user)
      vault = Vault.create!(name: "Personal", vault_type: :personal)
      Membership.create!(user: user, vault: vault, role: :owner)
      vault
    end

    def create_default_folder(vault)
      Folder.create!(vault: vault, name: "General", icon: "folder", position: 0)
    end
  end
end
