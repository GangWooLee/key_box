require "test_helper"

class Secrets::DeletionServiceTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    @vault = vaults(:personal_one)
    @mek = derive_mek_for_user(@user)
    @secret = create_test_secret
  end

  test "deletes the secret" do
    assert_difference "Secret.count", -1 do
      result = Secrets::DeletionService.new(secret: @secret, user: @user).call
      assert result.success?
    end
  end

  test "creates audit event after deletion" do
    assert_difference "AuditEvent.count", 1 do
      Secrets::DeletionService.new(secret: @secret, user: @user).call
    end

    event = AuditEvent.last
    assert_equal "secret.delete", event.action
    assert_equal({ "name" => "Test Secret" }, event.metadata)
    assert_nil event.secret_id
  end

  test "decrements folder counter cache" do
    folder = @secret.folder
    initial_count = folder.secrets_count

    Secrets::DeletionService.new(secret: @secret, user: @user).call
    folder.reload

    assert_equal initial_count - 1, folder.secrets_count
  end

  private

  def create_test_secret
    encrypted = Encryption::SecretEncryptionService.encrypt(value: "test", key: @mek)

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
