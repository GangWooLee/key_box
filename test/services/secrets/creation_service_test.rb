require "test_helper"

class Secrets::CreationServiceTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    @vault = vaults(:personal_one)
    @folder = folders(:general_one)
    @mek = derive_mek_for_user(@user)
  end

  test "creates secret with encrypted value" do
    params = {
      name: "GitHub Token",
      value: "ghp_abc123",
      secret_type: "token",
      service_name: "GitHub",
      environment: "production",
      notes: "Main repo access",
      tags: "github, ci"
    }

    result = build_service(params).call

    assert result.success?
    assert result.secret.persisted?
    assert_equal "GitHub Token", result.secret.name
    assert_equal "token", result.secret.secret_type
    assert_equal "GitHub", result.secret.service_name
    assert_equal "production", result.secret.environment

    # Verify encryption
    decrypted = Encryption::SecretEncryptionService.decrypt(
      encrypted_value: result.secret.encrypted_value,
      iv: result.secret.encrypted_value_iv,
      auth_tag: result.secret.encrypted_value_auth_tag,
      key: @mek
    )
    assert_equal "ghp_abc123", decrypted
  end

  test "creates audit event on success" do
    params = { name: "Test", value: "secret123", folder_id: @folder.id }

    assert_difference "AuditEvent.count", 1 do
      build_service(params).call
    end

    event = AuditEvent.last
    assert_equal "secret.create", event.action
  end

  test "fails with blank value" do
    params = { name: "Test", value: "", folder_id: @folder.id }
    result = build_service(params).call

    assert_not result.success?
    assert_includes result.errors, "Encryption failed"
  end

  test "fails with invalid name" do
    params = { name: "", value: "secret123", folder_id: @folder.id }
    result = build_service(params).call

    assert_not result.success?
    assert result.errors.any? { |e| e.include?("Name") }
  end

  test "defaults secret_type to api_key" do
    params = { name: "Test", value: "secret123", folder_id: @folder.id }
    result = build_service(params).call

    assert result.success?
    assert_equal "api_key", result.secret.secret_type
  end

  private

  def build_service(params)
    Secrets::CreationService.new(
      params: params,
      folder: @folder,
      vault: @vault,
      encryption_key: @mek,
      user: @user
    )
  end

  def derive_mek_for_user(user)
    pdk = Encryption::KeyDerivationService.derive_key(password: "password123", salt: user.master_key_salt)
    Encryption::MasterKeyService.unwrap(wrapped_key: user.encrypted_master_key, wrapping_key: pdk)
  end
end
