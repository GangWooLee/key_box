class SearchController < ApplicationController
  before_action :require_encryption_key

  def index
    @vault = current_user.personal_vault

    if params[:q].present?
      @secrets = Secrets::SearchQuery.new(vault: @vault).call(
        query: params[:q],
        filters: search_filters
      )
    else
      @secrets = Secret.none
    end

    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  private

  def require_encryption_key
    unless master_encryption_key
      redirect_to login_path, alert: "Please log in again to access secrets."
    end
  end

  def search_filters
    {
      secret_type: params[:secret_type],
      environment: params[:environment],
      folder_id: params[:folder_id]
    }
  end
end
