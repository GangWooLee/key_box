require "test_helper"

class SecretsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @vault = @user.personal_vault
    @folder = folders(:general_one)
    log_in_as(@user)
    @mek = session_mek
  end

  # ===== Index =====
  test "should get index" do
    get secrets_url
    assert_response :success
  end

  # ===== New =====
  test "should get new" do
    get new_secret_url
    assert_response :success
  end

  # ===== Create =====
  test "should create secret" do
    assert_difference [ "Secret.count", "AuditEvent.count" ] do
      post secrets_url, params: { secret: {
        name: "New API Key",
        value: "sk-test-123",
        secret_type: "api_key",
        service_name: "TestService",
        folder_id: @folder.id
      } }
    end

    secret = Secret.last
    assert_redirected_to secret_url(secret)
    assert_equal "New API Key", secret.name

    # Verify encrypted
    decrypted = decrypt_secret(secret)
    assert_equal "sk-test-123", decrypted
  end

  test "should not create secret with blank value" do
    assert_no_difference "Secret.count" do
      post secrets_url, params: { secret: {
        name: "Test", value: "", folder_id: @folder.id
      } }
    end
    assert_response :unprocessable_entity
  end

  test "should not create secret with blank name" do
    assert_no_difference "Secret.count" do
      post secrets_url, params: { secret: {
        name: "", value: "test", folder_id: @folder.id
      } }
    end
    assert_response :unprocessable_entity
  end

  # ===== Show =====
  test "should show secret" do
    secret = create_test_secret

    get secret_url(secret)
    assert_response :success
  end

  test "should not show secret from another vault" do
    other_user = users(:two)
    other_vault = other_user.personal_vault
    other_mek = derive_mek_for_user(other_user)
    encrypted = Encryption::SecretEncryptionService.encrypt(value: "x", key: other_mek)
    other_secret = Secret.create!(
      folder: folders(:general_two), vault: other_vault, name: "Other",
      encrypted_value: encrypted[:encrypted_value],
      encrypted_value_iv: encrypted[:iv],
      encrypted_value_auth_tag: encrypted[:auth_tag]
    )

    get secret_url(other_secret)
    assert_response :not_found
  end

  # ===== Edit =====
  test "should get edit" do
    secret = create_test_secret

    get edit_secret_url(secret)
    assert_response :success
  end

  # ===== Update =====
  test "should update secret metadata" do
    secret = create_test_secret

    patch secret_url(secret), params: { secret: {
      name: "Updated Name",
      notes: "Updated notes",
      folder_id: @folder.id
    } }

    assert_redirected_to secret_url(secret)
    secret.reload
    assert_equal "Updated Name", secret.name
  end

  test "should update secret value" do
    secret = create_test_secret

    patch secret_url(secret), params: { secret: {
      name: secret.name,
      value: "new-encrypted-value",
      folder_id: @folder.id
    } }

    assert_redirected_to secret_url(secret)
    secret.reload
    decrypted = decrypt_secret(secret)
    assert_equal "new-encrypted-value", decrypted
  end

  # ===== Destroy =====
  test "should destroy secret" do
    secret = create_test_secret

    assert_difference "Secret.count", -1 do
      delete secret_url(secret)
    end
    assert_redirected_to secrets_url
  end

  # ===== Copy =====
  test "should copy secret value as JSON" do
    secret = create_test_secret("copy-me")

    post copy_secret_url(secret), headers: { "Accept" => "application/json" }
    assert_response :success

    json = JSON.parse(response.body)
    assert_equal "copy-me", json["value"]
  end

  # ===== Auth =====
  test "should redirect to login when not logged in" do
    delete logout_url
    get secrets_url
    assert_redirected_to login_url
  end

  private

  def create_test_secret(value = "test-secret-value")
    mek = derive_mek_for_user(@user)
    encrypted = Encryption::SecretEncryptionService.encrypt(value: value, key: mek)

    Secret.create!(
      folder: @folder,
      vault: @vault,
      name: "Test Secret #{SecureRandom.hex(4)}",
      encrypted_value: encrypted[:encrypted_value],
      encrypted_value_iv: encrypted[:iv],
      encrypted_value_auth_tag: encrypted[:auth_tag]
    )
  end

  def decrypt_secret(secret)
    mek = derive_mek_for_user(@user)
    Encryption::SecretEncryptionService.decrypt(
      encrypted_value: secret.encrypted_value,
      iv: secret.encrypted_value_iv,
      auth_tag: secret.encrypted_value_auth_tag,
      key: mek
    )
  end

  def derive_mek_for_user(user)
    pdk = Encryption::KeyDerivationService.derive_key(password: "password123", salt: user.master_key_salt)
    Encryption::MasterKeyService.unwrap(wrapped_key: user.encrypted_master_key, wrapping_key: pdk)
  end

  def session_mek
    derive_mek_for_user(@user)
  end
end
