class SecretsController < ApplicationController
  before_action :require_encryption_key
  before_action :set_vault
  before_action :set_secret, only: [ :show, :edit, :update, :destroy, :copy ]

  def index
    @folders = @vault.folders.ordered.includes(:secrets)
    @secrets = @vault.secrets.includes(:folder).recent
  end

  def show
    result = Secrets::RetrievalService.new(
      secret: @secret,
      encryption_key: master_encryption_key,
      user: current_user,
      request: request
    ).call

    if result.success?
      @decrypted_value = result.decrypted_value
    else
      redirect_to secrets_path, alert: "Unable to decrypt secret."
    end
  end

  def new
    @secret = Secret.new(folder_id: params[:folder_id])
    @folders = @vault.folders.ordered
  end

  def create
    result = Secrets::CreationService.new(
      params: secret_params,
      folder: @vault.folders.find(secret_params[:folder_id]),
      vault: @vault,
      encryption_key: master_encryption_key,
      user: current_user,
      request: request
    ).call

    if result.success?
      redirect_to result.secret, notice: "Secret saved", status: :see_other
    else
      @secret = result.secret || Secret.new(secret_params.except(:value))
      @folders = @vault.folders.ordered
      flash.now[:alert] = result.errors.join(", ")
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @folders = @vault.folders.ordered
  end

  def update
    result = Secrets::UpdateService.new(
      secret: @secret,
      params: secret_params,
      encryption_key: master_encryption_key,
      user: current_user,
      request: request
    ).call

    if result.success?
      redirect_to result.secret, notice: "Secret updated", status: :see_other
    else
      @folders = @vault.folders.ordered
      flash.now[:alert] = result.errors.join(", ")
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    result = Secrets::DeletionService.new(
      secret: @secret,
      user: current_user,
      request: request
    ).call

    if result.success?
      if turbo_frame_request?
        render turbo_stream: [
          turbo_stream.update("secret_detail", partial: "secrets/detail_empty"),
          turbo_stream.remove("secret_item_#{@secret.id}")
        ]
      else
        redirect_to secrets_path, notice: "Secret deleted.", status: :see_other
      end
    else
      redirect_to @secret, alert: result.errors.join(", ")
    end
  end

  def copy
    result = Secrets::RetrievalService.new(
      secret: @secret,
      encryption_key: master_encryption_key,
      user: current_user,
      request: request
    ).call

    if result.success?
      Audit::EventLoggerService.new(user: current_user, vault: @vault, request: request)
        .log(action: "secret.copy", secret: @secret)
      render json: { value: result.decrypted_value }
    else
      render json: { error: "Unable to decrypt secret." }, status: :unprocessable_entity
    end
  end

  private

  def require_encryption_key
    unless master_encryption_key
      redirect_to login_path, alert: "Please log in again to access secrets."
    end
  end

  def set_vault
    @vault = current_user.personal_vault
  end

  def set_secret
    @secret = @vault.secrets.find(params[:id])
  end

  def secret_params
    params.require(:secret).permit(
      :name, :value, :secret_type, :service_name,
      :environment, :notes, :tags, :folder_id
    )
  end
end
