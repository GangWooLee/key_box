class VaultsController < ApplicationController
  def show
    @vault = current_user.personal_vault
    @folders = @vault.folders.ordered.includes(:secrets)
  end
end
