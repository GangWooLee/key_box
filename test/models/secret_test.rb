require "test_helper"

class SecretTest < ActiveSupport::TestCase
  setup do
    @folder = folders(:general_one)
    @vault = vaults(:personal_one)
    mek = Encryption::MasterKeyService.generate_master_key
    result = Encryption::SecretEncryptionService.encrypt(value: "sk-test-123", key: mek)

    @secret = Secret.new(
      folder: @folder,
      vault: @vault,
      name: "Stripe API Key",
      encrypted_value: result[:encrypted_value],
      encrypted_value_iv: result[:iv],
      encrypted_value_auth_tag: result[:auth_tag],
      secret_type: "api_key",
      service_name: "Stripe",
      environment: "production",
      tags: "payment, stripe"
    )
  end

  # ===== Validations =====
  test "should be valid with valid attributes" do
    assert @secret.valid?
  end

  test "should require name" do
    @secret.name = nil
    assert_not @secret.valid?
  end

  test "should enforce name length limit" do
    @secret.name = "a" * 201
    assert_not @secret.valid?
  end

  test "should require encrypted_value" do
    @secret.encrypted_value = nil
    assert_not @secret.valid?
  end

  test "should require encrypted_value_iv" do
    @secret.encrypted_value_iv = nil
    assert_not @secret.valid?
  end

  test "should require encrypted_value_auth_tag" do
    @secret.encrypted_value_auth_tag = nil
    assert_not @secret.valid?
  end

  test "should validate secret_type inclusion" do
    @secret.secret_type = "invalid_type"
    assert_not @secret.valid?
  end

  test "should validate environment inclusion" do
    @secret.environment = "invalid_env"
    assert_not @secret.valid?
  end

  test "should allow blank environment" do
    @secret.environment = nil
    assert @secret.valid?
  end

  test "should enforce notes length limit" do
    @secret.notes = "a" * 2001
    assert_not @secret.valid?
  end

  # ===== Associations =====
  test "should belong to folder" do
    assert_respond_to @secret, :folder
  end

  test "should belong to vault" do
    assert_respond_to @secret, :vault
  end

  # ===== Instance Methods =====
  test "should record access" do
    @secret.save!
    assert_equal 0, @secret.access_count

    @secret.record_access!
    @secret.reload
    assert_equal 1, @secret.access_count
    assert_not_nil @secret.last_accessed_at
  end

  test "should parse tags array" do
    assert_equal [ "payment", "stripe" ], @secret.tags_array
  end

  test "should handle empty tags" do
    @secret.tags = nil
    assert_equal [], @secret.tags_array
  end

  test "should set tags from array" do
    @secret.tags_array = [ "aws", "iam", "production" ]
    assert_equal "aws, iam, production", @secret.tags
  end
end
