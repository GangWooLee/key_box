class RegistrationsController < ApplicationController
  skip_before_action :require_login, only: [ :new, :create ]

  def new
    redirect_to root_path if logged_in?
    @user = User.new
  end

  def create
    result = Users::RegistrationService.new(params: user_params).call

    if result.success?
      log_in(result.user, password: user_params[:password])
      redirect_to root_path, notice: "Welcome to KeyBox!"
    else
      @user = result.user
      render :new, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation)
  end
end
