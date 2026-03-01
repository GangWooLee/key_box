class SessionsController < ApplicationController
  skip_before_action :require_login, only: [ :new, :create ]

  def new
    redirect_to root_path if logged_in?
  end

  def create
    user = User.find_by(email: params[:email]&.downcase&.strip)

    if user&.authenticate(params[:password])
      log_in(user, password: params[:password])
      remember(user) if params[:remember_me] == "1"
      redirect_back_or root_path, status: :see_other
    else
      flash.now[:alert] = "Invalid email or password."
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    forget(current_user) if logged_in?
    log_out
    redirect_to login_path, status: :see_other
  end
end
