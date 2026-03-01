require "test_helper"

class Secrets::UpdateServiceTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    @vault = vaults(:personal_one)
    @mek = derive_mek_for_user(@user)
    @secret = create_test_secret("original-value")
  end

  test "updates metadata without changing encrypted value" do
    result = Secrets::UpdateService.new(
      secret: @secret,
      params: { name: "Updated Name", notes: "New notes" },
      encryption_key: @mek,
      user: @user
    ).call

    assert result.success?
    @secret.reload
    assert_equal "Updated Name", @secret.name
    assert_equal "New notes", @secret.notes

    # Verify original value unchanged
    decrypted = Encryption::SecretEncryptionService.decrypt(
      encrypted_value: @secret.encrypted_value,
      iv: @secret.encrypted_value_iv,
      auth_tag: @secret.encrypted_value_auth_tag,
      key: @mek
    )
    assert_equal "original-value", decrypted
  end

  test "re-encrypts when new value provided" do
    result = Secrets::UpdateService.new(
      secret: @secret,
      params: { value: "new-secret-value" },
      encryption_key: @mek,
      user: @user
    ).call

    assert result.success?
    @secret.reload

    decrypted = Encryption::SecretEncryptionService.decrypt(
      encrypted_value: @secret.encrypted_value,
      iv: @secret.encrypted_value_iv,
      auth_tag: @secret.encrypted_value_auth_tag,
      key: @mek
    )
    assert_equal "new-secret-value", decrypted
  end

  test "creates audit event" do
    assert_difference "AuditEvent.count", 1 do
      Secrets::UpdateService.new(
        secret: @secret,
        params: { name: "Updated" },
        encryption_key: @mek,
        user: @user
      ).call
    end

    assert_equal "secret.update", AuditEvent.last.action
  end

  test "fails with invalid name" do
    result = Secrets::UpdateService.new(
      secret: @secret,
      params: { name: "" },
      encryption_key: @mek,
      user: @user
    ).call

    assert_not result.success?
  end

  test "updates folder assignment" do
    new_folder = Folder.create!(vault: @vault, name: "New Folder", position: 1)

    result = Secrets::UpdateService.new(
      secret: @secret,
      params: { folder_id: new_folder.id },
      encryption_key: @mek,
      user: @user
    ).call

    assert result.success?
    @secret.reload
    assert_equal new_folder, @secret.folder
  end

  private

  def create_test_secret(value)
    encrypted = Encryption::SecretEncryptionService.encrypt(value: value, key: @mek)

    Secret.create!(
      folder: folders(:general_one),
      vault: @vault,
      name: "Test Secret",
      encrypted_value: encrypted[:encrypted_value],
      encrypted_value_iv: encrypted[:iv],
      encrypted_value_auth_tag: encrypted[:auth_tag]
    )
  end

  def derive_mek_for_user(user)
    pdk = Encryption::KeyDerivationService.derive_key(password: "password123", salt: user.master_key_salt)
    Encryption::MasterKeyService.unwrap(wrapped_key: user.encrypted_master_key, wrapping_key: pdk)
  end
end
