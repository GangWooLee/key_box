require "test_helper"

class UserTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
  end

  # ===== Validations =====
  test "should be valid with valid attributes" do
    assert @user.valid?
  end

  test "should require email" do
    @user.email = nil
    assert_not @user.valid?
    assert_includes @user.errors[:email], "can't be blank"
  end

  test "should require unique email" do
    duplicate = @user.dup
    duplicate.email = @user.email.upcase
    assert_not duplicate.valid?
  end

  test "should require valid email format" do
    @user.email = "not_an_email"
    assert_not @user.valid?
  end

  test "should downcase email before validation" do
    @user.email = "ALICE@EXAMPLE.COM"
    @user.valid?
    assert_equal "alice@example.com", @user.email
  end

  test "should require name" do
    @user.name = nil
    assert_not @user.valid?
  end

  test "should enforce name length limit" do
    @user.name = "a" * 51
    assert_not @user.valid?
  end

  test "should require password minimum 8 characters for new user" do
    salt = Encryption::KeyDerivationService.generate_salt
    pdk = Encryption::KeyDerivationService.derive_key(password: "short", salt: salt)
    mek = Encryption::MasterKeyService.generate_master_key
    wrapped = Encryption::MasterKeyService.wrap(master_key: mek, wrapping_key: pdk)

    user = User.new(
      email: "new@example.com",
      name: "New",
      password: "short",
      password_confirmation: "short",
      master_key_salt: salt,
      encrypted_master_key: wrapped
    )
    assert_not user.valid?
    assert_includes user.errors[:password], "is too short (minimum is 8 characters)"
  end

  test "should require master_key_salt" do
    @user.master_key_salt = nil
    assert_not @user.valid?
  end

  test "should require encrypted_master_key" do
    @user.encrypted_master_key = nil
    assert_not @user.valid?
  end

  # ===== Associations =====
  test "should have many memberships" do
    assert_respond_to @user, :memberships
  end

  test "should have many vaults through memberships" do
    assert_respond_to @user, :vaults
  end

  test "should have many audit events" do
    assert_respond_to @user, :audit_events
  end

  # ===== Instance Methods =====
  test "should return personal vault" do
    vault = @user.personal_vault
    assert_not_nil vault
    assert_equal "Personal", vault.name
    assert vault.vault_type_personal?
  end

  test "should record login" do
    @user.record_login(ip: "127.0.0.1")
    @user.reload
    assert_equal "127.0.0.1", @user.last_login_ip
    assert_not_nil @user.last_login_at
  end

  test "should remember and forget" do
    token = @user.remember
    assert_not_nil token
    assert @user.remembered?(token)
    assert_not @user.remembered?("wrong_token")

    @user.forget
    assert_not @user.remembered?(token)
  end
end
