module Authentication
  extend ActiveSupport::Concern

  included do
    helper_method :current_user, :logged_in?
    before_action :require_login
  end

  private

  def current_user
    @current_user ||= find_current_user
  end

  def logged_in?
    current_user.present?
  end

  def require_login
    unless logged_in?
      store_location
      redirect_to login_path, alert: "Please log in to continue."
    end
  end

  def log_in(user, password:)
    reset_session
    session[:user_id] = user.id
    store_master_key(user, password: password)
    user.record_login(ip: request.remote_ip)
  end

  def log_out
    reset_session
    @current_user = nil
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

  def find_current_user
    if session[:user_id]
      User.find_by(id: session[:user_id])
    elsif cookies.encrypted[:remember_token].present?
      user = User.find_by(id: cookies.encrypted[:user_id])
      if user&.remembered?(cookies.encrypted[:remember_token])
        log_in_from_remember(user)
        user
      end
    end
  end

  def store_master_key(user, password:)
    pdk = Encryption::KeyDerivationService.derive_key(
      password: password,
      salt: user.master_key_salt
    )
    mek = Encryption::MasterKeyService.unwrap(
      wrapped_key: user.encrypted_master_key,
      wrapping_key: pdk
    )
    session[:mek] = Base64.strict_encode64(mek)
  end

  def log_in_from_remember(user)
    session[:user_id] = user.id
  end

  def remember(user)
    token = user.remember
    cookies.encrypted[:user_id] = {
      value: user.id,
      expires: 30.days.from_now,
      httponly: true,
      secure: Rails.env.production?
    }
    cookies.encrypted[:remember_token] = {
      value: token,
      expires: 30.days.from_now,
      httponly: true,
      secure: Rails.env.production?
    }
  end

  def forget(user)
    user.forget
    cookies.delete(:user_id)
    cookies.delete(:remember_token)
  end
end
