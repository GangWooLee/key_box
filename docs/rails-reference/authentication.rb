module Authentication
  extend ActiveSupport::Concern

  included do
    helper_method :current_vault, :vault_unlocked?, :vault_setup_complete?
    before_action :require_unlock
  end

  private

  def current_vault
    @current_vault ||= Vault.find_by(id: session[:vault_id])
  end

  def vault_unlocked?
    current_vault.present? && master_encryption_key.present?
  end

  def vault_setup_complete?
    Vault.joins(:vault_config).exists?
  end

  def require_unlock
    unless vault_unlocked?
      store_location
      if vault_setup_complete?
        redirect_to unlock_path, alert: "Please unlock KeyBox to continue."
      else
        redirect_to setup_path
      end
    end
  end

  def unlock_vault(password:)
    vault = Vault.joins(:vault_config).first
    return nil unless vault

    config = vault.vault_config
    return nil unless config.authenticate_master_password(password)

    reset_session
    session[:vault_id] = vault.id
    store_master_key_from_config(config, password: password)
    vault
  end

  def lock_vault
    reset_session
    @current_vault = nil
  end

  def master_encryption_key
    session[:mek]&.then { |encoded| Base64.strict_decode64(encoded) }
  end

  def store_location
    session[:forwarding_url] = request.original_url if request.get?
  end

  def redirect_back_or(default, **options)
    redirect_to(session.delete(:forwarding_url) || default, **options)
  end

  def store_master_key_from_config(config, password:)
    pdk = Encryption::KeyDerivationService.derive_key(
      password: password,
      salt: config.master_key_salt
    )
    mek = Encryption::MasterKeyService.unwrap(
      wrapped_key: config.encrypted_master_key,
      wrapping_key: pdk
    )
    session[:mek] = Base64.strict_encode64(mek)
  end
end
