require "test_helper"
require "ostruct"

class Audit::EventLoggerServiceTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    @vault = vaults(:personal_one)
    @service = Audit::EventLoggerService.new(user: @user, vault: @vault)
  end

  test "logs audit event with valid action" do
    assert_difference "AuditEvent.count", 1 do
      event = @service.log(action: "secret.create", metadata: { name: "Test" })
      assert event.persisted?
      assert_equal "secret.create", event.action
      assert_equal @user, event.user
      assert_equal @vault, event.vault
      assert_equal({ "name" => "Test" }, event.metadata)
    end
  end

  test "logs audit event with secret reference" do
    secret = create_test_secret
    event = @service.log(action: "secret.read", secret: secret)

    assert event.persisted?
    assert_equal secret, event.secret
  end

  test "logs IP and user agent from request" do
    mock_request = OpenStruct.new(remote_ip: "192.168.1.1", user_agent: "TestBrowser/1.0")
    service = Audit::EventLoggerService.new(user: @user, vault: @vault, request: mock_request)

    event = service.log(action: "secret.create")
    assert_equal "192.168.1.1", event.ip_address
    assert_equal "TestBrowser/1.0", event.user_agent
  end

  test "handles nil request gracefully" do
    event = @service.log(action: "secret.create")

    assert event.persisted?
    assert_nil event.ip_address
    assert_nil event.user_agent
  end

  test "returns nil on invalid action without raising" do
    result = @service.log(action: "invalid.action")
    assert_nil result
  end

  test "truncates long user agent" do
    long_agent = "A" * 600
    mock_request = OpenStruct.new(remote_ip: "127.0.0.1", user_agent: long_agent)
    service = Audit::EventLoggerService.new(user: @user, vault: @vault, request: mock_request)

    event = service.log(action: "secret.create")
    assert event.persisted?
    assert event.user_agent.length <= 500
  end

  private

  def create_test_secret
    mek = derive_mek_for_user(@user)
    encrypted = Encryption::SecretEncryptionService.encrypt(value: "test", key: mek)

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
