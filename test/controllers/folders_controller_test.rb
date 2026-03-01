require "test_helper"

class FoldersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @vault = @user.personal_vault
    log_in_as(@user)
  end

  test "should get new" do
    get new_vault_folder_url(@vault)
    assert_response :success
  end

  test "should create folder" do
    assert_difference "Folder.count", 1 do
      post vault_folders_url(@vault), params: { folder: { name: "Production Keys" } }
    end
    assert_redirected_to root_url
  end

  test "should create folder audit event" do
    assert_difference "AuditEvent.count", 1 do
      post vault_folders_url(@vault), params: { folder: { name: "Audit Test" } }
    end
    assert_equal "folder.create", AuditEvent.last.action
  end

  test "should not create folder with blank name" do
    assert_no_difference "Folder.count" do
      post vault_folders_url(@vault), params: { folder: { name: "" } }
    end
    assert_response :unprocessable_entity
  end

  test "should not create folder with duplicate name" do
    assert_no_difference "Folder.count" do
      post vault_folders_url(@vault), params: { folder: { name: "General" } }
    end
    assert_response :unprocessable_entity
  end

  test "should get edit" do
    folder = @vault.folders.first
    get edit_vault_folder_url(@vault, folder)
    assert_response :success
  end

  test "should update folder" do
    folder = @vault.folders.first
    patch vault_folder_url(@vault, folder), params: { folder: { name: "Renamed" } }
    assert_redirected_to root_url
    folder.reload
    assert_equal "Renamed", folder.name
  end

  test "should destroy empty folder" do
    folder = Folder.create!(vault: @vault, name: "Empty Folder", position: 1)
    assert_difference "Folder.count", -1 do
      delete vault_folder_url(@vault, folder)
    end
    assert_redirected_to root_url
  end

  test "should not destroy folder with secrets" do
    folder = @vault.folders.first
    mek = derive_mek_for_user(@user)
    encrypted = Encryption::SecretEncryptionService.encrypt(value: "x", key: mek)
    Secret.create!(
      folder: folder, vault: @vault, name: "Test",
      encrypted_value: encrypted[:encrypted_value],
      encrypted_value_iv: encrypted[:iv],
      encrypted_value_auth_tag: encrypted[:auth_tag]
    )

    assert_no_difference "Folder.count" do
      delete vault_folder_url(@vault, folder)
    end
    assert_redirected_to root_url
    assert_equal "Cannot delete folder with secrets. Move or delete them first.", flash[:alert]
  end

  test "should not access other vault folders" do
    other_folder = folders(:general_two)

    get edit_vault_folder_url(@vault, other_folder)
    assert_response :not_found
  end

  test "should redirect to login when not logged in" do
    delete logout_url
    get new_vault_folder_url(@vault)
    assert_redirected_to login_url
  end

  private

  def derive_mek_for_user(user)
    pdk = Encryption::KeyDerivationService.derive_key(password: "password123", salt: user.master_key_salt)
    Encryption::MasterKeyService.unwrap(wrapped_key: user.encrypted_master_key, wrapping_key: pdk)
  end
end
