require "application_system_test_case"

class SecretsTest < ApplicationSystemTestCase
  setup do
    @user = users(:one)
    @vault = @user.personal_vault
    @folder = folders(:general_one)
  end

  # ===== Create =====
  test "user creates a new secret" do
    sign_in_as(@user)

    click_link "New"
    assert_selector "[data-controller='reveal']", wait: 5
    assert_current_path new_secret_path

    fill_in "Name", with: "My GitHub Token"
    fill_in "Secret Value", with: "ghp_test1234567890"
    select "General", from: "Folder"
    select "Api key", from: "Type"
    fill_in "Service", with: "GitHub"

    click_button "Create Secret"

    assert_text "My GitHub Token", wait: 5
    assert_text "Secret saved", wait: 5
  end

  # ===== Search =====
  test "user searches secrets" do
    secret = create_test_secret(name: "AWS Access Key #{SecureRandom.hex(4)}")

    sign_in_as(@user)

    visit search_path
    assert_selector "[data-controller='search']", wait: 5

    fill_in "q", with: "AWS"
    assert_text "result", wait: 5
    assert_text secret.name, wait: 5
  end

  # ===== Show =====
  test "user views secret details" do
    secret = create_test_secret(name: "Detail Test Secret #{SecureRandom.hex(4)}")

    sign_in_as(@user)

    visit secrets_path
    assert_selector "#secret_list", wait: 5

    click_link secret.name
    assert_text secret.name, wait: 5
    assert_selector "[data-controller~='reveal']", wait: 5
  end

  # ===== Audit Log =====
  test "audit log shows activity after viewing a secret" do
    secret = create_test_secret(name: "Audit Test Secret #{SecureRandom.hex(4)}")

    sign_in_as(@user)

    # Visit the secret to generate an audit event
    visit secret_path(secret)
    assert_text secret.name, wait: 5

    # Navigate to audit log
    visit vault_audit_events_path(@vault)
    assert_text "Audit Log", wait: 5
    assert_text "secret.read", wait: 5
    assert_text secret.name, wait: 5
  end

  private

  def create_test_secret(name: "Test Secret #{SecureRandom.hex(4)}", value: "test-secret-value")
    pdk = Encryption::KeyDerivationService.derive_key(password: "password123", salt: @user.master_key_salt)
    mek = Encryption::MasterKeyService.unwrap(wrapped_key: @user.encrypted_master_key, wrapping_key: pdk)
    encrypted = Encryption::SecretEncryptionService.encrypt(value: value, key: mek)

    Secret.create!(
      folder: @folder,
      vault: @vault,
      name: name,
      encrypted_value: encrypted[:encrypted_value],
      encrypted_value_iv: encrypted[:iv],
      encrypted_value_auth_tag: encrypted[:auth_tag]
    )
  end
end
