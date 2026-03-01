class FoldersController < ApplicationController
  before_action :set_vault
  before_action :set_folder, only: [ :edit, :update, :destroy ]

  def index
    @folders = @vault.folders.ordered
  end

  def new
    @folder = @vault.folders.build
  end

  def create
    @folder = @vault.folders.build(folder_params)

    if @folder.save
      Audit::EventLoggerService.new(user: current_user, vault: @vault, request: request)
        .log(action: "folder.create", metadata: { name: @folder.name })
      redirect_to root_path, notice: "Folder created.", status: :see_other
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @folder.update(folder_params)
      Audit::EventLoggerService.new(user: current_user, vault: @vault, request: request)
        .log(action: "folder.update", metadata: { name: @folder.name })
      redirect_to root_path, notice: "Folder updated.", status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @folder.secrets.any?
      redirect_to root_path, alert: "Cannot delete folder with secrets. Move or delete them first."
    else
      name = @folder.name
      @folder.destroy!
      Audit::EventLoggerService.new(user: current_user, vault: @vault, request: request)
        .log(action: "folder.delete", metadata: { name: name })
      redirect_to root_path, notice: "Folder deleted.", status: :see_other
    end
  end

  private

  def set_vault
    @vault = current_user.personal_vault
  end

  def set_folder
    @folder = @vault.folders.find(params[:id])
  end

  def folder_params
    params.require(:folder).permit(:name, :icon)
  end
end
