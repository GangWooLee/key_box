require "test_helper"

class Secrets::RetrievalServiceTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    @vault = vaults(:personal_one)
    @mek = derive_mek_for_user(@user)
    @secret = create_test_secret("my-secret-value")
  end

  test "decrypts and returns secret value" do
    result = build_service.call

    assert result.success?
    assert_equal "my-secret-value", result.decrypted_value
    assert_equal @secret, result.secret
  end

  test "records access count" do
    assert_equal 0, @secret.access_count

    build_service.call

    @secret.reload
    assert_equal 1, @secret.access_count
    assert_not_nil @secret.last_accessed_at
  end

  test "creates audit event" do
    assert_difference "AuditEvent.count", 1 do
      build_service.call
    end

    event = AuditEvent.last
    assert_equal "secret.read", event.action
    assert_equal @secret, event.secret
  end

  test "fails with wrong encryption key" do
    wrong_key = OpenSSL::Random.random_bytes(32)
    result = Secrets::RetrievalService.new(
      secret: @secret,
      encryption_key: wrong_key,
      user: @user
    ).call

    assert_not result.success?
    assert_includes result.errors, "Decryption failed"
  end

  private

  def build_service
    Secrets::RetrievalService.new(
      secret: @secret,
      encryption_key: @mek,
      user: @user
    )
  end

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
