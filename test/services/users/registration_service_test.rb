require "test_helper"

class Users::RegistrationServiceTest < ActiveSupport::TestCase
  test "should register user with valid params" do
    params = {
      email: "newuser@example.com",
      name: "New User",
      password: "password123",
      password_confirmation: "password123"
    }

    result = Users::RegistrationService.new(params: params).call

    assert result.success?
    assert_not_nil result.user.id
    assert_equal "newuser@example.com", result.user.email
  end

  test "should create personal vault for new user" do
    params = {
      email: "vaultuser@example.com",
      name: "Vault User",
      password: "password123",
      password_confirmation: "password123"
    }

    result = Users::RegistrationService.new(params: params).call
    assert result.success?

    vault = result.user.personal_vault
    assert_not_nil vault
    assert_equal "Personal", vault.name
    assert vault.vault_type_personal?
  end

  test "should create default General folder" do
    params = {
      email: "folderuser@example.com",
      name: "Folder User",
      password: "password123",
      password_confirmation: "password123"
    }

    result = Users::RegistrationService.new(params: params).call
    assert result.success?

    vault = result.user.personal_vault
    folders = vault.folders
    assert_equal 1, folders.count
    assert_equal "General", folders.first.name
  end

  test "should generate encryption keys" do
    params = {
      email: "keyuser@example.com",
      name: "Key User",
      password: "password123",
      password_confirmation: "password123"
    }

    result = Users::RegistrationService.new(params: params).call
    user = result.user

    assert_not_nil user.master_key_salt
    assert_not_nil user.encrypted_master_key

    pdk = Encryption::KeyDerivationService.derive_key(
      password: "password123",
      salt: user.master_key_salt
    )
    mek = Encryption::MasterKeyService.unwrap(
      wrapped_key: user.encrypted_master_key,
      wrapping_key: pdk
    )
    assert_not_nil mek
    assert_equal 32, mek.bytesize
  end

  test "should fail with invalid params" do
    params = {
      email: "",
      name: "",
      password: "short",
      password_confirmation: "mismatch"
    }

    result = Users::RegistrationService.new(params: params).call
    assert_not result.success?
    assert_not_empty result.errors
  end

  test "should fail with duplicate email" do
    params = {
      email: users(:one).email,
      name: "Duplicate",
      password: "password123",
      password_confirmation: "password123"
    }

    result = Users::RegistrationService.new(params: params).call
    assert_not result.success?
  end
end
